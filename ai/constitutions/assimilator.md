# Assimilator — Constitution

> Personal finance management platform: expense tracking + investment portfolio, self-hosted.
> Named after the Protoss building that extracts and processes resources.

## 1. Problem Statement

The user manages finances across multiple banks (XP, Nubank, Wise), a joint account with spouse, and a segregated investment account belonging to his mother. Historical tracking was done via spreadsheets but fell off ~mid-2025. There is no single tool that consolidates:

- Multi-bank expense tracking with automatic categorization
- Joint account management with per-person contribution tracking
- Investment portfolio across brokers with performance benchmarking
- Clean segregation of third-party assets (mother's portfolio)
- Multi-currency support (BRL + USD)

## 2. Vision

A self-hosted, Docker-based web application that serves as the single source of truth for personal and household finances. Designed for one household but supports multiple user accounts. Prioritizes data ownership, local-first operation, and clean separation of concerns between expense management and investment tracking.

## 3. Users & Access

| User | Role | Scope |
|------|------|-------|
| Primary (Adriano) | Owner | Full access to everything |
| Spouse | Member | Sees joint account, her own expenses, shared dashboards |
| Mother | Viewer | Read-only view of her segregated investment portfolio |

No permission system needed — simple user accounts with implicit full access to their scoped data. No RBAC, no roles engine.

## 4. Core Domain Model

### 4.1 Entities

- **User** — account holder
- **Household** — groups users that share joint accounts
- **Financial Account** — a bank account, brokerage account, credit card, or wallet
  - Belongs to a User or a Household
  - Has a currency (BRL, USD, etc.)
  - Has a type: `checking`, `savings`, `credit_card`, `brokerage`, `wallet`
  - Tagged: `personal`, `joint`, `third_party` (mother's)
- **Transaction** — a debit, credit, or transfer
  - Linked to a Financial Account
  - Has: date, amount, description, category, subcategory, currency
  - Source: `open_finance`, `import_csv`, `import_pdf`, `import_ofx`, `manual`
  - `adb_capture` source is v3 scope — not implemented in v1
- **Category** — hierarchical (category → subcategory)
- **Budget** — monthly limit per category, scoped to account group (joint vs personal)
- **Investment Position** — current holding in an asset
  - Linked to a Brokerage Account
  - Asset type: `stock_br`, `stock_us`, `fii`, `fixed_income`, `crypto`, `other`
  - Tracks: quantity, average cost, current price, currency
- **Investment Transaction** — buy, sell, dividend, yield, split, etc.
- **Snapshot** — periodic portfolio valuation for historical evolution charts

### 4.2 Account Topology (Initial Setup)

A single bank can have multiple accounts (e.g., XP has 3 distinct accounts below). The model supports N accounts per institution natively — `Financial Account` has a `bank`/`institution` field but identity is per-account, not per-bank.

| Bank | Account Type | Owner | Tag | Currency |
|------|-------------|-------|-----|----------|
| XP | Checking (joint) | Household | joint | BRL |
| XP | Credit Card (joint) | Household | joint | BRL |
| XP | Checking + Brokerage (individual) | Adriano | personal | BRL + USD |
| XP | Brokerage (mother) | Adriano | third_party | BRL |
| Nubank | Credit Card | Adriano | personal | BRL |
| Nubank | Brokerage | Adriano | personal | BRL |
| Wise | Wallet | Adriano | personal | USD/BRL |

### 4.3 Segregation Rules

- **Net Worth** = sum of all `personal` + `joint` accounts. `third_party` is **excluded**.
- **Mother's portfolio** is fully isolated: separate dashboard, separate reports, never mixed into household totals.
- **Joint account**: expenses and cash flow only (no investments). Tracked with full categorization; each user's contribution is recorded monthly; the "household share" concept shows what portion of expenses belongs to whom.

### 4.4 Liabilities

- **Mortgage / Financing**: the couple has a joint apartment under financing. The system tracks:
  - Outstanding balance (liability, reduces net worth)
  - Monthly payment: linked via `Category#liability_id` — categories tagged to a liability auto-track regular and extra payments
  - Amortization schedule: SAC (constant principal) or Price (French/constant payment); extra amortization payments recalculate the SAC installment (`new_balance / new_remaining`) and shorten the term — matching Brazilian bank behavior. `term_months` stores the **original contract term** (immutable); end date is computed dynamically so adding/deleting extra payments adjusts it automatically.
  - **TBD: TR (Taxa Referencial) correction** — banks apply TR monthly to the balance (`balance *= 1 + TR_rate`). Calculator currently assumes TR = 0% (accurate since 2017). To implement: sync BCB série 226 via `api.bcb.gov.br`, store in a `TaxaReferencial` table, apply in `AmortizationSchedule#generate`. Low priority while TR ≈ 0%.
  - Paid installment detection: parsed from transaction description (e.g., "000011", "016/132") — more reliable than date matching since payments may cross months
  - Property valuation (optional, manual update) as an asset to offset the liability
- Future-proof for other liabilities (car financing, loans) with same pattern.

## 5. Functional Requirements

### 5.1 Expense Management (Dashboard 1)

- **Transaction ingestion** from multiple sources (priority order):
  1. Open Finance API (real-time sync)
  2. CSV / OFX / PDF import (bank statements, credit card bills)
  3. Manual entry
  4. ADB screen capture fallback (for banks that don't integrate)
  - **Credit Card Rule**: For credit card imports (CSVs or Open Finance), transactions must be billed to the month of the invoice, not the purchase date. If a transaction is an installment (e.g., "1/3" or "6/10" in the original source), its `date` in the system MUST reflect the invoice due date so it correctly impacts the cash flow of the month it was paid.
- **Automatic categorization** using rules engine + ML fallback
  - User can correct; corrections feed back into the model
  - Pre-seeded with user's existing category tree (see §5.1.1)
  - **Confidence threshold**: configurable (e.g., 0.8 default). Transactions below threshold land in a **review queue** — a dedicated UI where the user sees the suggestion, confirms or reassigns, and the feedback trains the model.
  - **Smart heuristics**: recurring transfers to the same recipient suggest a fixed category (e.g., monthly transfer to "Maria" → "Moradia/Limpeza"); same merchant patterns cluster together; amount + day-of-month patterns detect subscriptions/recurring bills.
  - **Three-tier categorization pipeline**:
    1. **Rule engine** (high confidence): exact merchant match, recipient mapping, regex patterns → auto-categorized, no review needed
    2. **LLM** (medium-high confidence): transaction description + amount + context sent to LLM for category inference. Can run via MCP (Nexus categorizes) or local API call. Falls back to review queue if below threshold.
    3. **Human review queue** (below threshold): dedicated UI showing the LLM's suggestion + confidence score. User confirms or reassigns. Every correction feeds back into the rule engine (creates a new rule) and improves future LLM prompts via few-shot examples.
- **Budget tracking** per category per month
  - Separate budgets: joint vs personal
  - Visual indicators: on-track, warning (>80%), over-budget
- **Monthly summary**: income vs expenses, savings rate, category breakdown
- **Recurring transaction detection**: rent, subscriptions, utilities

#### 5.1.1 Initial Category Tree (Joint Account)

| Category | Subcategories |
|----------|---------------|
| Pet | Comida/Higiene, Veterinário, Roupas/Acessórios |
| Alimentação | Restaurante *(Lanchonete merged in)*, Açougue, Feira/Mercado |
| Moradia | Aluguel, Internet, Serviços, Luz, Gás, Condomínio, Limpeza, Jardineiro, Manutenção |
| Transporte | Connect Car, Estacionamento, Uber, Carro |
| Saúde | Personal, Plano de Saúde, Farmácia, Massagem |
| Compras | Produtos Casa, Presentes |
| Viagem | Passagem, Outros |
| Lazer | Lazer |
| 💸 Mov. Financeiras | Renda, IOF, Previdência, Serviços, Outros |

Personal categories TBD (likely simpler: food, entertainment, tech, subscriptions, etc.)

### 5.2 Investment Portfolio (Dashboard 2)

- **Position tracking**: current holdings grouped by asset type
- **Performance**: absolute return, % return, comparison vs benchmarks (CDI, IBOV, S&P500)
- **Evolution chart**: net worth over time (built from snapshots)
- **Multi-currency**: USD positions converted to BRL at current rate; option to view in original currency
- **Tax helpers**: cost basis tracking for future IR calculations
- **Dividend/yield tracking**: income from investments over time

### 5.3 Consolidated Dashboard

- **Net worth**: all personal + joint assets minus liabilities
- **Monthly cash flow**: all income vs all expenses
- **Savings rate**: (income - expenses) / income
- **Asset allocation**: pie chart by type, currency, broker

### 5.4 Mother's Portfolio (Isolated)

- Separate dashboard, separate navigation section
- Same investment tracking features (position, performance, evolution)
- Report generation: exportable PDF/CSV for her records
- No crossover with personal/joint data

### 5.5 Data Import & Sync

- **Open Finance**: OAuth2 flow, scheduled sync (configurable interval)
- **CSV/PDF/OFX import**: upload via UI, parser per bank format
- **Google Sheets import**: one-time migration tool for historical spreadsheet data ("Orçamento Casa")
- **ADB capture**: structured screen scraping module as last resort

## 6. Non-Functional Requirements

- **Self-hosted**: Docker Compose, single `docker compose up` to run everything
- **Bootstrap scripts**: `bin/setup` that handles DB creation, migrations, seed data, env setup
- **No cloud dependencies**: all services run locally; external APIs (Open Finance, exchange rates) are optional enrichments, not hard requirements
- **Cloud-ready**: stateless app layer, config via env vars, easy to migrate to VPS later
- **Performance**: snappy for 1-3 concurrent users; no need for horizontal scaling
- **Data safety**: Postgres with regular pg_dump; no encryption-at-rest required for MVP but schema should not prevent adding it later

## 7. Tech Stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Backend | **Ruby on Rails 8** (full-stack, Hotwire — not API mode) | Familiar to user; rich ecosystem for financial libs |
| Frontend | **Hotwire (Turbo + Stimulus)** | Rails-native, clean, minimal JS; responsive/PWA-ready |
| Database | **PostgreSQL 16** | JSONB for flexible metadata, strong decimal/money support |
| Background Jobs | **Solid Queue** | Rails 8 default, no Redis dependency |
| Caching | **Solid Cache** | Rails 8 default, DB-backed |
| Containerization | **Docker Compose** | App + Postgres + (optional) worker |
| CSS | **Tailwind CSS** | Utility-first, clean, good for dashboards |
| Charts | **Chart.js** or **ApexCharts** via Stimulus | Lightweight, no heavy JS framework needed |
| Exchange Rates | **Open Exchange Rates** or **ECB** (free) | Scheduled daily fetch, cached locally |
| Categorization | **Rule engine → LLM → human review** | Three-tier pipeline (see §5.1) |

### MCP Layer (Model Context Protocol)

Assimilator exposes an MCP server so AI assistants (OpenClaw, Claude, etc.) can interact with financial data programmatically.

**MCP Tools (implemented):**
- `accounts.list` — list all financial accounts
- `transactions.search` — search/filter transactions by date, category, amount, account
- `transactions.create` — add a transaction manually
- `transactions.categorize` — categorize a transaction
- `budget.status` — current month budget vs actual per category
- `import.csv` — trigger a CSV import from a file path
- `reports.monthly` — generate a monthly expense report

**MCP Resources (read-only context):**
- `households` — household info
- `categories` — category tree
- `rules` — active categorization rules

**v2 MCP tools (planned):**
- `portfolio.summary` — investment positions, net worth, allocation
- `portfolio.performance` — returns vs benchmarks
- `reports.mother` — mother's portfolio report

Implementation: lightweight Ruby MCP server (JSON-RPC 2.0 over stdio) that reuses Rails models/services. Packaged as a separate entrypoint in the same Docker image (`bin/mcp`). OpenClaw integration via mcporter pending.

### Why Hotwire over React/Svelte?

- Keeps the stack pure Ruby/Rails — no separate frontend build, no TypeScript, no node_modules
- Turbo Frames + Streams handle the interactivity needed (live updates, inline edits, modals)
- Stimulus controllers stay small and readable
- PWA installable via standard Rails manifest
- If heavy interactivity is needed later for specific views (complex charts, drag-and-drop), a Stimulus wrapper around a JS charting lib handles it fine

## 8. Architecture

```
┌─────────────────────────────────────────┐
│              Docker Compose             │
│                                         │
│  ┌──────────┐  ┌──────────┐            │
│  │  Rails    │  │ Postgres │            │
│  │  App      │──│   16     │            │
│  │  (Puma)   │  └──────────┘            │
│  │           │                          │
│  │  Solid    │  ┌──────────────────┐    │
│  │  Queue    │  │ Open Finance     │    │
│  │  (worker) │──│ Sync Worker      │    │
│  └──────────┘  └──────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
         │
         ▼ PWA (Hotwire)
    ┌──────────┐
    │ Browser  │
    │ (mobile/ │
    │ desktop) │
    └──────────┘
```

Single Rails process with Solid Queue for background jobs (Open Finance sync, import processing, snapshot generation, categorization). No Redis, no Sidekiq, minimal moving parts.

## 9. Roadmap

### v1 — Expense Management & Cash Flow

1. **Project scaffold**: Rails 8, Docker Compose, bootstrap scripts, auth
2. **Core models**: User, Household, Financial Account, Transaction, Category, Budget, Liability
3. **Manual entry + CSV/OFX import**: transaction CRUD, CSV/OFX parsers (XP, Nubank, Wise formats)
4. **Google Sheets import**: one-time migration of historical "Orçamento Casa" spreadsheet
5. **Auto-categorization**: three-tier pipeline (rules → LLM → human review) + confidence threshold + review queue UI + smart heuristics
6. **Budget tracking**: per-category monthly limits, joint vs personal budgets, visual indicators
7. **Expense dashboard**: monthly view, category breakdown, income vs expenses, savings rate
8. **Mortgage tracker**: outstanding balance, amortization schedule, principal vs interest
9. **Open Finance integration**: OAuth flow, sync worker (Pluggy or equivalent)
10. **PWA setup**: manifest, service worker, installable on mobile
11. **MCP server**: JSON-RPC stdio interface for AI assistant integration

### v2 — Investment Portfolio

12. **Investment models**: Position, Investment Transaction, Snapshot, multi-currency
13. **Investment dashboard**: positions by asset type, performance vs benchmarks (CDI, IBOV, S&P500)
14. **Portfolio evolution**: historical net worth chart from snapshots
15. **Mother's isolated portfolio**: separate scope, dashboard, report export (PDF/CSV)
16. **Consolidated dashboard**: full net worth (assets - liabilities), asset allocation, cash flow
17. **Dividend/yield tracking**: investment income over time
18. **Tax helpers**: cost basis tracking for IR

### v3 — Advanced Features

19. **Travel module**: trip entity, per-day budget by category/currency, trip dashboard
20. **Email scraping**: Gmail integration to backfill historical investment snapshots
21. **PDF statement parser**: structured extraction from bank/brokerage PDFs
22. **ADB fallback module**: screen capture + OCR for non-integrated banks
23. **Native mobile app** (if PWA isn't sufficient)

## 10. Project Name

**Assimilator** — the Protoss building that extracts and processes vespene gas (resources). Fits the StarCraft Protoss naming convention used across the ecosystem (Nexus, Recall, etc.).

## 11. Repository & Location

- Code: `~/projects/assimilator/`
- Specs: `/home/abacha/.openclaw/shared-workspace/specs/assimilator/`

## 12. Open Questions

1. ~~**Open Finance provider**~~ — **Resolved**: Pluggy selected and integrated. Pluggy widget for OAuth flow, REST API for sync. Handles XP and Nubank. Known quirk: Itaú OFX files use hybrid SGML/XML format requiring per-tag conversion before parsing.
2. ~~**Exchange rate source**~~ — **Resolved**: BCB (Banco Central do Brasil) PTAX API chosen. `ExchangeRates::BcbFetcher` service planned for Phase 13 (not yet implemented).
