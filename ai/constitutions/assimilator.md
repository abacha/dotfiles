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
  - Source: `open_finance`, `import_csv`, `import_pdf`, `import_ofx`, `manual`, `recurring_job`
- **Category** — hierarchical (category → subcategory)
- **Budget** — monthly limit per category, scoped to account group (joint vs personal)
- **Recurring Transaction** — templates for recurring events
  - Has frequency (`daily`, `weekly`, `monthly`, `yearly`), next_date, active flag
  - Automatically generates `Transaction` records via background jobs
- **Investment Position** — current holding in an asset
- **Investment Transaction** — buy, sell, dividend, yield, split, etc.
- **Snapshot** — periodic portfolio valuation for historical evolution charts

### 4.2 Account Topology (Initial Setup)

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

### 4.4 Virtual Clearing (Partida Dobrada) & Payroll Deductions

For structural expenses paid outside the primary cash flow (e.g., health insurance deducted directly from a spouse's payroll before the net salary hits the account), we use a "Virtual Clearing" mechanism via Recurring Transactions:
- A monthly `RecurringTransaction` creates two opposing ledger entries on the exact same date.
- **Entry A (The Expense):** `-R$ X` tagged as the actual expense (e.g., `Saúde / Plano de Saúde`).
- **Entry B (The Revenue/Transfer):** `+R$ X` tagged as the funding source (e.g., `Mov. Financeiras / Transf. Interna` representing the spouse's extra contribution).
- **Result:** The account's real cash balance remains 100% accurate (net zero impact), while the analytical dashboards correctly display the household's actual spending and income/contribution.

### 4.5 Liabilities

- **Mortgage / Financing**: tracks outstanding balance, monthly payment, and amortization schedule (SAC/Price).
- Paid installment detection: parsed from transaction description (e.g., "000011", "016/132").

## 5. Functional Requirements

### 5.1 Expense Management & Data Pipelines

- **Transaction ingestion pipelines**:
  1. **Open Finance API** (via Pluggy - syncs real-time via jobs).
  2. **File Imports** (OFX/CSV) - handled asynchronously via `ImportBatch` and Solid Queue.
  3. **Manual Entry & Recurring** - `ProcessRecurringTransactionsJob` generates expected transactions dynamically based on `next_date`.
- **Categorization Engine**:
  - **Rule engine**: exact merchant match, recipient mapping, regex patterns (runs immediately upon ingestion).
  - **LLM**: used for ambiguous descriptions (fallback).
  - **Human review queue**: transactions below the confidence threshold land here. Confirming them trains the rule engine.
  - **Shadow Rules**: strict lock on `status: confirmed` to prevent auto-categorization from continuously rewriting manually fixed or virtual clearing transactions.

### 5.2 File Parsers & Deduplication Strategy

Different file types require distinct ingestion logic to avoid data duplication and ensure chronological integrity.
- **OFX (Gold Standard):** Uses the `FITID` field as an absolute deduplication key. Imports are completely idempotent. Re-importing overlapping OFX files will safely ignore existing entries.
- **CSV (Nubank / XP):** Since CSVs lack guaranteed unique IDs, the parser generates a synthetic hash based on `date + amount + description`. 
  - *XP CSV quirks:* Often has delayed settlement dates or generic descriptions. The import pipeline must carefully evaluate gap days (e.g., weekend rollovers). 
  - *Credit Card Invoice gaps:* When importing CC invoices, overlapping dates are standard (e.g., Feb invoice covers Jan 25 - Feb 24, Mar invoice covers Feb 25 - Mar 24). The system groups these under `AccountPeriod` to reconcile statements vs continuous timelines, relying on the synthetic hashes to prevent double-charging.

## 6. Non-Functional Requirements

- **Self-hosted**: Docker Compose, local-first.
- **Performance**: Solid Queue handles heavy lifting (importing 1000+ CSV lines, running LLM categorization, syncing OF).
- **Data safety**: Postgres with regular pg_dump.

## 7. Tech Stack

- **Backend**: Ruby on Rails 8 (Hotwire, Turbo, Stimulus)
- **Database**: PostgreSQL 16 (JSONB for metadata)
- **Background Jobs**: Solid Queue & Solid Cache
- **CSS**: Tailwind CSS
- **MCP Layer**: Exposes `accounts.list`, `transactions.search`, `transactions.create`, `budget.status`, etc., to OpenClaw.

## 8. Architecture

```
┌──────────────────────────────────────────────┐
│                Docker Compose                │
│                                              │
│  ┌──────────┐  ┌──────────┐                 │
│  │  Rails   │  │ Postgres │                 │
│  │  App     │──│   16     │                 │
│  │  (Puma)  │  └──────────┘                 │
│  │          │                               │
│  │  Solid   │  ┌───────────────────────┐    │
│  │  Queue   │──│ - ImportBatchJob      │    │
│  │ (Worker) │  │ - OpenFinanceSyncJob  │    │
│  └──────────┘  │ - RecurringTxJob      │    │
│                └───────────────────────┘    │
└──────────────────────────────────────────────┘
```

## 9. Roadmap

### Completed (v1 Core)
- Core models: Account, Transaction, Category, Budget, Rules.
- Import pipelines: CSV/OFX parsers for XP/Nubank, auto-deduplication.
- Auto-categorization: Rule engine + Review queue.
- Open Finance: Pluggy integration.
- MCP Server: Basic tool exposure for OpenClaw.
- Virtual Clearing & Recurring Transactions (Backend Job + Models).

### Active / Next (v1.5 - v2)
- Frontend UI for Recurring Transactions (Tailwind + Hotwire).
- Investment tracking (Positions, Snapshots, Evolution charts).
- Mother's isolated portfolio views.
- Consolidated Net Worth dashboard.
- Dividend & Tax helpers.
