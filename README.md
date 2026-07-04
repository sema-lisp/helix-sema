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

Helix has no plugin system, so you merge this configuration into your own Helix config directory (`~/.config/helix/`).

### 1. Add the language and grammar definitions

Append the `[[language]]`, `[language-server.sema-lsp]`, `[language.auto-pairs]`, and `[[grammar]]` sections from this repo's [`languages.toml`](languages.toml) to your own `~/.config/helix/languages.toml`:

```sh
cat languages.toml >> ~/.config/helix/languages.toml
```

> If you already have a `languages.toml`, merge the sections by hand rather than concatenating, to avoid duplicate keys.

### 2. Copy the query files

```sh
mkdir -p ~/.config/helix/runtime/queries/sema
cp queries/sema/*.scm ~/.config/helix/runtime/queries/sema/
```

### 3. Fetch and build the grammar

```sh
hx --grammar fetch
hx --grammar build
```

### 4. Verify

```sh
hx --health sema
```

Then open any `.sema` file:

```sh
hx hello.sema
```

## Features

- **Tree-sitter syntax highlighting** via the dedicated [tree-sitter-sema](https://github.com/sema-lisp/tree-sitter-sema) grammar (pinned to `v0.2.0`) — special forms, LLM primitives (`llm/chat`, `defagent`, `deftool`, …), slash-namespaced builtins, keyword literals (`:foo`), booleans, `nil`, strings, and comments
- **Language server** via `sema lsp` — completions, hover, go-to-definition, references, rename, semantic tokens, and more
- **Smart auto-pairs** for `()`, `[]`, `{}`, `""`
- **Comment support** (`;` line comments) and 2-space indentation

### How it works

The `grammar = "sema"` setting tells Helix to parse `.sema` files with the [tree-sitter-sema](https://github.com/sema-lisp/tree-sitter-sema) grammar, which natively understands Sema syntax like keyword literals (`:name`), hash maps, and vectors. The query files in `queries/sema/` add Sema-specific captures for LLM primitives, slash-namespaced builtins, and special forms. The `[language-server.sema-lsp]` block wires Helix to the language server shipped in the `sema` binary (`sema lsp`).

### Troubleshooting

- **No highlighting?** Confirm the query files landed in `~/.config/helix/runtime/queries/sema/` and that `HELIX_RUNTIME` is not pointing elsewhere.
- **Grammar not found?** Re-run `hx --grammar fetch && hx --grammar build`.
- **No LSP features?** Make sure `sema` is on your `PATH`; `hx --health sema` reports whether the language server was found.
- **Stale config?** Restart Helix after editing `languages.toml` — it does not hot-reload language configuration.

## Requirements

- The [`sema`](https://github.com/HelgeSverre/sema) binary on your `PATH` (provides the language server via `sema lsp`)
- [Helix](https://helix-editor.com) 23.10 or newer
- A C compiler (`cc`/`gcc`/`clang`) — Helix compiles the tree-sitter grammar locally

## Roadmap

Upstreaming this configuration into [helix-editor/helix](https://github.com/helix-editor/helix) once Sema adoption supports inclusion in the default distribution.

## Links

- **Website** — [sema-lang.com](https://sema-lang.com)
- **Playground** — [sema.run](https://sema.run)
- **Documentation** — [sema-lang.com/docs](https://sema-lang.com/docs/)
- **Grammar** — [tree-sitter-sema](https://github.com/sema-lisp/tree-sitter-sema)
- **Repository** — [sema-lisp/helix-sema](https://github.com/sema-lisp/helix-sema)

## License

[MIT](LICENSE) © [Helge Sverre](https://github.com/HelgeSverre)
