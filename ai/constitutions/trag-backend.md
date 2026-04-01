# Trag Backend — Constitution
> Project path: `~/projects/trag/trag-backend`

## 1. Coding Standards & Paradigms
- **Functional Paradigm:** Do not use classes for business logic, services, or utilities. Rely strictly on functional programming paradigms.
- **Interfaces & Types:** All interfaces and types must be extracted into their own separate files within a dedicated `interfaces/` or `types/` directory (never inline them within implementation files like `index.ts` or `calculator.ts`). Use interfaces for resolver return types to avoid forced `as` assertions.
- **Naming Conventions:**
  - **Files:** `PascalCase` for Resolvers and GraphQL Types/Schemas (e.g., `AuthResolver.ts`, `LoginSchema.ts`). `camelCase` for Services, Repositories, Helpers, and utility files (e.g., `userRepository.ts`, `customErrorHandler.ts`).
  - **Variables and Properties:** Heavily use `snake_case` for all variable names, function arguments/parameters, array elements, and database fields (e.g., `user_device_info`, `start_date`, `insurance_policy_id`). Do not let JavaScript/TypeScript standard `camelCase` conventions leak into your variables.
  - **Functions and Methods:** `camelCase` (e.g., `resolveRiskType`, `customErrorHandler`). Maintain functions in `camelCase` even when internal variables or parameters are `snake_case`.
  - **Types and Interfaces (TypeScript):** `PascalCase` (e.g., `TriggerOptimizerOptionsInput`).
  - **Constants:** `UPPER_SNAKE_CASE` (e.g., `TRIGGER_OPTIMIZER_MIN_TARGET_RATE`).
- **Error Handling:**
  - Wrap business logic in `try/catch` blocks and consistently use `throw customErrorHandler(err);` imported from `src/shared/customErrors/customErrorHandler.ts`.
  - Prisma errors (`PrismaClientKnownRequestError`) are intercepted by the handler and mapped to user-friendly, translated Portuguese messages based on Prisma error codes (e.g., unique constraints or foreign key violations).

## 2. Project Structure & Architecture
- **Layer Isolation:** 
  - `src/db/repository/`: Abstracted database operations. No direct Prisma calls in services or resolvers.
  - `src/services/`: Core business logic grouped by domain (e.g., `auth/`, `insurancePolicy/`). Keep `src/resolvers` thin. `index.ts` files within domain folders act as controllers/entrypoints and should only export the primary services called by resolvers. All auxiliary logic, helpers, and internal calculations must be extracted to separate files (e.g., `helpers.ts`, `calculator.ts`).
  - `src/shared/`: Cross-cutting concerns like `config/`, `customErrors/`, `helpers/`, `middleware/`, `utils/`, `pdf/`, etc.
  - `src/resolvers/` & `src/schemas/`: GraphQL layer endpoints and TypeGraphQL classes.
  - `src/inputs/` & `src/interfaces/`: Input arguments and TypeScript typings. (Do not leave generic `types.ts` files inside feature folders like `core/`; always extract and move them to `interfaces`).
- **Async & Queues:** Long-running operations, especially climatic data parsing and document generation (Proposals/Simulations PDFs via `@sparticuz/chromium`), should be offloaded to PubSub workers or PM2 async jobs to prevent GraphQL request timeouts.
- **Document Templates & Static Assets:** All email templates, EJS/HBS PDFs for climatic reports, proposals, and simulations must remain in `src/shared/pdf` or `src/shared/emailTemplate`. Never rely on absolute paths or `__dirname` logic that fails when running the compiled JavaScript in `dist`. Use the `yarn build` pipeline's `copyfiles` process to ensure the runtime can access templates in production.

## 3. Core Product Rules & Guardrails
- **Type Safety:** Maintain TypeGraphQL type safety across all resolvers, inputs, and schemas. Rely strictly on `class-validator` decorators in `src/inputs` and avoid manual validation boilerplate in resolvers.
- **Database & Prisma:** 
  - Ensure Prisma transactions are used for multi-table domain operations (e.g., Insurance Policy + Producer + Risk).
  - Use Prisma's nested writes (`create`, `upsert`, `deleteMany`) often paired with helpers like `UpsertAndDelete`.
  - Complex searches often use the `executeUnaccentSearchForIds` pattern first, followed by an `in` Prisma query to fetch the full records.
- **Authorization:** Do not bypass the central authorization middleware (`@authChecker`) inside resolvers for protected mutations or queries.
- **External Integrations:** All external API interactions (Google Cloud PubSub, Earth Engine, Maps, Varda) must be wrapped with appropriate retry and custom error formatting rules (using `formatErrors.ts`).
- **Configuration:** Secrets, topic names, queue names, and external API keys must not be hardcoded. Rely on `.env` injected configurations.
- **Monitoring / Tracing:** OpenTelemetry (`src/otel.ts`) must be loaded correctly before bootstrapping the server or any jobs. Do not disable or break the auto-instrumentation of Node/HTTP and Prisma without user approval.
- **API Compatibility:** When modifying `src/schemas` or `@Field` decorations on TypeGraphQL classes, avoid removing or dramatically changing existing types without deprecation flags unless instructed. Use standardized pagination, limits, and order rules for list endpoints.

## 4. Development Workflow & Testing
- **Package Manager:** All dependencies and scripts should be run using `yarn`. Do not use `npm` unless explicit.
- **Testing Rules:**
  - Tests are placed in a root-level `tests/` folder mirroring the `src/` directory structure.
  - Files are named with `.spec.ts` or `.test.ts` suffixes.
  - Run `yarn test:unit` and `yarn test:integration` before finalizing changes.
- **Linting & Formatting:** Always run `yarn eslint:check`.
- **Database Migrations:** Run `yarn db:migrate:dev` and `yarn prisma generate` if schema changes. Use `yarn db:seed` if a seed is needed after a DB wipe.
- **Build Process:** For the production build (`yarn build`), ensure all template files are correctly copied to the `dist` directory via the `copyTemplates` scripts.
- **Commit Hygiene:** Keep commits objective-focused (`feat:`, `fix:`, `refactor:`). Document why the change exists. Do not commit or push unless explicitly requested.


# Project Overview & Domain Logic

# Trag Backend — Overview
> Project path: `~/projects/trag/trag-backend`

## Scope
- **Purpose:** Backend platform for agricultural and parametric insurance, handling insurance policies, producers, crops, and climatic data/simulations.
- **Stack:**
  - **Runtime & Web:** Node.js, TypeScript, Express, Apollo Server.
  - **API Layer:** GraphQL via TypeGraphQL.
  - **Database & ORM:** PostgreSQL (with PostGIS extensions) and Prisma.
  - **Cloud & Async:** Google Cloud PubSub, Google Cloud Storage, Google Earth Engine.
  - **Monitoring:** OpenTelemetry for tracing.
  - **Job Execution:** PM2 for cron jobs and background workers.
  - **PDF Generation:** `@sparticuz/chromium` with EJS/Handlebars templates.

## Architecture & Modules
The system is heavily structured around agricultural insurance domains and async processing pipelines:

### 1. GraphQL API (`src/resolvers` & `src/schemas`)
- Provides domain-specific mutations and queries via TypeGraphQL resolvers (e.g., `CropResolver`, `InsurancePolicyResolver`, `ProducerResolver`, `TriggerOptimizerResolver`).
- Input validation via `class-validator`.
- Uses a central `@authChecker` middleware for authorization boundaries.

### 2. Business Logic (`src/services`)
- Heavy domain services separating logic from API resolvers (e.g., `insurancePolicy`, `googleCloud`, `queueMonitoring`, `auth`).
- Connects directly to Prisma for database operations.

### 3. Meteorological & Climate Data (`src/shared/metereologicalData`)
- Integrates with Google Earth Engine (`@google/earthengine`) to fetch spatial and temporal weather data.
- Processes triggers and risk parameters for parametric policies.

### 4. Background Jobs & Workers (`src/shared/scripts/pm2` & PubSub)
- **PM2 Jobs:** Scripts configured to run on schedule (e.g., `insurancePolicyValidity`, `insurancePolicyStatusUpdate`) via `pm2`.
- **PubSub Queues:** Handles long-running async tasks asynchronously, monitored via custom `QueueMonitoringResolver`.

### 5. Document Generation (`src/shared/pdf` & `src/shared/emailTemplate`)
- Compiles PDF proposals, climatic reports, and simulations using EJS/HBS templates and Chromium.
- Templates are copied to `dist` during the build process via `copyfiles`.

## Environment Rules
- **Database:** Requires PostgreSQL with PostGIS extension. Run database migrations via Prisma.
- **Local Dev:** Handled via `nodemon` and `ts-node` (`yarn dev`). OpenTelemetry tracing is bootstrapped at startup (`src/otel.ts`).
- **Build Output:** The build (`yarn build`) compiles TypeScript to `dist` using SWC/tsc and securely copies all non-TS templates (PDFs/Emails) into the build folder.

## Related Documentation
- [development.md](./development.md): Setup, build, and deployment workflows.
- [conventions.md](./conventions.md): Code style and pattern guidelines.
