<div align="center">

<img src="https://sema-lang.com/logo.svg" alt="Sema" height="64">

# Sema for Helix

**[Sema](https://sema-lang.com) support for [Helix](https://helix-editor.com)** — a Lisp with first-class LLM primitives.

[![CI](https://img.shields.io/github/actions/workflow/status/sema-lisp/helix-sema/ci.yml?branch=main&label=CI&logo=github)](https://github.com/sema-lisp/helix-sema/actions)
[![License](https://img.shields.io/github/license/sema-lisp/helix-sema?color=c8a855)](LICENSE)
[![Website](https://img.shields.io/badge/website-sema--lang.com-c8a855)](https://sema-lang.com)

</div>

Language configuration for Sema in the Helix editor. Provides tree-sitter syntax highlighting and LSP integration for `.sema` files.

## Install

Helix has no plugin system, so support is installed by placing the grammar queries in Helix's runtime directory and merging the language config into your `~/.config/helix/`. There's no plugin-based auto-install; the options are the script below (recommended) or the manual steps.

### Quick install (script)

```sh
git clone https://github.com/sema-lisp/helix-sema.git
cd helix-sema
./install.sh
```

The script copies the queries into `~/.config/helix/runtime/queries/sema/`, merges the language config into your `languages.toml` (idempotent — it won't duplicate an existing `sema` entry), and builds the grammar. Verify with `hx --health sema` (expect all ✓). Respects `XDG_CONFIG_HOME`.

### Manual install

<details><summary>Prefer to do it by hand? Expand.</summary>

#### 1. Add the language and grammar definitions

Append the `[[language]]`, `[language-server.sema-lsp]`, `[language.auto-pairs]`, and `[[grammar]]` sections from this repo's [`languages.toml`](languages.toml) to your own `~/.config/helix/languages.toml`:

```sh
cat languages.toml >> ~/.config/helix/languages.toml
```

> If you already have a `languages.toml`, merge the sections by hand rather than concatenating, to avoid duplicate keys.

#### 2. Copy the query files

```sh
mkdir -p ~/.config/helix/runtime/queries/sema
cp queries/sema/*.scm ~/.config/helix/runtime/queries/sema/
```

#### 3. Fetch and build the grammar

```sh
hx --grammar fetch
hx --grammar build
```

#### 4. Verify

```sh
hx --health sema
```

</details>

Then open any `.sema` file (`hx hello.sema`); `hx --health sema` should report the language server, debug adapter, tree-sitter parser, and all queries as ✓.

## Features

- **Tree-sitter syntax highlighting** via the dedicated [tree-sitter-sema](https://github.com/sema-lisp/tree-sitter-sema) grammar (pinned to `v0.2.0`) — special forms, LLM primitives (`llm/chat`, `defagent`, `deftool`, …), slash-namespaced builtins, keyword literals (`:foo`), booleans, `nil`, strings, and comments
- **Language server** via `sema lsp` — completions, hover, go-to-definition, references, rename, semantic tokens, and more
- **Debugging (DAP)** via `sema dap` — launch-and-debug `.sema` programs with breakpoints, stepping, and variable inspection (see [Debugging](#debugging))
- **Smart auto-pairs** for `()`, `[]`, `{}`, `""`
- **Comment support** (`;` line comments) and 2-space indentation

### How it works

The `grammar = "sema"` setting tells Helix to parse `.sema` files with the [tree-sitter-sema](https://github.com/sema-lisp/tree-sitter-sema) grammar, which natively understands Sema syntax like keyword literals (`:name`), hash maps, and vectors. The query files in `queries/sema/` add Sema-specific captures for LLM primitives, slash-namespaced builtins, and special forms. The `[language-server.sema-lsp]` block wires Helix to the language server shipped in the `sema` binary (`sema lsp`).

### Debugging

Sema's debug adapter (`sema dap`) is wired via the `[language.debugger]` block, with two launch templates. To start a session:

```
:debug-start launch <path-to-file.sema>
```

or use the **launch (stop on entry)** template to pause at the first form:

```
:debug-start 'launch (stop on entry)' <path-to-file.sema>
```

> **Workspace trust:** Helix (0.25+) gates debug adapters behind workspace trust. If `:debug-start` does nothing, run `:workspace-trust` first (Helix refuses to spawn a debugger in an untrusted workspace).

Set breakpoints with `<space>` `Space` on a line, then step/continue with the debug commands (`:debug-*`). Program output appears in Helix's status/log.

### Troubleshooting

- **No highlighting?** Confirm the query files landed in `~/.config/helix/runtime/queries/sema/` and that `HELIX_RUNTIME` is not pointing elsewhere.
- **Grammar not found?** Re-run `hx --grammar fetch && hx --grammar build`.
- **No LSP features?** Make sure `sema` is on your `PATH`; `hx --health sema` reports whether the language server was found.
- **Debugger won't start?** Run `:workspace-trust` (Helix blocks debug adapters in untrusted workspaces), and confirm `hx --health sema` shows the debug adapter ✓.
- **Stale config?** Restart Helix after editing `languages.toml` — it does not hot-reload language configuration.

## Requirements

- The [`sema`](https://github.com/HelgeSverre/sema) binary on your `PATH` (provides the language server via `sema lsp`)
- [Helix](https://helix-editor.com) 23.10 or newer
- A C compiler (`cc`/`gcc`/`clang`) — Helix compiles the tree-sitter grammar locally

## Links

- **Website** — [sema-lang.com](https://sema-lang.com)
- **Playground** — [sema.run](https://sema.run)
- **Documentation** — [sema-lang.com/docs](https://sema-lang.com/docs/)
- **Grammar** — [tree-sitter-sema](https://github.com/sema-lisp/tree-sitter-sema)
- **Repository** — [sema-lisp/helix-sema](https://github.com/sema-lisp/helix-sema)

## License

[MIT](LICENSE) © [Helge Sverre](https://github.com/HelgeSverre)
