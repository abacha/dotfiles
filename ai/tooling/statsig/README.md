# Statsig CLI notes

This is a simple wrapper around the Statsig console APIs. Use `manage.rb` for listing, getting, creating, updating, or cloning experiments/configs/layers/gates.

## Common flows

- **List and search experiments/layers**
  ```bash
  ./manage.rb list experiment
  ./manage.rb list layer -s "getting"
  ```

- **Read an entity details**
  ```bash
  ./manage.rb read layer getting-started
  ```

- **Update a layer parameter safely (Merge / Add)**
  Instead of sending the full payload which overwrites all existing parameters, use `--add-param` to append or update a single parameter in a Layer.
  ```bash
  ./manage.rb update layer getting-started --add-param '{"name": "show_icons", "type": "boolean", "defaultValue": false}'
  ```

- **Copy an existing experiment** (e.g., to change `idType` or target criteria)
  ```bash
  ./manage.rb clone experiment AR0092_estimated_charges_email_deflection AR0092B_estimated_charges_email_deflection --id-type organizationID --tags "Growth - Retention" --status setup
  ```
  This clones the source entity, generates fresh group/rule IDs, copies hypotheses/metrics, and allows overriding tags, status, and the destination ID once the clone payload is built.

- **Create a new entity with custom metadata**
  ```bash
  ./manage.rb create experiment AR0123_new_flow --id-type userID --tags "Core" --status setup --description "My new experiment"
  ```

- **Update an experiment**
  ```bash
  ./manage.rb update experiment AR0123_new_flow --payload '{"hypothesis":"New hypothesis"}'
  ```

## Notes

- `manage.rb` uses `STATSIG_CONSOLE_API_KEY`/`STATSIG_CONSOLE_KEY` from the environment; export whichever key has management permissions before running the script.
- When cloning, the inline targeting rules are duplicated and switched to the requested `--id-type` (defaults to the source's `idType`).
- Groups in a clone always receive randomly generated IDs so you can safely create a fresh experiment without collisions.
