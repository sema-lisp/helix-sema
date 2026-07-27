#!/usr/bin/env bash
#
# Install Sema support into your Helix configuration.
#
# Helix has no plugin system, so language support is installed by placing the
# grammar queries in Helix's runtime directory and merging the language config
# into your languages.toml. This script does both idempotently, then builds the
# tree-sitter grammar.
#
# Usage:  ./install.sh [--dry-run]
# Verify: hx --health sema

set -euo pipefail

# Targets bash 3.2 (what macOS ships), so: no associative arrays, no `${x^^}`,
# and every array expansion needs the `${a[@]+…}` guard — under `set -u` bash
# 3.2 treats an empty array as unbound.

DRY_RUN=false

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--dry-run]

Install Sema language support for the Helix editor.

Options:
  --dry-run    Report what would change without touching the filesystem
  --help, -h   Show this message

Steps:
  1. Copy query files to <config>/helix/runtime/queries/sema/
  2. Create or extend <config>/helix/languages.toml
  3. Build the tree-sitter grammar (if hx is on PATH)

Verify with: hx --health sema
USAGE
}

die() {
  echo "ERROR: $*" >&2
  echo >&2
  echo "Troubleshooting:" >&2
  echo "  - Run from the helix-sema repository root" >&2
  echo "  - Check write permissions on \$XDG_CONFIG_HOME (or ~/.config)" >&2
  echo "  - Re-run with --dry-run to see what it would touch" >&2
  exit 1
}

warn() { echo "WARNING: $*" >&2; }

# Paths this run created, newest last — used to roll back a failed install.
# Only paths that did NOT exist beforehand are recorded, so cleanup can never
# delete a file the user already had.
CREATED_FILES=()
CREATED_DIRS=()

cleanup() {
  # $1 is the script's exit status, forwarded by the EXIT trap.
  if [ "${1:-0}" -eq 0 ] || [ "$DRY_RUN" = true ]; then
    return
  fi
  echo >&2
  echo "Install failed — rolling back what this run created..." >&2

  for f in ${CREATED_FILES[@]+"${CREATED_FILES[@]}"}; do
    [ -f "$f" ] || continue
    if rm -f "$f" 2>/dev/null; then
      echo "  removed $f" >&2
    else
      warn "could not remove $f (clean up manually)"
    fi
  done

  # Reverse order: children before parents. Only empty dirs, so a directory
  # that picked up unrelated files is always left alone.
  for (( i = ${#CREATED_DIRS[@]} - 1; i >= 0; i-- )); do
    d="${CREATED_DIRS[$i]}"
    [ -d "$d" ] || continue
    rmdir "$d" 2>/dev/null && echo "  removed $d" >&2 || true
  done
}
trap 'cleanup $?' EXIT

# ── Arguments ────────────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown argument: $arg (try --help)" ;;
  esac
done

# ── Resolve paths ────────────────────────────────────────────────────────────

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[ -d "$SRC/queries/sema" ] || die "Missing $SRC/queries/sema — run from the repository root."
[ -f "$SRC/languages.toml" ] || die "Missing $SRC/languages.toml — run from the repository root."

if [ -n "${XDG_CONFIG_HOME:-}" ]; then
  CONFIG="$XDG_CONFIG_HOME/helix"
elif [ -n "${HOME:-}" ]; then
  CONFIG="$HOME/.config/helix"
else
  die "Neither \$XDG_CONFIG_HOME nor \$HOME is set — cannot locate your Helix config."
fi

QDIR="$CONFIG/runtime/queries/sema"
LANG_TOML="$CONFIG/languages.toml"

echo "Installing Sema support into $CONFIG"
[ "$DRY_RUN" = true ] && echo "  (dry run — nothing will be written)"

# Create a directory, recording it for rollback only if it wasn't already there.
ensure_dir() {
  [ -d "$1" ] && return 0
  mkdir -p "$1" 2>/dev/null || die "Could not create $1 — check permissions and free space."
  CREATED_DIRS+=("$1")
}

# ── 1. Queries → runtime (isolated under queries/sema/, safe to overwrite) ────

# nullglob so a no-match expands to nothing instead of the literal pattern.
shopt -s nullglob
QUERIES=( "$SRC"/queries/sema/*.scm )
shopt -u nullglob
[ ${#QUERIES[@]} -gt 0 ] || die "No .scm query files in $SRC/queries/sema."

if [ "$DRY_RUN" = true ]; then
  echo "  [dry-run] would copy ${#QUERIES[@]} query file(s) → $QDIR"
else
  ensure_dir "$QDIR"
  [ -w "$QDIR" ] || die "$QDIR is not writable — fix permissions."
  for q in "${QUERIES[@]}"; do
    dest="$QDIR/$(basename "$q")"
    # Record only genuinely new files, so a rollback never deletes a query the
    # user had installed before this run.
    [ -e "$dest" ] || CREATED_FILES+=("$dest")
    cp "$q" "$dest" 2>/dev/null || die "Could not copy $q → $dest"
  done
  echo "  ✓ ${#QUERIES[@]} queries → $QDIR"
fi

# ── 2. Language config → languages.toml (create, append-if-absent, or skip) ──

if [ ! -f "$LANG_TOML" ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] would create $LANG_TOML"
  else
    ensure_dir "$CONFIG"
    CREATED_FILES+=("$LANG_TOML")
    cp "$SRC/languages.toml" "$LANG_TOML" 2>/dev/null ||
      die "Could not create $LANG_TOML — check permissions."
    echo "  ✓ created $LANG_TOML"
  fi
elif grep -q 'name = "sema"' "$LANG_TOML" 2>/dev/null; then
  echo "  • $LANG_TOML already defines a 'sema' language — left untouched"
  echo "    (re-copy from $SRC/languages.toml manually if you want the latest)"
else
  if [ "$DRY_RUN" = true ]; then
    echo "  [dry-run] would append Sema config to $LANG_TOML"
  else
    [ -w "$LANG_TOML" ] || die "$LANG_TOML is not writable — fix permissions."
    {
      echo
      echo "# --- Sema (added by sema-lisp/helix-sema install.sh) ---"
      cat "$SRC/languages.toml"
    } >>"$LANG_TOML"
    echo "  ✓ appended Sema config to $LANG_TOML"
  fi
fi

# ── 3. Build the tree-sitter grammar from the pinned source ──────────────────

if ! command -v hx >/dev/null 2>&1; then
  echo "  ! 'hx' not on PATH — after installing Helix, run: hx --grammar fetch && hx --grammar build"
elif [ "$DRY_RUN" = true ]; then
  echo "  [dry-run] would run: hx --grammar fetch && hx --grammar build"
else
  echo "Building the tree-sitter grammar (requires a C compiler)..."
  # Each step reported separately; `hx --grammar fetch` exits non-zero if *any*
  # of its ~250 grammars fails, which is common and not fatal for Sema alone.
  fetch_ok=true
  hx --grammar fetch || fetch_ok=false
  if hx --grammar build; then
    [ "$fetch_ok" = true ] ||
      warn "'hx --grammar fetch' reported errors (often unrelated grammars); the build succeeded."
    echo
    echo "Done. Verify with:  hx --health sema"
  else
    warn "'hx --grammar build' failed. Ensure a C compiler (gcc/clang) is on your PATH,"
    warn "then re-run: hx --grammar fetch && hx --grammar build"
  fi
fi
