# Trag Web — Constitution
> Project path: `~/projects/trag/trag-web`

## 1. Coding Standards & Paradigms
- **Functional Components:** Used exclusively (e.g., `const OperationsPage = () => { ... }`).
- **Data Fetching (Apollo):** Apollo Client is the standard pattern. Custom hooks `useQuery` and `useLazyQuery` fetch data directly within components, frequently pairing with `fetchPolicy: 'cache-and-network'` and `onError` callbacks for error handling. Mutations use `useMutation` or direct `apolloClient.mutate()`.
- **State Management:**
  - **Local State:** React's `useState` handles UI state (modals, active tabs, form values, pagination, filtering).
  - **Global State:** Handled natively via React Context API, organized in `src/context/` (e.g., `globalContext.tsx`, `AuthContext`, `theme`, `sidebarAndModal`). No Redux or Zustand is used.
  - **Server State:** Handled strictly by Apollo Client hooks (`data`, `loading`, `refetch`).
- **Permissions (RBAC):** Render access is controlled via a wrapper component `<PrivateRoute resource={ResourceNames.InsurancePolicy} requiredPermission="can_read" />`.
- **Naming Conventions:**
  - **Components & Variables:** `PascalCase` for component variables and their main files (e.g., `OperationsPage`, `Searchbar`).
  - **Custom Hooks:** `camelCase` prefixed with `use` (e.g., `useShowSwalError`).
  - **GraphQL:** Operations are `UPPER_SNAKE_CASE` constants (e.g., `QUERY_OPERATION_KPIS`).
  - **Types/Interfaces:** `PascalCase` (e.g., `SelectProps`, `Filters`).
- **Styling Conventions (MUI v6):**
  - **`sx` Prop:** Frequently used for inline, responsive layouts directly on MUI elements.
  - **Styled Components:** Custom elements are extracted into separate `styles.ts` files using MUI's `@mui/material/styles` `styled` API, heavily leveraging the `theme` object.
  - **Theming:** The `useTheme` hook is used heavily inside functional components to access palette and spacing values.
- **Error Handling & Validation:**
  - **Form Validation:** Relies on **Formik** and **Yup**. Schemas are defined as `Yup.object().shape({...})` and passed into a reusable wrapper component `<CustomFormik>`.
  - **API Errors:** Centralized alert modals using SweetAlert2 via custom hooks (`useShowSwalError()`, `useCustomMultilineErrorHandler()`). These are consistently wired into Apollo's `onError` callback hooks.

## 2. Project Structure & Architecture
- **Pages Router:** The project uses the Next.js Pages router (`src/pages`). Do not introduce App router (`src/app`) conventions unless explicitly migrating. Directories group domains (`pages/operacoes/index.tsx`).
- **Component Isolation:** Keep domain-specific components under `src/components/<domain>/<ComponentName>/`.
  - Inside a component folder, you will typically find: `index.tsx` (main logic), `types.ts` (interfaces), and `styles.ts` (styled components).
- **Utility Functions:** Keep math, geo-calculations, and pure logic in `src/utils/` (e.g., `calculateRectangleBounds`, `triggersOptimizer`). Ensure they are fully testable in isolation.
- **Absolute Imports:** Path aliases are strictly used (`@components/`, `@graphql/`, `@utils/`, `@template/`, `@hooks/`).

## 3. Core Product Rules & Guardrails
- **Trigger Calculation Integrity:** Any change touching trigger calculations must validate slope/index behavior. Never regress first-year handling logic for calculations.
- **Status UI Consistency:** If touching status UI (`actionTable` or similar), validate the rendering behavior across all affected page contexts (`operacoes`, `produtores`, etc.).
- **Data Filtering:** Prefer explicit data filtering over complex control flags or boolean toggles when managing list states or table views.
- **Map & Geospatial Rules:**
  - **Leaflet Integration:** When modifying maps, ensure React-Leaflet (`react-leaflet`) components are dynamically loaded if they rely on browser APIs, to avoid Next.js SSR hydration errors.
  - **Polygon Handling:** Always validate MultiPolygon flattening and bounds calculations when manipulating geographic operation areas.

## 4. Development Workflow & Testing
- **API Environment:** For backend data integration in local/dev work, always hit the **staging API** (`https://api.stg.trag.agr.br/`). Ensure authorization tokens are passed correctly without standard prefixes if required by staging.
- **Linting & Formatting:** Always run `npm run lint` or `npm run lint:fix`, and format code with `npm run format`.
- **Testing Rules:**
  - **Trigger/Math Logic:** For any change touching trigger calculations or optimizers (e.g. `src/utils/triggersOptimizer/`), run targeted tests: `npm run test -- __tests__/utils/triggersOptimizer.spec.ts`.
  - **Broad Changes:** For broader behavior changes, run the full test suite (`npm run test`).
  - **E2E Testing:** For critical flow changes, consider running Cypress E2E tests (`npm run cypress:run`).
- **Commit Hygiene:** Keep commits objective-focused (`feat:`, `fix:`, `refactor:`). Document *why* the change exists. Avoid stacking many `fixup!` commits; squash before review. Do not commit or push unless explicitly requested.


# Project Overview & Domain Logic

# Trag Web — Overview
> Project path: `~/projects/trag/trag-web`

## Scope
- **Purpose:** B2B portal for agricultural operations, trigger analysis, consultant and producer management, and weather/climate index tracking.
- **Stack:**
  - **Frontend:** Next.js (Pages Router, v15), React 18, TypeScript.
  - **UI/Styling:** Material UI (MUI v6), Emotion, Chart.js, react-leaflet (Map integration).
  - **Data Fetching:** Apollo Client (GraphQL).
  - **Testing:** Jest (Unit), Cypress (E2E).

## Core Modules & Entities
- **Operações (Operations):** Core business logic for agricultural operations and triggers.
- **Consultores (Consultants):** Management of agricultural consultants.
- **Produtores (Producers):** Management of farmers and agricultural producers.
- **Matrizes (Matrices):** Templates for rules and metrics.
- **Organizacões (Organizations):** Company and hierarchy management.

## Environment & Data Rules
- **Backend Target:** Default backend target is staging (`https://api.stg.trag.agr.br/`).
- **API Routing:** `next.config.js` typically rewrites `/api/graphql` to the staging backend.
- **Authentication:** Staging Authorization token is a naked string (no "Bearer"/"Token" prefix).
- **Map & Geo:** Heavy use of Leaflet for polygons, bounds calculation, and coordinate extraction (`extractUF`, `flattenMultiPolygons`, `calculateRectangleBounds`).

## Related Documentation
- [development.md](./development.md): Setup, build, testing, and deployment workflows.
- [conventions.md](./conventions.md): Code style, product rules, and architectural guidelines.