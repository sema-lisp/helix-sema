from pathlib import Path


query = Path("queries/sema/highlights.scm").read_text()

assert "(regex) @string.regexp" in query
for name in (
    "regex/match?",
    "regex/match",
    "regex/find-all",
    "regex/replace",
    "regex/replace-all",
    "regex/split",
):
    assert f'"{name}"' in query, name
