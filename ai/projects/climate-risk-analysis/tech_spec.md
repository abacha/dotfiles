# Tech Spec: Climate Risk Analysis — Full Implementation Plan

> **Version:** 1.0 — 2026-03-08  
> **Status:** Draft  
> **Scope:** Environment setup, local Docker dev, staging environment, database setup, job queue architecture, GCS deployment scripts, and rollout plan.

---

## Table of Contents

1. [Current State Assessment](#1-current-state-assessment)
2. [Target Architecture Overview](#2-target-architecture-overview)
3. [Environment & Configuration Strategy](#3-environment--configuration-strategy)
4. [Database Setup](#4-database-setup)
5. [Local Development — Fully Dockerized](#5-local-development--fully-dockerized)
6. [Job Queue & Async Architecture](#6-job-queue--async-architecture)
7. [Worker Service](#7-worker-service)
8. [API Changes](#8-api-changes)
9. [Frontend / UX Changes](#9-frontend--ux-changes)
10. [Staging Environment](#10-staging-environment)
11. [GCS / GKE Deployment Scripts](#11-gcs--gke-deployment-scripts)
12. [Observability & Logging](#12-observability--logging)
13. [Security](#13-security)
14. [Testing Strategy](#14-testing-strategy)
15. [Migration Plan](#15-migration-plan)
16. [Rollout Phases](#16-rollout-phases)
17. [File-Level Change Map](#17-file-level-change-map)

---

## 1. Current State Assessment

### What exists today

| Aspect | Current State |
|---|---|
| **Web framework** | Flask (`app.py`) with `flask-basicauth`, served by Gunicorn (1 worker, 4 threads, gthread) |
| **CLI** | Click-based (`main.py`) with `single` and `batch` commands |
| **Simulation engine** | DSSAT (via `DSSATTools`), orchestrated in `src/simulation_core/workflow.py` |
| **Job tracking** | In-memory `SimulationRegistry` (Python dicts) — lost on restart |
| **Config** | `config.ini` (INI file, loaded via `configparser`) for simulation params; `.env` for env vars (GCS, AIOMA) |
| **Auth** | `config.ini [auth]` section — plaintext user:password pairs |
| **Storage** | Local filesystem (`Output/`) + optional GCS upload. When GCS is enabled, local files are deleted post-upload |
| **Infra** | Single Dockerfile → GKE deployment (1 replica, `e2-standard-4`). K8s manifests in `k8s/`. Deploy script `scripts/deploy_gke.sh` |
| **External APIs** | Google Earth Engine (NASA POWER + CHIRPS), AIOMA future climate forecast |
| **Tests** | pytest (unit + smoke). Smoke tests require GEE credentials + network |
| **Staging** | None |
| **Database** | None — all state is in-memory or on filesystem |

### Key problems

1. **Simulations block the HTTP request** — long-running subprocess tied to web process lifetime
2. **State lost on restart** — in-memory dicts mean running simulations are orphaned
3. **No staging environment** — all testing happens against production GKE or local dev
4. **Auth is plaintext in config.ini** — no hashed passwords, no token auth
5. **No database** — job history, user sessions, audit logs all ephemeral
6. **No docker-compose** — local dev requires manually installing Python 3.11, Poetry, DSSAT deps
7. **Config split** — some in `config.ini`, some in `.env`, some hardcoded. No clear hierarchy

---

## 2. Target Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                     docker-compose                       │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  climate  │  │  climate  │  │ RabbitMQ │  │ Postgres│ │
│  │   -web    │  │  -worker  │  │          │  │         │ │
│  │  (Flask)  │  │  (CLI)    │  │          │  │         │ │
│  └────┬─────┘  └────┬──────┘  └────┬─────┘  └────┬────┘ │
│       │              │              │              │      │
│       └──────────────┴──────────────┴──────────────┘      │
│                    shared network                         │
└─────────────────────────────────────────────────────────┘
```

### Services

| Service | Role | Port |
|---|---|---|
| `climate-web` | Flask API + web UI. Receives requests, validates, enqueues jobs, serves results | `8080` |
| `climate-worker` | Consumes RabbitMQ queue, runs DSSAT simulations via CLI subprocess, updates job status in DB | — |
| `rabbitmq` | Message broker. Main queue + DLQ | `5672` (AMQP), `15672` (mgmt) |
| `postgres` | Job state, user auth (future), audit log | `5432` |

---

## 3. Environment & Configuration Strategy

### 3.1 Configuration Hierarchy (in order of precedence)

```
Environment variables (highest priority)
  └── .env file (loaded via python-dotenv)
       └── config.ini (simulation parameters, crop benchmarks — NOT secrets)
```

### 3.2 What goes where

| Store | What belongs there | Examples |
|---|---|---|
| **Environment variables / `.env`** | Secrets, infrastructure endpoints, feature flags | `DATABASE_URL`, `RABBITMQ_URL`, `OUTPUT_GCS_BUCKET`, `AIOMA_*`, `FLASK_SECRET_KEY`, `BASIC_AUTH_ADMIN_PASSWORD` |
| **`config.ini`** | Simulation science parameters, crop benchmarks, fenology phases, trigger ranges | `[climate_benchmarks_soybean]`, `[simulation_defaults]`, `[fenology_phases]` |
| **Database** | Job state, job events, (future: user accounts, API keys) | `simulation_jobs`, `job_events` |

### 3.3 `.env` file — new canonical template

Create `.env.template` (replaces `.env.example`):

```ini
# ── Infrastructure ──
DATABASE_URL=postgresql://climate:climate@postgres:5432/climate_risk
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672/
REDIS_URL=                           # optional, for future caching layer

# ── Flask ──
FLASK_SECRET_KEY=change-me-in-production
FLASK_ENV=development                # development | staging | production
PORT=8080

# ── Auth ──
# Migrating from config.ini [auth]. For now, keep backward compat.
# Phase 2 will move users to DB.
BASIC_AUTH_ADMIN_PASSWORD=

# ── GCS Storage ──
OUTPUT_GCS_BUCKET=
OUTPUT_GCS_PREFIX=Output
GOOGLE_APPLICATION_CREDENTIALS=Resources/gcp-service-account.json

# ── AIOMA Future Climate ──
AIOMA_API_BASE_URL=
AIOMA_TIMEOUT_SECONDS=30
AIOMA_AUTH_TYPE=none                  # none | basic | bearer
AIOMA_API_KEY=
AIOMA_BASIC_USER=
AIOMA_BASIC_PASSWORD=
AIOMA_HORIZON_DAYS=365

# ── Google Earth Engine ──
GEE_SERVICE_ACCOUNT_JSON=Resources/gcp-service-account.json
```

### 3.4 config.ini — cleanup

Remove from `config.ini`:
- `[auth]` section → move to env vars / DB (Phase 2)
- `[paths] service_account_json` → use `GEE_SERVICE_ACCOUNT_JSON` env var

Keep in `config.ini`:
- All `[climate_benchmarks_*]`, `[simulation_defaults]`, `[fenology_phases]`, `[trigger_ranges]`, `[yield_monitoring]`, `[decadal_thresholds]`, `[dssat]`, `[crop_parameters]`, `[climate_score]` — these are science config, not infra.

### 3.5 Config loader changes

Update `src/config_loader.py`:

```python
import os
import configparser
from functools import lru_cache

@lru_cache(maxsize=1)
def load_config(config_path: str = None) -> configparser.ConfigParser:
    if config_path is None:
        config_path = os.environ.get("CONFIG_INI_PATH", "config.ini")
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    abs_path = os.path.join(base_dir, config_path) if not os.path.isabs(config_path) else config_path
    if not os.path.exists(abs_path):
        raise FileNotFoundError(f"Configuration file not found at: {abs_path}")
    config = configparser.ConfigParser()
    config.read(abs_path)
    return config

def get_database_url() -> str:
    return os.environ["DATABASE_URL"]

def get_rabbitmq_url() -> str:
    return os.environ["RABBITMQ_URL"]

def get_flask_env() -> str:
    return os.environ.get("FLASK_ENV", "production")

def is_gcs_enabled() -> bool:
    return bool(os.environ.get("OUTPUT_GCS_BUCKET"))
```

---

## 4. Database Setup

### 4.1 Technology choice: PostgreSQL
- Proven, free, excellent JSON support, works great in Docker and Cloud SQL
- For local dev: Postgres 16 in docker-compose
- For GKE staging/prod: Cloud SQL for PostgreSQL

### 4.2 ORM: Peewee (Active Record)
We will use **Peewee**, a lightweight and expressive ORM that follows the Active Record pattern (similar to Ruby on Rails). It removes the need for complex sessions and repository layers, allowing models to save themselves directly.

Add to `pyproject.toml` deps: `peewee`, `psycopg2-binary`, `peewee_migrate`.

### 4.3 Peewee Models

New file: `src/db/models.py`

```python
import os
import uuid
from datetime import datetime, timezone
from peewee import *
from playhouse.postgres_ext import PostgresqlExtDatabase, BinaryJSONField

# Initialize database connection
db = PostgresqlExtDatabase(
    os.environ.get("POSTGRES_DB", "climate_risk"),
    user=os.environ.get("POSTGRES_USER", "climate"),
    password=os.environ.get("POSTGRES_PASSWORD", "climate"),
    host=os.environ.get("POSTGRES_HOST", "postgres"),
    port=int(os.environ.get("POSTGRES_PORT", 5432))
)

class BaseModel(Model):
    class Meta:
        database = db

class SimulationJob(BaseModel):
    job_id = UUIDField(primary_key=True, default=uuid.uuid4)
    simulation_type = CharField(default="single")  # single | batch
    sim_id = CharField(null=True)
    requested_by = CharField()
    request_payload = BinaryJSONField()
    status = CharField(default="queued")  # queued, running, succeeded, failed, canceled
    progress = IntegerField(default=0)
    current_step = CharField(null=True)
    error_summary = TextField(null=True)
    output_ref = CharField(null=True)
    log_ref = CharField(null=True)
    batch_group_id = CharField(null=True, index=True)
    created_at = DateTimeField(default=lambda: datetime.now(timezone.utc))
    started_at = DateTimeField(null=True)
    finished_at = DateTimeField(null=True)
    updated_at = DateTimeField(default=lambda: datetime.now(timezone.utc))

    def save(self, *args, **kwargs):
        self.updated_at = datetime.now(timezone.utc)
        return super().save(*args, **kwargs)

    class Meta:
        table_name = 'simulation_jobs'

class JobEvent(BaseModel):
    event_id = AutoField()
    job_id = ForeignKeyField(SimulationJob, backref='events', on_delete='CASCADE')
    timestamp = DateTimeField(default=lambda: datetime.now(timezone.utc))
    level = CharField(default="INFO")
    message = TextField()
    metadata = BinaryJSONField(null=True)

    class Meta:
        table_name = 'job_events'
```

### 4.4 Migrations Setup
We will use `peewee_migrate` for schema migrations.
The `migrate` service in `docker-compose.yml` will simply run `pw_migrate migrate`.

## 5. Local Development — Fully Dockerized

### 5.1 docker-compose.yml

```yaml
version: "3.9"

x-common-env: &common-env
  DATABASE_URL: postgresql://climate:climate@postgres:5432/climate_risk
  RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
  FLASK_ENV: development
  FLASK_SECRET_KEY: dev-secret-key
  CONFIG_INI_PATH: /app/config.ini
  GOOGLE_APPLICATION_CREDENTIALS: /app/Resources/gcp-service-account.json
  TZ: America/Sao_Paulo

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: climate
      POSTGRES_PASSWORD: climate
      POSTGRES_DB: climate_risk
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U climate -d climate_risk"]
      interval: 5s
      timeout: 3s
      retries: 5

  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_port_connectivity"]
      interval: 10s
      timeout: 5s
      retries: 5

  migrate:
    build:
      context: .
      dockerfile: Dockerfile
    command: ["pw_migrate", "migrate"]
    environment:
      <<: *common-env
    depends_on:
      postgres:
        condition: service_healthy
    restart: "no"

  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: >
      gunicorn --bind 0.0.0.0:8080
      --workers 2 --threads 4 --worker-class gthread
      --timeout 120 --log-file=- --reload
      app:app
    environment:
      <<: *common-env
      PORT: "8080"
    env_file:
      - .env
    ports:
      - "8080:8080"
    volumes:
      - ./:/app
      - output_data:/app/Output
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      migrate:
        condition: service_completed_successfully

  worker:
    build:
      context: .
      dockerfile: Dockerfile
    command: ["python", "-m", "src.worker"]
    environment:
      <<: *common-env
    env_file:
      - .env
    volumes:
      - ./:/app
      - output_data:/app/Output
    depends_on:
      postgres:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      migrate:
        condition: service_completed_successfully
    deploy:
      replicas: 1            # scale with: docker compose up --scale worker=N

volumes:
  pgdata:
  rabbitmq_data:
  output_data:
```

### 5.2 Dockerfile updates

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# System deps for psycopg2 + DSSAT
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libpq-dev gfortran \
    && rm -rf /var/lib/apt/lists/*

COPY poetry.lock pyproject.toml ./
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --without dev --no-root

COPY . .
COPY Resources/ /app/Resources/

EXPOSE 8080

# Default CMD — overridden per service in docker-compose
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--threads", "4", \
     "--worker-class", "gthread", "--timeout", "1800", "--log-file=-", "app:app"]
```

### 5.3 Makefile (developer convenience)

```makefile
.PHONY: up down logs shell test migrate worker-logs

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f web worker

worker-logs:
	docker compose logs -f worker

shell:
	docker compose exec web bash

test:
	docker compose exec web poetry run pytest -x -q

migrate:
	docker compose exec web python -m peewee_migrate upgrade head

db-shell:
	docker compose exec postgres psql -U climate -d climate_risk

rabbit-ui:
	@echo "RabbitMQ Management: http://localhost:15672 (guest/guest)"

reset:
	docker compose down -v
	docker compose up -d --build
```

### 5.4 Local dev workflow

```bash
# First time
cp .env.template .env          # edit secrets
make up                        # builds all, runs migrations, starts services

# Day-to-day
make up                        # starts (with --build if Dockerfile changed)
make logs                      # tail web + worker logs
make test                      # run tests inside container
make shell                     # bash into web container
make db-shell                  # psql into postgres

# Full reset
make reset                     # wipes volumes, rebuilds
```

---

## 6. Job Queue & Async Architecture

### 6.1 Message broker: RabbitMQ

| Queue | Purpose | Routing Key |
|---|---|---|
| `simulation.jobs` | Main job queue | `simulation.new` |
| `simulation.jobs.dlq` | Dead-letter queue (failed after retries) | `simulation.failed` |

Exchange: `simulation` (topic).

### 6.2 Message schema

```json
{
  "job_id": "uuid",
  "simulation_type": "single|batch",
  "request_payload": {
    "name": "...",
    "latitude": -16.08,
    "longitude": -47.51,
    "crop": "soybean",
    "planting_day": "25/10",
    "cultivar": "990008",
    "start_stage": "Planting",
    "end_stage": "Harvest",
    "future_climate": false,
    "user": "admin"
  },
  "batch_group_id": null,
  "enqueued_at": "2026-03-08T10:00:00Z"
}
```

### 6.3 Library: `pika`

Add to `pyproject.toml`:
```toml
pika = "^1.3.2"
```

### 6.4 Publisher module

New file: `src/queue/publisher.py`

```python
import json
import os
import pika

def _get_connection():
    return pika.BlockingConnection(
        pika.URLParameters(os.environ["RABBITMQ_URL"])
    )

def declare_topology(channel):
    channel.exchange_declare(exchange="simulation", exchange_type="topic", durable=True)
    channel.queue_declare(queue="simulation.jobs.dlq", durable=True)
    channel.queue_bind(queue="simulation.jobs.dlq", exchange="simulation", routing_key="simulation.failed")
    channel.queue_declare(
        queue="simulation.jobs",
        durable=True,
        arguments={
            "x-dead-letter-exchange": "simulation",
            "x-dead-letter-routing-key": "simulation.failed",
        },
    )
    channel.queue_bind(queue="simulation.jobs", exchange="simulation", routing_key="simulation.new")

def publish_job(job_message: dict):
    connection = _get_connection()
    channel = connection.channel()
    declare_topology(channel)
    channel.basic_publish(
        exchange="simulation",
        routing_key="simulation.new",
        body=json.dumps(job_message),
        properties=pika.BasicProperties(
            delivery_mode=2,  # persistent
            content_type="application/json",
        ),
    )
    connection.close()
```

---

## 7. Worker Service


### 7.1 Worker entrypoint

New file: `src/worker.py`

```python
import json
import logging
import os
import traceback
from datetime import datetime, timezone

import pika

from config_loader import load_config
from db.models import db, SimulationJob, JobEvent
from queue.publisher import declare_topology
from simulation_core.workflow import run_single_simulation, OUTPUT_DIR
from src.main import run_simulation_logic

log = logging.getLogger("worker")
logging.basicConfig(level=logging.INFO, format="%(asctime)s [worker] %(levelname)s %(message)s")


def process_job(ch, method, properties, body):
    message = json.loads(body)
    job_id = message["job_id"]
    payload = message["request_payload"]
    
    log.info("Processing job %s", job_id)
    
    # Ensure DB connection is alive in worker thread
    if db.is_closed():
        db.connect()
    
    try:
        # Active Record: Fetch, update, save
        job = SimulationJob.get_by_id(job_id)
        job.status = "running"
        job.started_at = datetime.now(timezone.utc)
        job.save()
        
        JobEvent.create(job_id=job.job_id, level="INFO", message="Worker picked up job")
        
        config = load_config()
        simulation_params = {**payload}
        
        job.progress = 10
        job.current_step = "Preparing weather data"
        job.save()
        
        sim_id = run_simulation_logic(
            simulation_params,
            inputs={},
            config=config,
            is_batch=(message["simulation_type"] == "batch"),
            batch_group_folder=message.get("batch_group_id"),
            future_manual_csv=payload.get("future_climate_csv"),
        )
        
        job.status = "succeeded"
        job.sim_id = sim_id
        job.output_ref = sim_id
        job.progress = 100
        job.finished_at = datetime.now(timezone.utc)
        job.save()
        
        JobEvent.create(job_id=job.job_id, level="INFO", message=f"Simulation completed: {sim_id}")
        
        ch.basic_ack(delivery_tag=method.delivery_tag)
        log.info("Job %s completed: %s", job_id, sim_id)
    
    except Exception as exc:
        error_msg = traceback.format_exc()
        log.error("Job %s failed: %s", job_id, exc)
        
        job = SimulationJob.get_or_none(SimulationJob.job_id == job_id)
        if job:
            job.status = "failed"
            job.error_summary = str(exc)[:2000]
            job.finished_at = datetime.now(timezone.utc)
            job.save()
            JobEvent.create(job_id=job.job_id, level="ERROR", message=error_msg[:4000])
        
        # Reject and send to DLQ (no requeue)
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        
    finally:
        if not db.is_closed():
            db.close()


def main():
    log.info("Worker starting...")
    connection = pika.BlockingConnection(
        pika.URLParameters(os.environ["RABBITMQ_URL"])
    )
    channel = connection.channel()
    declare_topology(channel)
    
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue="simulation.jobs", on_message_callback=process_job)
    
    log.info("Worker ready. Waiting for jobs...")
    channel.start_consuming()


if __name__ == "__main__":
    main()
```

---

## 8. API Changes

### 8.1 New endpoints (Phase 1)

| Method | Path | Description |
|---|---|---|
| `POST` | `/api/simulations/jobs` | Create job → DB + RabbitMQ |
| `GET` | `/api/simulations/jobs/<job_id>` | Status + progress |
| `GET` | `/api/simulations/jobs/<job_id>/events` | Event timeline |
| `GET` | `/api/simulations/jobs` | List jobs (paginated) |

### 8.2 Updated `POST /api/simulations/jobs` flow

```python
# In web/api.py

@api_bp.route("/api/simulations/jobs", methods=["POST"])
@basic_auth.required
def start_simulation():
    sim_params = request.get_json()
    # ... validation (unchanged) ...
    
    # Active Record: Create job in DB
    job = SimulationJob.create(
        simulation_type="single",
        requested_by=user,
        request_payload=sim_params
    )
    
    sim_id = f"{sim_params['name']}_{job.job_id.hex[:8]}"
    
    # Publish to queue
    publish_job({
        "job_id": str(job.job_id),
        "simulation_type": "single",
        "request_payload": {**sim_params, "sim_id": sim_id},
        "enqueued_at": datetime.now(timezone.utc).isoformat(),
    })
    
    return jsonify({
        "message": "Simulation queued.",
        "job_id": str(job.job_id),
        "status_url": url_for("api.get_job_status", job_id=str(job.job_id), _external=True),
    }), 202
```

---

## 9. Frontend / UX Changes

### 9.1 Loading screen (Consumer Experience)

**Goal:** Create a waiting experience similar to iFood or Nubank. The user must see what is happening focused on the value generated, not the underlying script execution.

- **Remove the Terminal:** Completely hide the black log box for the end user.
- **Visual Feedback:** Replace the terminal with a centralized card containing:
  - An icon or looping animation (e.g., a radar, a growing plant, or a spinning satellite).
  - A prominent status title (e.g., "Analisando sua área...").
  - A dynamic subtitle that changes as the backend progresses through steps.
  - A horizontal progress bar (actual event-based or simulated with easing, stopping at 90% until the completion flag is received).

### 9.2 Event Mapping to User-Friendly Subtitles

The frontend will poll `/api/simulations/jobs/<job_id>` and read the `current_step` or `progress` fields. The backend should emit standard internal steps, which the UI translates into friendly messages:

| Backend Internal Step (or keyword) | User-Facing Subtitle |
|---|---|
| Queueing NASA POWER / CHIRPS / Merging | ☁️ "Consultando histórico climático e dados de satélite da propriedade..." |
| Starting soil data preparation | 🌱 "Analisando composição e características do solo..." |
| Initial soybean crop cycle / Rerunning | 🌿 "Modelando a fenologia e ajustando o ciclo da cultura..." |
| Writing weather file / DSSAT simulation | ⚙️ "Executando simulação de risco e projeção de safra..." |
| Processing simulation outputs | 📊 "Quase pronto! Organizando seus resultados..." |
| Analysis Finished | ✅ "Análise agroclimática realizada" (Show buttons: View Report, etc.) |

### 9.3 Error Handling & Exceptions

- **No Tracebacks:** If the script breaks or times out, **never** display the Python traceback or raw error on the screen.
- **Friendly Fallback:** Show a user-friendly error state with an illustration and message:
  > *"Tivemos uma instabilidade ao processar os dados climáticos. Nossos engenheiros já foram notificados. Por favor, tente novamente em alguns instantes."*
- **Admin Debugging:** Keep the raw logs accessible *only* via the browser console or a hidden admin panel toggle.

---

## 10. Staging Environment

### 10.1 Strategy

Staging mirrors production but with:
- Separate GKE node pool (or namespace `staging` in the same cluster)
- Separate GCS bucket (`climate-risk-analysis-473221-outputs-staging`)
- Separate Cloud SQL instance (or same instance, different database `climate_risk_staging`)
- Same Docker image, different env vars

### 10.2 Kubernetes namespace approach

```yaml
# k8s/staging/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
```

### 10.3 Staging config overlay

Create `k8s/staging/` directory with kustomize overlays:

```
k8s/
  base/
    deployment.yaml         # parameterized (moved from k8s/)
    service.yaml
    ingress.yaml
    backend-config.yaml
    kustomization.yaml
  staging/
    kustomization.yaml      # patches for staging
    config-patch.yaml
    ingress-patch.yaml
  production/
    kustomization.yaml      # patches for production
    config-patch.yaml
```

`k8s/staging/kustomization.yaml`:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: staging
resources:
  - ../base
patchesStrategicMerge:
  - config-patch.yaml
  - ingress-patch.yaml
```

`k8s/staging/config-patch.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: climate-risk-analysis-deployment
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: climate-risk-analysis-container
        env:
        - name: FLASK_ENV
          value: "staging"
        - name: OUTPUT_GCS_BUCKET
          value: "climate-risk-analysis-473221-outputs-staging"
        - name: DATABASE_URL
          value: "postgresql://climate:climate@postgres-staging:5432/climate_risk_staging"
        - name: RABBITMQ_URL
          value: "amqp://guest:guest@rabbitmq-staging:5672/"
        resources:
          requests:
            memory: "4Gi"
            cpu: "250m"
          limits:
            memory: "4Gi"
            cpu: "500m"
```

### 10.4 Staging deployment script

New file: `scripts/deploy_staging.sh`

```bash
#!/bin/bash
set -e

export PROJECT_ID="climate-risk-analysis-473221"
export REGION="southamerica-east1"
export ZONE="southamerica-east1-b"
export AR_REPO="climate-risk-repo"
export GKE_CLUSTER="climate-risk-cluster"
export APP_NAME="climate-risk-analysis"
export IMAGE_TAG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${APP_NAME}:staging-$(git rev-parse --short HEAD)"

echo "=== Building staging image: ${IMAGE_TAG} ==="
docker build -t ${IMAGE_TAG} .
docker push ${IMAGE_TAG}

echo "=== Getting cluster credentials ==="
gcloud container clusters get-credentials ${GKE_CLUSTER} --zone=${ZONE} --project=${PROJECT_ID}

echo "=== Creating staging namespace (if needed) ==="
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

echo "=== Creating staging GCS bucket (if needed) ==="
gcloud storage buckets create gs://${PROJECT_ID}-outputs-staging \
    --location=${REGION} --uniform-bucket-level-access --project=${PROJECT_ID} 2>/dev/null || true

echo "=== Deploying to staging ==="
cd k8s
kustomize build staging | sed "s|__IMAGE_TAG__|${IMAGE_TAG}|g" | kubectl apply -f -

echo "=== Staging deployment complete ==="
kubectl -n staging rollout status deployment/climate-risk-analysis-deployment
```

---

## 11. GCS / GKE Deployment Scripts

### 11.1 Updated deploy script

Refactor `scripts/deploy_gke.sh` into modular scripts:

```
scripts/
  deploy/
    build_and_push.sh        # build image, push to AR
    setup_infra.sh           # GCP APIs, AR repo, GKE cluster, IAM, buckets (idempotent)
    deploy_production.sh     # kustomize build production | kubectl apply
    deploy_staging.sh        # kustomize build staging | kubectl apply
    rollback.sh              # kubectl rollout undo
  deploy_gke.sh              # legacy wrapper — calls setup_infra + build_and_push + deploy_production
```

### 11.2 Worker deployment in GKE

New k8s manifest: `k8s/base/worker-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: climate-worker-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: climate-worker
  template:
    metadata:
      labels:
        app: climate-worker
    spec:
      containers:
      - name: climate-worker
        image: __IMAGE_TAG__
        command: ["python", "-m", "src.worker"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: climate-secrets
              key: database-url
        - name: RABBITMQ_URL
          valueFrom:
            secretKeyRef:
              name: climate-secrets
              key: rabbitmq-url
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: "/app/Resources/gcp-service-account.json"
        - name: TZ
          value: "America/Sao_Paulo"
        envFrom:
        - configMapRef:
            name: climate-config
        resources:
          requests:
            memory: "6Gi"
            cpu: "500m"
          limits:
            memory: "6Gi"
            cpu: "1000m"
```

New: `k8s/base/rabbitmq-deployment.yaml` (for GKE — alternatively use CloudAMQP or a managed service):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rabbitmq
  template:
    metadata:
      labels:
        app: rabbitmq
    spec:
      containers:
      - name: rabbitmq
        image: rabbitmq:3.13-management-alpine
        ports:
        - containerPort: 5672
        - containerPort: 15672
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: rabbitmq
spec:
  selector:
    app: rabbitmq
  ports:
  - name: amqp
    port: 5672
  - name: management
    port: 15672
```

### 11.3 ConfigMap and Secrets

```yaml
# k8s/base/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: climate-config
data:
  FLASK_ENV: "production"
  OUTPUT_GCS_PREFIX: "Output"
  TZ: "America/Sao_Paulo"
  AIOMA_TIMEOUT_SECONDS: "30"
  AIOMA_HORIZON_DAYS: "365"
```

Secrets should be created via `kubectl create secret` or a secrets manager — never committed:

```bash
kubectl create secret generic climate-secrets \
  --from-literal=database-url="postgresql://..." \
  --from-literal=rabbitmq-url="amqp://..." \
  --from-literal=flask-secret-key="..." \
  --from-literal=output-gcs-bucket="..." \
  --from-literal=aioma-api-key="..."
```

---

## 12. Observability & Logging

### 12.1 Structured logging

All services output JSON logs:

```python
# src/logging_config.py
import logging
import json
import sys

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_obj = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
        }
        if hasattr(record, "job_id"):
            log_obj["job_id"] = record.job_id
        if hasattr(record, "sim_id"):
            log_obj["sim_id"] = record.sim_id
        if record.exc_info:
            log_obj["exception"] = self.formatException(record.exc_info)
        return json.dumps(log_obj)

def setup_json_logging():
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())
    logging.root.handlers = [handler]
    logging.root.setLevel(logging.INFO)
```

### 12.2 Metrics to track

| Metric | Source | Alert threshold |
|---|---|---|
| Queue depth | RabbitMQ management API | > 10 jobs waiting > 5 min |
| Average queue wait time | `started_at - created_at` from DB | > 5 min |
| Average simulation time | `finished_at - started_at` from DB | > 30 min |
| Error rate | `failed / total` from DB | > 10% in 1h |
| DLQ depth | RabbitMQ DLQ | > 0 |
| AIOMA fallback rate | `future_source=fallback` log count | > 5 in 1h |

### 12.3 Health endpoints

Already exists: `GET /healthz` (used by k8s probes).

Add:
- `GET /healthz/ready` — checks DB + RabbitMQ connectivity
- `GET /healthz/live` — always 200 (process is alive)

---

## 13. Security

### 13.1 Phase 1 (current)
- Keep `config.ini [auth]` for backward compat
- Add `FLASK_SECRET_KEY` as mandatory env var (already done)
- Move GCS/AIOMA secrets out of config.ini → env vars (already done)

### 13.2 Phase 2 (DB-backed auth)
- `users` table with bcrypt-hashed passwords
- API key support (for automation clients)
- Rate limiting per user (max concurrent jobs)

### 13.3 Secrets in GKE
- Use Kubernetes Secrets (at minimum)
- Future: GCP Secret Manager with CSI driver

---

## 14. Testing Strategy

### 14.1 Test matrix

| Layer | Tool | What's tested | Requires |
|---|---|---|---|
| Unit | pytest | Config loading, models, repository, publisher | Nothing (mocked) |
| Integration | pytest + testcontainers | DB operations, queue pub/sub | Docker |
| API | pytest + Flask test client | Endpoints, validation, auth | DB (testcontainers) |
| Smoke | pytest | Full simulation pipeline | GEE credentials + network |
| E2E | docker-compose + curl | Full flow end-to-end | docker compose up |

### 14.2 New test files

```
tests/
  test_db_repository.py       # CRUD operations
  test_queue_publisher.py      # Message publishing
  test_worker.py               # Worker job processing (mocked simulation)
  test_api_jobs.py             # New job endpoints
  integration/
    test_full_flow.py          # docker-compose E2E
```

### 14.3 CI pipeline additions

```yaml
# Add to CI (GitHub Actions)
- name: Run tests with services
  services:
    postgres:
      image: postgres:16-alpine
      env:
        POSTGRES_USER: climate
        POSTGRES_PASSWORD: climate
        POSTGRES_DB: climate_risk_test
    rabbitmq:
      image: rabbitmq:3.13-alpine
  env:
    DATABASE_URL: postgresql://climate:climate@postgres:5432/climate_risk_test
    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
  run: poetry run pytest -x --ignore=tests/test_smoke.py
```

---

## 15. Migration Plan

### 15.1 Data migration

No data migration needed — current state is ephemeral (in-memory dicts). The DB starts empty. Historical outputs in GCS are unaffected.

---

## 16. Rollout Phases

### Phase 0 — Foundation (1-2 days)
- [ ] Create `docker-compose.yml` with postgres + rabbitmq + web + worker
- [ ] Add `peewee_migrate`, `peewee`, `psycopg2-binary`, `pika` to `pyproject.toml`
- [ ] Create `src/db/` package (models, session, repository)
- [ ] Create initial Alembic migration
- [ ] Update `Dockerfile` (add `gcc`, `libpq-dev`)
- [ ] Create `.env.template`
- [ ] Create `Makefile`
- [ ] Verify: `make up` boots all 4 services, migrations run, web serves on `:8080`

### Phase 1 — Job Queue (2-3 days)
- [ ] Create `src/queue/publisher.py`
- [ ] Create `src/worker.py`
- [ ] Update `web/api.py` — `POST /api/simulations` creates DB job + publishes to RabbitMQ
- [ ] Add `GET /api/simulations/jobs/<job_id>` endpoint
- [ ] Add `GET /api/simulations/jobs/<job_id>/events` endpoint
- [ ] Worker: consume queue, run `run_simulation_logic()`, update DB
- [ ] Test: submit simulation via API, verify worker picks it up, results appear

### Phase 2 — Staging & Deploy (1-2 days)
- [ ] Reorganize `k8s/` into `base/` + `staging/` + `production/` with kustomize
- [ ] Create `k8s/base/worker-deployment.yaml`, `rabbitmq-deployment.yaml`, `configmap.yaml`
- [ ] Create `scripts/deploy/deploy_staging.sh`
- [ ] Create staging GCS bucket
- [ ] Deploy staging to GKE namespace `staging`
- [ ] Verify: end-to-end simulation works in staging

### Phase 3 — UX & Frontend (1-2 days)
- [ ] Update `run.html` to poll `/api/simulations/jobs/<job_id>` instead of old status endpoint
- [ ] Add progress bar + step text
- [ ] Update `batch_status.html` similarly
- [ ] Add "Modo técnico" toggle for admin users (show job events)
- [ ] Test: full flow from web UI, loading screen, results page

### Phase 4 — Resilience & Cleanup (1-2 days)
- [ ] DLQ monitoring endpoint
- [ ] Job cancellation (`POST /api/simulations/jobs/<job_id>/cancel`)
- [ ] Retry logic in worker (configurable max retries)
- [ ] Rate limiting per user
- [ ] Remove `subprocess.Popen` from `web/api.py`
- [ ] Add `/healthz/ready` endpoint (DB + RabbitMQ checks)

### Phase 5 — Observability (1 day)
- [ ] JSON structured logging
- [ ] Job metrics dashboard (query DB for avg times, error rates)
- [ ] RabbitMQ management monitoring
- [ ] AIOMA fallback rate alerting

---

## 17. File-Level Change Map

### New files

| Path | Purpose |
|---|---|
| `docker-compose.yml` | Local dev orchestration |
| `.env.template` | Canonical env var template |
| `Makefile` | Developer convenience commands |
| `src/db/__init__.py` | DB package |
| `src/db/models.py` | Peewee models |
| `src/queue/__init__.py` | Queue package |
| `src/queue/publisher.py` | RabbitMQ publisher |
| `src/worker.py` | Worker service entrypoint |
| `src/logging_config.py` | JSON structured logging |
| `migrations/` | Peewee migration framework |
| `k8s/base/` | Base k8s manifests (kustomize) |
| `k8s/staging/` | Staging overlay |
| `k8s/production/` | Production overlay |
| `k8s/base/worker-deployment.yaml` | Worker k8s deployment |
| `k8s/base/rabbitmq-deployment.yaml` | RabbitMQ k8s deployment |
| `k8s/base/configmap.yaml` | Shared config |
| `scripts/deploy/` | Modular deploy scripts |
| `tests/test_db_repository.py` | DB tests |
| `tests/test_queue_publisher.py` | Queue tests |
| `tests/test_worker.py` | Worker tests |
| `tests/test_api_jobs.py` | Job API tests |

### Modified files

| Path | Changes |
|---|---|
| `Dockerfile` | Add system deps (`gcc`, `libpq-dev`), keep multi-purpose |
| `pyproject.toml` | Add `peewee`, `psycopg2-binary`, `peewee_migrate`, `pika` |
| `src/config_loader.py` | Add `get_database_url()`, `get_rabbitmq_url()`, use env for config path |
| `app.py` | Initialize DB engine on startup, register new API endpoints |
| `web/api.py` | Rewrite `POST /api/simulations` to use DB + queue; add job endpoints |
| `src/services/registry.py` | Add DB fallback for job status lookup |
| `config.ini` | Remove `[auth]` section (moved to env/DB) |
| `.env.example` | Deprecate in favor of `.env.template` |
| `scripts/deploy_gke.sh` | Refactor into modular scripts under `scripts/deploy/` |
| `k8s/deployment.yaml` | Move to `k8s/base/`, parameterize with kustomize |
| `k8s/service.yaml` | Move to `k8s/base/` |
| `k8s/ingress.yaml` | Move to `k8s/base/`, staging gets different host |
| `web/templates/run.html` | Poll new job status endpoint, add progress bar |
| `web/templates/batch_status.html` | Poll new batch job status endpoint |

### Untouched (core simulation logic)

These files are NOT modified — the simulation engine stays as-is:

- `src/simulation_core/*` (all files)
- `src/analysis/*` (all files)
- `src/presentation/*` (all files)
- `src/services/storage.py`
- `src/services/aioma_client.py`
- `src/services/batch.py`
- `src/services/validation.py`
- `Resources/*`
- `config.ini` (science sections)

---

## Appendix A: New Dependencies

```toml
# Add to [tool.poetry.dependencies]
peewee = "^3.17"
peewee_migrate = "^1.12"
psycopg2-binary = "^2.9"
pika = "^1.3"
```

## Appendix B: Environment Matrix

| Variable | Local (docker-compose) | Staging | Production |
|---|---|---|---|
| `DATABASE_URL` | `postgresql://climate:climate@postgres:5432/climate_risk` | Cloud SQL staging | Cloud SQL production |
| `RABBITMQ_URL` | `amqp://guest:guest@rabbitmq:5672/` | RabbitMQ in staging namespace | RabbitMQ in prod namespace |
| `FLASK_ENV` | `development` | `staging` | `production` |
| `OUTPUT_GCS_BUCKET` | (empty — local only) | `*-outputs-staging` | `*-outputs` |
| `FLASK_SECRET_KEY` | `dev-secret-key` | K8s Secret | K8s Secret |
| `AIOMA_*` | From `.env` | K8s Secret | K8s Secret |

## Appendix C: Port Map

| Service | Port | Protocol |
|---|---|---|
| Web (Flask/Gunicorn) | 8080 | HTTP |
| PostgreSQL | 5432 | TCP |
| RabbitMQ (AMQP) | 5672 | AMQP |
| RabbitMQ (Management) | 15672 | HTTP |

---

---

## Appendix D: Implementation Code Review (v1.0)

### Summary

The implementation covers **Phases 0–5 substantially well**, going beyond the spec in several areas (rate limiting, retry logic, cancellation, observability). The core architecture is sound. Below are the issues found, ordered by severity.

---

### 🔴 Critical / Bugs

**1. `JobProgressHandler.emit()` lacks exception handling**
File: `src/worker.py`, lines 55–84

```python
def emit(self, record):
    ...
    JobEvent.create(...)  # DB write — no try/except
    ...
    self.job.save()       # DB write — no try/except
```

`logging.Handler.emit()` must catch all exceptions and call `self.handleError(record)`. A DB connectivity blip mid-simulation will propagate an exception up through the logging framework into the simulation code, causing the job to fail with a misleading error rather than the actual simulation failure. Per Python docs, `emit()` implementations should swallow their own errors.

**2. `JobProgressHandler` is attached to the root logger — unsafe with concurrent jobs**
File: `src/worker.py`, lines 127–139

With `prefetch_count=1` a single worker process is safe. But if `prefetch_count` is ever raised, or if the worker is modified to handle jobs concurrently, `JobProgressHandler` attached to the root logger will write log events from Job B into Job A's `job_id`. This is a latent concurrency bug. The handler should be scoped to a simulation-specific logger, not `logging.getLogger()` (root).

**3. `run_simulation_logic()` call has broken indentation**
File: `src/worker.py`, lines 132–139

```python
sim_id = run_simulation_logic(

{**payload},     # ← this argument is at wrong indent level
inputs={},
...
```

This is syntactically valid Python (the call spans multiple lines), but it's visually confusing and suggests a copy-paste artifact. More importantly, the blank line between the function name and the first arg is unusual and would fail some linters/formatters.

**4. `models.py` ignores `DATABASE_URL` — mismatches docker-compose**
File: `src/db/models.py`, lines 17–23

The spec and `docker-compose.yml` both set `DATABASE_URL=postgresql://...`. However, `models.py` reads individual `POSTGRES_DB`, `POSTGRES_USER`, etc. env vars that are never set in `docker-compose.yml` or `.env.template`. The docker-compose env block only sets `DATABASE_URL`. This means connecting to PostgreSQL in the containerized environment will silently fall back to all defaults (`host=postgres`, `db=climate_risk`, `user=climate`), which happens to work in local dev — but it's fragile. If the `DATABASE_URL` ever points to a different host/credentials, `models.py` won't pick it up.

**Fix:** Parse `DATABASE_URL` directly using `playhouse.db_url`:
```python
from playhouse.db_url import connect
db = connect(os.environ["DATABASE_URL"])
```

---

### 🟠 Medium Issues

**5. No Flask/Peewee connection lifecycle management**
Files: `app.py`, `web/api.py`

Peewee with `PostgresqlExtDatabase` requires explicit connection management per request. The spec notes the DB should be initialized on startup. The current implementation has no `before_request` / `teardown_appcontext` hooks in `app.py`. Instead, `api.py` only does ad-hoc `if _db.is_closed(): _db.connect()` in the metrics endpoint. All other DB-hitting routes (`create_simulation_job`, `get_job_status`, etc.) call Peewee model methods without ensuring an open connection. This works with connection pooling but Peewee's `PostgresqlExtDatabase` doesn't pool by default — it needs `playhouse.pool.PooledPostgresqlExtDatabase` or explicit per-request connection management:

```python
# In app.py
@app.before_request
def connect_db():
    if db.is_closed():
        db.connect()

@app.teardown_appcontext
def close_db(exc):
    if not db.is_closed():
        db.close()
```

**6. `config_loader.py` deviates from spec — missing helper functions and `CONFIG_INI_PATH` env var support**
File: `src/config_loader.py`

The spec defines:
- `@lru_cache(maxsize=1)` — implementation uses a manual `_config_cache` dict (functionally equivalent but doesn't match spec)
- `get_database_url()`, `get_rabbitmq_url()`, `get_flask_env()`, `is_gcs_enabled()` helper functions — **none implemented**
- `CONFIG_INI_PATH` env var override — **not implemented** (though `docker-compose.yml` sets `CONFIG_INI_PATH=/app/config.ini`, it's never read)

These helpers aren't used internally yet, but they're referenced in the spec as the canonical way to access env config and the `CONFIG_INI_PATH` issue is a real gap.

**7. Migration system uses ad-hoc `CREATE TABLE IF NOT EXISTS`, not `peewee_migrate`**
File: `src/db/migrate.py`

The spec specifies `peewee_migrate` (`pw_migrate migrate`) and a `migrations/` directory. The implementation uses `db.create_tables([...], safe=True)` — no migration history, no rollback capability. The `docker-compose.yml` calls `python -m src.db.migrate` (not `pw_migrate migrate`). The spec also references a `migrations/` directory that doesn't exist.

For a project with an evolving schema this is a significant gap — `safe=True` won't apply ALTER TABLE operations when columns are added.

**8. `[auth]` section still in `config.ini` with plaintext passwords**
File: `config.ini`

The spec (§3.4, §13.1) explicitly says to remove `[auth]` from `config.ini` and move to env vars. It remains, with production passwords visible in the file. The spec acknowledges backward compat for Phase 1 but the intent was to move `BASIC_AUTH_ADMIN_PASSWORD` to env. The `app.py` `MultiUserBasicAuth` still reads only from `config.ini`, never from env vars — making the `.env.template`'s `BASIC_AUTH_ADMIN_PASSWORD` field dead code.

**9. `docker-compose.yml` uses `--preload` instead of `--reload`**
File: `docker-compose.yml`

The spec defines `--reload` for the dev web service (hot reload on code changes). The implementation uses `--preload` instead, which forks workers after loading the app — this is a production optimization, not a dev convenience. In development with a volume mount, `--reload` is expected. `--preload` with a volume mount will not auto-reload on file changes.

**10. Rate limiting code is duplicated between `web/api.py` and `web/routes.py`**
Files: `web/api.py` (lines 13–26), `web/routes.py` (lines 519–528)

The `_check_rate_limit()` function in `api.py` and the inline equivalent in `routes.py` are the same logic duplicated. If the threshold or query changes, it needs updating in two places.

---

### 🟡 Low / Minor Issues

**11. Queue package renamed from spec (`src/queue/` → `src/job_queue/`)**

The spec defines `src/queue/publisher.py`. The implementation uses `src/job_queue/publisher.py`. This is a reasonable deviation (avoids shadowing Python's built-in `queue` module — actually a good call), but worth noting the spec is outdated on this point.

**12. Import inconsistency: `api.py` uses `from src.job_queue.publisher` but `worker.py` uses `from job_queue.publisher`**
Files: `web/api.py` (line 16), `src/worker.py` (line 32)

Both work because each module manipulates `sys.path` differently. But the inconsistency is a code smell and will confuse anyone adding new modules. Should standardize on one pattern (preferably the `src.` prefix style from `api.py`).

**13. `services/registry.py` — spec says add DB fallback, not done**

The spec (§17 modified files) calls for adding a DB fallback to `registry.py`. The current `SimulationRegistry` is still pure in-memory with no DB fallback. The batch flow still uses in-memory `batch_jobs` dict, meaning batch job status is lost on restart.

**14. Spec-defined test files not implemented**
Per the spec (§14.2), the following test files are required:
- `tests/test_db_repository.py` — ❌ missing
- `tests/test_queue_publisher.py` — ❌ missing  
- `tests/test_worker.py` — ❌ missing
- `tests/test_api_jobs.py` — ❌ missing
- `tests/integration/test_full_flow.py` — ❌ missing

The existing test suite covers legacy functionality well, but the new async job infrastructure has zero test coverage.

**15. No GitHub Actions CI pipeline**

The spec (§14.3) defines a CI pipeline with postgres and rabbitmq services. No `.github/` directory exists. Without CI, there's no automated guard against regressions.

**16. Worker deployment missing `TZ` env var and liveness probe**
File: `k8s/base/worker-deployment.yaml`

The `TZ: America/Sao_Paulo` comes from `envFrom: configMapRef: climate-config` (which does include it), so this is fine. However, there's no liveness/readiness probe on the worker pod — if the worker hangs (e.g., inside a simulation with a blocked subprocess), Kubernetes won't restart it.

**17. `k8s/staging/config-patch.yaml` exposes DB credentials in plaintext**
File: `k8s/staging/config-patch.yaml`

```yaml
- name: DATABASE_URL
  value: "postgresql://climate:climate@postgres-staging:5432/..."
```

Credentials are hardcoded in the kustomize patch. The spec says to use `secretKeyRef`. This is a security regression from the base `worker-deployment.yaml` which correctly uses secrets.

**18. `Makefile` `migrate` target is wrong**
File: `Makefile`

```makefile
migrate:
    docker compose exec web python -m src.db.migrate
```

This runs migrations inside the already-running web container. The spec's migration flow uses a dedicated `migrate` service in docker-compose. Also, the spec's `Makefile` called `pw_migrate upgrade head`. The current target works but bypasses the migration service's dependency chain.

---

### ✅ What's Done Well (beyond spec)

- **Phase 4 (Retry logic):** `WORKER_MAX_RETRIES` with exponential republish — not in the base spec, well-implemented
- **Phase 4 (Job cancellation):** `/api/simulations/jobs/<job_id>/cancel` endpoint is clean and the worker correctly checks for cancellation before starting
- **Phase 4 (Rate limiting):** Per-user concurrent job limit implemented in both API and web routes
- **Phase 5 (Observability):** `/api/metrics/jobs`, `/api/metrics/rabbitmq`, `/api/metrics/aioma` — all implemented with correct alert thresholds from the spec
- **`AIOMA fallback tracker`:** Elegant in-process sliding window counter with thread safety, nicely factored
- **`/healthz/ready`:** Implements the DB + RabbitMQ check as spec'd
- **`run.html`:** Consumer-facing loading screen with step mapping, admin tech log toggle — matches spec §9 requirements well
- **k8s structure:** `base/`, `staging/`, `production/` kustomize layout matches spec §10
- **`scripts/deploy/`:** All 5 modular scripts (`_common.sh`, `build_and_push.sh`, `setup_infra.sh`, `deploy_production.sh`, `deploy_staging.sh`, `rollback.sh`) are present

---

### Prioritized Action Items

| Priority | Item |
|---|---|
| ✅ Done     | `JobProgressHandler.emit()` — add try/except + `handleError()` |
| ✅ Done     | Fix `models.py` to parse `DATABASE_URL` instead of individual vars |
| ✅ Done     | Fix indentation in `worker.py` `run_simulation_logic()` call |
| ✅ Done     | Add Flask DB connection lifecycle hooks in `app.py` |
| ✅ Done     | Replace `create_tables(safe=True)` with proper `peewee_migrate` setup |
| ⏸️ Skipped   | Move auth passwords out of `config.ini` → env vars; update `MultiUserBasicAuth` to check env first (Skipped per user request) |
| ✅ Done     | Change `docker-compose.yml` web command from `--preload` to `--reload` |
| ✅ Done     | Deduplicate rate-limit logic into a single function |
| 🟡 Backlog | Add `CONFIG_INI_PATH` support and helper functions to `config_loader.py` |
| 🟡 Backlog | Add DB fallback to `SimulationRegistry` for batch jobs |
| ✅ Done     | Write the 5 missing test files (db, queue, worker, api_jobs, integration) |
| ✅ Done     | Fix plaintext credentials in `k8s/staging/config-patch.yaml` |
| ✅ Done     | Add GitHub Actions CI pipeline |
| ✅ Done     | Add liveness probe to worker k8s deployment |

