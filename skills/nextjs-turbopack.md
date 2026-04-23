# Skill: nextjs-turbopack

## Purpose

Apply Next.js App Router and Turbopack patterns — file-based routing, Server Components, data fetching, caching, and build optimization.

## Trigger

- Starting or reviewing a Next.js 14+ project with App Router
- Asked about Server Components, Client Components, or `use cache`
- Migrating from Pages Router to App Router
- Diagnosing slow builds and switching to Turbopack

## Trigger

`/nextjs-turbopack` or `apply nextjs patterns to [target]`

## Agents

- `typescript-reviewer` — TypeScript quality
- `performance-optimizer` — bundle and render performance

## Patterns

### App Router Structure

```
app/
├── layout.tsx          # Root layout (Server Component)
├── page.tsx            # Home page
├── loading.tsx         # Suspense boundary fallback
├── error.tsx           # Error boundary (Client Component)
├── (auth)/             # Route group (no URL segment)
│   ├── login/page.tsx
│   └── register/page.tsx
└── api/
    └── orders/route.ts # API route handler
```

### Server vs Client Components

```tsx
// Server Component (default) — runs on server, no interactivity
export default async function OrderList() {
  const orders = await db.query.orders.findMany();  // direct DB access OK
  return <ul>{orders.map(o => <li key={o.id}>{o.name}</li>)}</ul>;
}

// Client Component — add "use client" directive
"use client";
export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

- Default is Server Component. Add `"use client"` only when you need hooks, event handlers, or browser APIs.
- Push `"use client"` as far down the tree as possible — keep most of the app as Server Components.

### Data Fetching and Caching

```tsx
// Next.js 15 — fetch is no longer cached by default
const data = await fetch("/api/data", { cache: "force-cache" });  // opt-in cache

// Use cache() for deduplication across a request
import { cache } from "react";
const getUser = cache(async (id: string) => db.users.findById(id));

// next/cache for revalidation
import { revalidatePath, revalidateTag } from "next/cache";
revalidatePath("/orders");
```

### API Routes

```typescript
// app/api/orders/route.ts
import { NextRequest, NextResponse } from "next/server";

export async function POST(req: NextRequest) {
  const body = await req.json();
  // validate body...
  return NextResponse.json({ id: "123" }, { status: 201 });
}
```

### Turbopack Dev Server

```bash
# Enable Turbopack (stable in Next.js 15)
next dev --turbopack

# package.json
"scripts": {
  "dev": "next dev --turbopack"
}
```

- Turbopack is opt-in for `dev`. The production build (`next build`) still uses Webpack/SWC by default in Next.js 15.
- Turbopack does not support all Webpack plugins — check before migrating.

### Environment Variables

- `NEXT_PUBLIC_*` — exposed to the browser bundle.
- Non-prefixed — server-only (never sent to browser).
- Never put secrets in `NEXT_PUBLIC_*` variables.

### Image and Font Optimization

```tsx
import Image from "next/image";
import { Inter } from "next/font/google";

const inter = Inter({ subsets: ["latin"] });  // self-hosted, no layout shift

<Image src="/hero.jpg" alt="Hero" width={1200} height={600} priority />
```

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/typescript/coding-style.md` and `rules/typescript/security.md`.
