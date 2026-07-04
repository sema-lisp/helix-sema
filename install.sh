#!/usr/bin/env bash
#
# Install Sema support into your Helix configuration.
#
# Helix has no plugin system, so language support is installed by placing the
# grammar queries in Helix's runtime directory and merging the language config
# into your languages.toml. This script does both idempotently, then builds the
# tree-sitter grammar.
#
# Usage:  ./install.sh
# Verify: hx --health sema
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/helix"
QDIR="$CONFIG/runtime/queries/sema"
LANG="$CONFIG/languages.toml"

echo "Installing Sema support into $CONFIG"

# 1. Queries → runtime (isolated under queries/sema/, always safe to overwrite).
mkdir -p "$QDIR"
cp "$SRC"/queries/sema/*.scm "$QDIR/"
echo "  ✓ queries → $QDIR"

# 2. Language config → languages.toml (create, append-if-absent, or skip).
if [ ! -f "$LANG" ]; then
  mkdir -p "$CONFIG"
  cp "$SRC/languages.toml" "$LANG"
  echo "  ✓ created $LANG"
elif grep -q 'name = "sema"' "$LANG"; then
  echo "  • $LANG already defines a 'sema' language — left untouched"
  echo "    (re-copy from $SRC/languages.toml manually if you want the latest)"
else
  {
    echo ""
    echo "# --- Sema (added by sema-lisp/helix-sema install.sh) ---"
    cat "$SRC/languages.toml"
  } >>"$LANG"
  echo "  ✓ appended Sema config to $LANG"
fi

# 3. Build the tree-sitter grammar from the pinned source.
if command -v hx >/dev/null 2>&1; then
  echo "Building the tree-sitter grammar (requires a C compiler)…"
  hx --grammar fetch
  hx --grammar build
  echo ""
  echo "Done. Verify with:  hx --health sema"
else
  echo "  ! 'hx' not on PATH — after installing Helix, run: hx --grammar fetch && hx --grammar build"
fi
