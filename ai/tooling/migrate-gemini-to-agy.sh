#!/usr/bin/env bash

set -e

echo "🚀 Migrating Gemini setup to Agy setup..."

# 1. Uninstall gemini-cli
echo "📦 Uninstalling @google/gemini-cli..."
npm uninstall -g @google/gemini-cli || echo "⚠️  Failed to uninstall or already uninstalled."

# Force clean up lingering symlinks and packages in user local prefix
rm -f "$HOME/.local/bin/gemini"
rm -rf "$HOME/.local/lib/node_modules/@google/gemini-cli"
rm -f "$HOME/.asdf/shims/gemini"

# 2. Migrate ~/.gemini to ~/.agy
if [ -d "$HOME/.gemini" ]; then
  echo "📂 Migrating ~/.gemini to ~/.agy..."
  mkdir -p "$HOME/.agy"
  
  # Sync contents, preserving symlinks where possible or overwriting
  rsync -a "$HOME/.gemini/" "$HOME/.agy/"
  
  # Rename specific files/folders if they exist
  if [ -f "$HOME/.agy/gemini-credentials.json" ]; then
    mv "$HOME/.agy/gemini-credentials.json" "$HOME/.agy/agy-credentials.json"
  fi
  
  if [ -f "$HOME/.agy/hooks/rtk-hook-gemini.sh" ]; then
    mv "$HOME/.agy/hooks/rtk-hook-gemini.sh" "$HOME/.agy/hooks/rtk-hook-agy.sh"
    # Also update the content of the hook if it contains 'gemini'
    sed -i 's/gemini/agy/g' "$HOME/.agy/hooks/rtk-hook-agy.sh" || true
  fi

  if [ -f "$HOME/.agy/GEMINI.md" ]; then
    # We remove the old name; setup.sh handles linking AGY.md
    rm -f "$HOME/.agy/GEMINI.md"
  fi
  
  # Remove the old gemini directory
  rm -rf "$HOME/.gemini"
  echo "✅ Moved history and sessions."
else
  echo "ℹ️  No ~/.gemini directory found. Skipping data migration."
fi

# 3. Rename project-specific GEMINI.md files to AGY.md
if [ -d "$HOME/projects" ]; then
  echo "🔍 Renaming project-specific GEMINI.md files to AGY.md..."
  find "$HOME/projects" -name "GEMINI.md" -execdir mv {} AGY.md \; 2>/dev/null || true
  echo "✅ Renamed project-specific configuration files."
fi

echo "🎉 Migration complete!"
