# Nexus Recall — Overview
> Project path: `~/projects/nexus-recall`

## Scope
- **Purpose:** Private “ChatGPT with memory” over exported ChatGPT history.
- **Stack:**
  - **Backend:** FastAPI + SQLite (FTS5) + FAISS (HNSW) + PyYAML.
  - **Configuration:** Centralized in `backend/src/app/resources/system_config.yaml`.
  - **Web:** React + Vite + TypeScript + Lucide + react-virtuoso.
  - **Runtime:** Docker Compose (`api` + `web`).

## Ingestion Pipeline
The system processes data in three main stages: Ingest -> Clean -> Tag.

### 1. Ingest (`parse_export.py`)
- Supports `.zip` (ChatGPT Export) or raw `.json` (conversations.json).
- Extracts hierarchy (Conversations -> Messages).
- Standardizes roles (`user`, `assistant`, `system`). **Note:** `tool` role messages are ignored during ingest as they contain internal ChatGPT noise.

### 2. Clean (`cleaner.py`)
- **Sanitization before storage:** Every message passes through the cleaner before hitting the database.
- **Noise Removal:** Automatically strips technical JSON (IDs, width/height), voice metadada (audio_start_timestamp), and redundant system instructions.
- **Token Replacement:** Custom tokens like `\uE200product` are replaced with human-readable labels.
- **Durable Records:** Since cleaning happens during ingest, the database contains only readable text, improving search quality.

### 3. Tagging (`tagging.py`)
- **LLM-Based Classification:** Uses `gpt-4o-mini` to categorize conversations.
- **Smart Sampling:** Samples 5 messages from the beginning (Head) and 5 from the end (Tail) of a conversation to provide context for the classifier.
- **Dimensions:**
  - **Domain:** Primary project (coding, wellness, recipes, gaming, etc.).
  - **Frequency:** Occurrence pattern (recurring, one-off, long-running).
  - **Orthogonal:** Cross-cutting concerns (guide, tutorial, data-tracking).
- **Forced Overrides:** Rules in `system_config.yaml` can force domains based on keywords (e.g., "Ikariam" -> Gaming).

## Configuration & Parametrization
Most system behaviors are decoupled from code and live in `backend/src/app/resources/system_config.yaml`:
- List of allowed domains and tags.
- Regex and keywords for classification.
- Prompts for LLM tagging and reranking.
- Fallback strings for noise detection.

## Search & Retrieval
- **Hybrid Search:** Combines BM25 (SQLite FTS5) with Vector Search (FAISS + OpenAI/Gemini Embeddings).
- **Reranking:** Post-retrieval reranking via LLM to ensure the most relevant context is provided for the final answer.

## Environment & Data Rules
- **DB Path:** `backend/data/app.db` (Mapped to Docker volume `nexus_data`).
- **Vector Index:** `backend/data/faiss.index`.
- **HMR Support:** Frontend source is volume-mapped to the container in dev mode to allow Hot Module Replacement.
- **Port Mapping:** API runs on `:18080`, Web on `:15173`.

## Related Documentation
- [development.md](./development.md): Setup, build, and deployment workflows.
- [conventions.md](./conventions.md): Code style and pattern guidelines.
