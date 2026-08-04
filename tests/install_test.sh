#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin"
cat >"$TEST_ROOT/bin/hx" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TEST_ROOT/bin/hx"

assert_header_count() {
  local expected="$1"
  local header="$2"
  local file="$3"
  local actual
  actual="$(grep -c "^\\[\\[$header\\]\\]$" "$file" || true)"
  if [ "$actual" -ne "$expected" ]; then
    echo "expected $expected [[$header]] section(s), found $actual in $file" >&2
    return 1
  fi
}

run_installer() {
  local case_root="$1"
  XDG_CONFIG_HOME="$case_root/config" PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/install.sh" >/dev/null
  python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' \
    "$case_root/config/helix/languages.toml"
}

# A pre-existing grammar must not be mistaken for the language definition.
grammar_only="$TEST_ROOT/grammar-only"
mkdir -p "$grammar_only/config/helix"
cat >"$grammar_only/config/helix/languages.toml" <<'EOF'
[[grammar]]
name = "sema"
source = { git = "https://example.invalid/sema", rev = "main" }
EOF
run_installer "$grammar_only"
assert_header_count 1 language "$grammar_only/config/helix/languages.toml"
assert_header_count 1 grammar "$grammar_only/config/helix/languages.toml"

# The inverse partial configuration receives only the missing grammar.
language_only="$TEST_ROOT/language-only"
mkdir -p "$language_only/config/helix"
cat >"$language_only/config/helix/languages.toml" <<'EOF'
[[language]]
name = "sema"
scope = "source.sema"
EOF
run_installer "$language_only"
assert_header_count 1 language "$language_only/config/helix/languages.toml"
assert_header_count 1 grammar "$language_only/config/helix/languages.toml"

# A complete configuration remains unchanged on repeated installs.
complete="$TEST_ROOT/complete"
mkdir -p "$complete/config/helix"
cp "$ROOT/languages.toml" "$complete/config/helix/languages.toml"
run_installer "$complete"
run_installer "$complete"
assert_header_count 1 language "$complete/config/helix/languages.toml"
assert_header_count 1 grammar "$complete/config/helix/languages.toml"

echo "installer merge tests: clean"
