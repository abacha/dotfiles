# Hubstaff Local Environment Notes

This doc explains the `hs-local` stack and `.sre-toolkit` helpers that spin up Hubstaff’s development services (Postgres, Traefik, etc.) so you can keep it alongside your other AI projects.

## Running the stack
The core helper is located inside `~/.sre-toolkit/bin/hs-local`. It delegates to Docker Compose files that live under `~/.sre-toolkit/local`. The usual startup sequence is:

1. `hs-local services start` – boots the shared infrastructure (Postgres, Redis, ClickHouse, Traefik, etc.).
2. `hs-local account start <repo>` – boots the account-specific Rails app and sidecars (you may need to run it once per repo).
3. `hs-local server start <repo>` – runs the server process if you prefer it separately.

Each command simply calls `docker compose -f <compose file>` from the toolkit directory, so you can open that YAML manually to understand what services are configured.

## Port collisions & overrides
The Compose file at `~/.sre-toolkit/local/compose.services.yml` is the only place the stack exposes host ports (see `ports:` sections for Postgres, Redis, Traefik, etc.). To avoid collisions when you run another project that also uses 5432/80/8080:

- Edit `compose.services.yml` locally before running `hs-local services start` and change the left-hand side of the `ports:` entries (e.g., `"5433:5432"`, `"9080:80"`).
- These edits are outside your tracked repos, so they stay uncommitted. You can keep a personal copy or script that rewrites the file before launching, or run `docker compose -f local/compose.services.yml -f local/compose.override.yml up` manually if you need persistent overrides.
- Alternatively, stop/pause one stack while the other is running, or use network isolation (WSL distro, Podman machine) so each stack has its own namespace.

## Tips
- When you need to bring up the Hubstaff stack for short-lived debugging, edit the ports immediately before `hs-local services start` and rerun `hs-local services restart` once you’re done.
- Document the custom ports you’re using in this file so you remember them later.
- Since the toolkit scripts already call `docker compose` with that base file, there’s no extra command-line flag—just edit the YAML directly and restart the service.

Keep this file updated if you discover any new quirks or additional helpers.
