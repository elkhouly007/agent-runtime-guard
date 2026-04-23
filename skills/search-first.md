# Skill: search-first

## Purpose

Apply the search-first development pattern — look up current documentation, API specs, and library behavior before writing code, rather than relying on training-data assumptions that may be stale.

## Trigger

- Working with a library, API, or framework that changes frequently (Next.js, LangChain, Anthropic SDK, etc.)
- The user asks about a specific API version, feature flag, or recently changed behavior
- A generated code snippet keeps failing with import errors or deprecated API calls
- Before implementing any external service integration

## Trigger

`/search-first` or `use search-first for [library/API]`

## Steps

1. **Identify what needs verification**
   - What library/API is being used?
   - What version is installed? (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`)
   - What specific behavior is uncertain?

2. **Look up current documentation**
   - Check the installed version's changelog or migration guide first.
   - Use `docs-lookup` agent to fetch official documentation.
   - Check GitHub releases or CHANGELOG.md for the library.

3. **Verify the API surface**
   - Read the type definitions or source if docs are unclear.
   - Run a minimal reproduction in a scratch file before integrating.

4. **Write code against verified behavior**
   - Only use APIs confirmed by current docs — not from memory.
   - Add a comment with the doc source and version when the behavior is non-obvious.

## Examples of When This Saves Time

| Scenario | Risk Without Search-First |
|----------|--------------------------|
| Next.js `fetch` caching | Changed defaults in v13, v14, v15 — wrong assumption = silent stale data |
| LangChain chain construction | API changed 3 times in 6 months — old patterns throw at runtime |
| Anthropic SDK `client.messages` | Tool use format changed — wrong schema = API error |
| FastAPI dependency injection | Behavior differs between 0.9x and 0.10x |
| React Server Components | New primitives added frequently — training data may not cover latest |

## Integration with Other Skills

- Activate before any skill that uses a rapidly-evolving library.
- Works alongside `docs-lookup` agent for fetching and summarizing documentation.
- Works alongside `cost-aware-llm-pipeline` when selecting model versions.

## Safe Behavior

- This skill is advisory — it guides the approach, does not write code itself.
- Never assume training-data knowledge is current for version-sensitive APIs.
- If documentation is unavailable, say so explicitly rather than guessing.
