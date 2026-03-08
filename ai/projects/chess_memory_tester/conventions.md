# Chess Memory Tester — UX & UI Conventions
> Project path: `~/projects/trag/chess_memory_tester`

## Core UX Rules
- Moves are made by click/drag only; no text input for moves.
- Wrong move: board border turns red. Only show the correct move after "Hint".
- Comments from PGN should be shown in the move list with clear association.
- Line completion panel should sit below board + list (no overlay).
- Replay supports buttons + keyboard:
  - ArrowRight/ArrowLeft: step
  - ArrowUp: first move
  - ArrowDown: last move
  - Space: play/pause

## i18n
- All user-visible strings must go through `apps/web/src/i18n/index.js`.
- EN is default, PT-BR available. Store locale in localStorage.
- Avoid hardcoded strings in JSX.

## Visual/Layout Notes
- Keep the move list and board same height; move list scrolls internally.
- CTA buttons should not wrap in a way that breaks layout.
- Avoid over-padding and extra vertical scroll.

## Agent Responsibilities
- Keep the project running through Docker at all times unless the user requests otherwise.
- Run all tests after major changes or when switching contexts.
