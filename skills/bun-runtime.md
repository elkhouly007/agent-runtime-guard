# Skill: bun-runtime

## Purpose

Apply Bun-specific patterns — project setup, API server, testing, bundling, and performance for projects using the Bun JavaScript/TypeScript runtime.

## Trigger

- Starting a new project with Bun as the runtime
- Migrating a Node.js project to Bun
- Asked about Bun APIs, `bun test`, `bun build`, or `bun run`

## Trigger

`/bun-runtime` or `apply bun patterns to [target]`

## Agents

- `typescript-reviewer` — TypeScript quality

## Patterns

### Project Init

```bash
bun init          # interactive setup
bun add <pkg>     # install dependency (fast, uses bun.lockb)
bun add -d <pkg>  # dev dependency
```

- Commit `bun.lockb` — it is binary but deterministic.
- Use `bun.lockb` + `package.json` for reproducible installs in CI.

### HTTP Server

```typescript
const server = Bun.serve({
  port: 3000,
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === "/health") return new Response("ok");
    return new Response("Not Found", { status: 404 });
  },
});
console.log(`Listening on ${server.url}`);
```

- `Bun.serve` uses the WinterCG `Request`/`Response` API — compatible with Cloudflare Workers patterns.
- Set `hostname: "0.0.0.0"` for container deployments.

### File I/O

```typescript
// Read
const text = await Bun.file("data.txt").text();
const json = await Bun.file("config.json").json();

// Write
await Bun.write("output.txt", "hello");
```

- Prefer `Bun.file()` over Node's `fs` — faster and returns a `BunFile` with streaming support.

### Testing

```typescript
import { describe, expect, test } from "bun:test";

describe("math", () => {
  test("adds numbers", () => {
    expect(1 + 1).toBe(2);
  });
});
```

```bash
bun test              # run all tests
bun test --watch      # watch mode
bun test --coverage   # coverage report
```

- `bun:test` is Jest-compatible — same `describe`/`test`/`expect` API.
- Use `mock()` from `bun:test` for mocking.

### Bundling

```bash
bun build ./src/index.ts --outdir ./dist --target browser
bun build ./src/index.ts --outdir ./dist --target node
bun build ./src/index.ts --outfile ./app --compile  # single executable
```

- `--compile` produces a self-contained binary (no Node/Bun required to run).
- Use `--minify` for production builds.

### Environment Variables

```typescript
const dbUrl = process.env.DATABASE_URL;  // works
const secret = Bun.env.SECRET_KEY;       // Bun-specific, same result
```

- Bun loads `.env` automatically in development — no `dotenv` package needed.
- In production, set env vars via the process environment (not `.env` files).

### Node.js Compatibility

- Bun implements most Node.js built-ins (`fs`, `path`, `http`, `crypto`, etc.) natively.
- Check [bun.sh/docs/runtime/nodejs-apis](https://bun.sh/docs/runtime/nodejs-apis) for any gaps before assuming full compatibility.
- If a package uses native Node addons (`.node` files), it may not work — check Bun compatibility first.

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/typescript/coding-style.md`.
