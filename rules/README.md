# Rules

Language and domain-specific coding standards. The `common/` layer applies everywhere. Language directories extend and override the common layer.

## Structure

| Directory | Covers |
|---|---|
| `common/` | Universal rules: coding style, security, testing, git, performance, workflow |
| `typescript/` | TypeScript, JavaScript, React, Next.js, Node.js |
| `python/` | Python, Django, FastAPI, data science |
| `golang/` | Go |
| `rust/` | Rust |
| `java/` | Java, Spring Boot |
| `kotlin/` | Kotlin, Android |
| `web/` | HTML, CSS, accessibility |

## How to Apply

1. Always apply `common/` rules first.
2. Apply the language-specific rules for the file being reviewed.
3. If the project has its own conventions that conflict, the project conventions win — but flag deviations.

## Adding Language Rules

Create a new directory under `rules/` with at minimum:
- `coding-style.md` — language idioms and style.
- `security.md` — language-specific security patterns.

Follow the import checklist before adding content from external sources.
