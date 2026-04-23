# Skill: documentation-lookup

## Purpose

Find, fetch, and summarize official documentation for a library, API, framework, or tool — without guessing from training data.

## Trigger

- Need the exact API signature, config option, or behavior for a specific library version
- A generated code snippet is failing and the API may have changed
- Asked "how do I do X in [library]?" where the answer is version-sensitive
- Before implementing any third-party integration

## Trigger

`/documentation-lookup [library] [topic]` or `look up [library] docs for [topic]`

## Steps

1. **Identify the library and version**
   - Check `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, or `build.gradle` for installed version.
   - Note the exact version — behavior often differs between minor versions.

2. **Activate `docs-lookup` agent**
   - Pass: library name, version, specific question or API to look up.
   - Agent fetches official documentation and returns a summary.

3. **Verify against the actual source if needed**
   - For critical behavior: read the type definitions or source directly.
   - `node_modules/[lib]/dist/index.d.ts`, `site-packages/[lib]/__init__.py`, etc.

4. **Apply the verified information**
   - Write code against confirmed behavior.
   - Add a comment with version and source when behavior is non-obvious.

## Common Lookups by Ecosystem

| Ecosystem | Where to look |
|-----------|--------------|
| npm/Node | `npmjs.com/package/[name]`, GitHub repo README, TypeScript `.d.ts` |
| Python | `pypi.org/project/[name]`, library's official docs site |
| Go | `pkg.go.dev/[module-path]` |
| Rust | `docs.rs/[crate]` |
| Java/Kotlin | Maven Central Javadoc, Spring docs, official library site |
| Swift | Apple Developer Docs, Swift Package Index |

## Integration with Other Skills

- Always run before `/search-first` identifies a version-sensitive area.
- Run before `/cost-aware-llm-pipeline` to confirm Anthropic SDK API shape.
- Run before `/mcp-server-patterns` to confirm MCP SDK API.

## Safe Behavior

- This skill fetches and summarizes documentation — it does not modify code.
- If official docs are unavailable, says so explicitly rather than falling back to guesses.
- Does not treat training-data knowledge as equivalent to fetched documentation for version-sensitive APIs.
