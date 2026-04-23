---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# TypeScript Coding Style

## Type System

- Enable `"strict": true` in `tsconfig.json` — no exceptions.
- No `any` — use `unknown` for untrusted input and narrow with type guards.
- Avoid `as` casts unless unavoidable — document why when used.
- `interface` for extensible object shapes; `type` for unions, intersections, and mapped types.
- No `enum` — use `as const` objects or string literal unions instead.
- Avoid `React.FC` — use named prop types on function components.

```typescript
// BAD
function process(data: any) { return data.value; }

// GOOD — narrow unknown input
function process(data: unknown): string {
    if (typeof data === "object" && data !== null && "value" in data) {
        return String((data as { value: unknown }).value);
    }
    throw new Error("Invalid data shape");
}

// BAD — enum
enum Direction { Up, Down }

// GOOD — as const
const Direction = { Up: "UP", Down: "DOWN" } as const;
type Direction = (typeof Direction)[keyof typeof Direction];

// GOOD — interface for extensible shape
interface User { id: string; name: string; }
interface AdminUser extends User { permissions: string[]; }

// GOOD — type for union
type Status = "active" | "inactive" | "pending";
```

## Nullability

- Prefer `undefined` over `null` for optional values in new code.
- Use optional chaining `?.` and nullish coalescing `??` rather than explicit null checks.
- Non-null assertions `!` should be rare and commented.

```typescript
// BAD
if (user !== null && user !== undefined && user.profile !== null) {
    return user.profile.avatar;
}

// GOOD
return user?.profile?.avatar ?? "/default-avatar.png";

// Non-null assertion — only when you've already verified externally
// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
const el = document.getElementById("root")!; // always present in index.html
```

## Immutability

- `const` by default; `let` only when reassignment is genuinely needed.
- Spread operator for object/array updates — no direct mutation.
- `Readonly<T>` and `ReadonlyArray<T>` on function parameters that must not be mutated.

```typescript
// BAD — mutation
function addItem(cart: CartItem[], item: CartItem) {
    cart.push(item); // mutates caller's array
    return cart;
}

// GOOD — immutable update
function addItem(cart: ReadonlyArray<CartItem>, item: CartItem): CartItem[] {
    return [...cart, item];
}

// BAD — reassignment unnecessary
let config = loadConfig();

// GOOD
const config = loadConfig();
```

## Error Handling

- `async/await` with `try/catch` — no `.then().catch()` chains in new code.
- Narrow unknown errors before accessing properties.
- No empty catch blocks.

```typescript
// BAD
fetch(url).then(r => r.json()).catch(console.error);

// GOOD
async function fetchData(url: string): Promise<Data> {
    try {
        const res = await fetch(url);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json() as Promise<Data>;
    } catch (err) {
        if (err instanceof Error) {
            logger.error("fetch failed", { url, message: err.message });
        }
        throw err;
    }
}
```

## Imports

- Absolute imports over relative where the project supports it.
- Group imports: external packages, internal modules, types.
- No unused imports (enforced by `@typescript-eslint/no-unused-vars`).

```typescript
// GOOD — grouped and ordered
import { z } from "zod";
import { useState } from "react";

import { UserService } from "@/services/user";
import { formatDate } from "@/utils/date";

import type { User, UserRole } from "@/types";
```

## Logging

- No `console.log` in production code — use the project's logger.
- No `console.error` left in production — handle errors properly.

## Validation

- Use Zod (or equivalent) for runtime validation of external data.
- Infer TypeScript types from Zod schemas — do not duplicate type definitions.

```typescript
import { z } from "zod";

const UserSchema = z.object({
    id: z.string().uuid(),
    email: z.string().email(),
    role: z.enum(["admin", "editor", "viewer"]),
});

// Infer — no duplicate type definition
type User = z.infer<typeof UserSchema>;

// Parse at boundary (throws on invalid)
const user = UserSchema.parse(req.body);

// Safe parse (returns success/error)
const result = UserSchema.safeParse(req.body);
if (!result.success) {
    return res.status(400).json({ errors: result.error.flatten() });
}
```

## Tooling Config

```json
// tsconfig.json — minimum required settings
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true
  }
}
```

```bash
# Type-check only (no emit)
npx tsc --noEmit

# Lint
npx eslint src/ --ext .ts,.tsx

# Format
npx prettier --write src/
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `any` everywhere | `unknown` + type guards |
| `as Type` cast without comment | Zod parse or type guard |
| `enum` | `as const` + derived type |
| `.then().catch()` chains | `async/await` with `try/catch` |
| `console.log` in production | Project logger |
| Duplicate type + Zod schema | Infer from schema |
| Direct object mutation | Spread operator |
