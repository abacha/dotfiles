#!/usr/bin/env bash

set -e

echo "Migrating Gemini setup to Agy setup..."

# 1. Uninstall gemini-cli
echo "Uninstalling @google/gemini-cli..."
npm uninstall -g @google/gemini-cli || echo "Warning: failed to uninstall or already uninstalled."

# Force clean up lingering symlinks and packages in user local prefix
rm -f "$HOME/.local/bin/gemini"
rm -rf "$HOME/.local/lib/node_modules/@google/gemini-cli"
rm -f "$HOME/.asdf/shims/gemini"

# 2. Migrate ~/.gemini to ~/.agy (idempotent — safe to re-run)
mkdir -p "$HOME/.agy"

if [ -d "$HOME/.gemini" ]; then
  echo "Migrating ~/.gemini to ~/.agy..."

  # Exclude antigravity-cli — antigravity always writes there directly, moving it is pointless
  rsync -a --exclude="antigravity-cli" "$HOME/.gemini/" "$HOME/.agy/"

  # Rename specific files/folders if they exist
  if [ -f "$HOME/.agy/gemini-credentials.json" ]; then
    mv "$HOME/.agy/gemini-credentials.json" "$HOME/.agy/agy-credentials.json"
  fi

  if [ -f "$HOME/.agy/hooks/rtk-hook-gemini.sh" ]; then
    mv "$HOME/.agy/hooks/rtk-hook-gemini.sh" "$HOME/.agy/hooks/rtk-hook-agy.sh"
    sed -i 's/gemini/agy/g' "$HOME/.agy/hooks/rtk-hook-agy.sh" || true
  fi

  if [ -f "$HOME/.agy/GEMINI.md" ]; then
    rm -f "$HOME/.agy/GEMINI.md"
  fi
else
  echo "No ~/.gemini directory found. Skipping base data migration."
fi

# 3. Remove ~/.gemini if now empty (or only has empty subdirs)
if [ -d "$HOME/.gemini" ]; then
  if [ -z "$(find "$HOME/.gemini" -mindepth 1 -maxdepth 1)" ]; then
    rm -rf "$HOME/.gemini"
    echo "Removed empty ~/.gemini."
  else
    echo "Warning: ~/.gemini still has contents after migration: $(ls "$HOME/.gemini")"
  fi
fi

# 4. Rename project-specific GEMINI.md files to AGY.md
if [ -d "$HOME/projects" ]; then
  echo "🔍 Renaming project-specific GEMINI.md files to AGY.md..."
  find "$HOME/projects" -name "GEMINI.md" -execdir mv {} AGY.md \; 2>/dev/null || true
  echo "✅ Renamed project-specific configuration files."
fi

echo "🎉 Migration complete!"
