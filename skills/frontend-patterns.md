# Skill: Frontend Patterns

## Trigger

Use when building React or Next.js applications: designing component architecture, managing state, handling data fetching, or applying performance patterns.

## Component Architecture

### Component Classification

```
UI components (dumb)         ← pure rendering, no data fetching, no state
  └─ atoms: Button, Input, Badge
  └─ molecules: FormField, Card, Modal
  └─ organisms: NavigationBar, DataTable, Sidebar

Feature components (smart)   ← own state, fetch data, use hooks
  └─ UserProfileCard
  └─ OrdersTable
  └─ CheckoutForm

Page components              ← one per route, compose feature components
  └─ /dashboard → DashboardPage
  └─ /orders/:id → OrderDetailPage
```

### Component Rules

- Keep components under 100 lines — split if they grow larger.
- Props should be minimal — if you're passing more than 5 props, consider splitting the component or using composition.
- Avoid prop drilling beyond 2 levels — use context or a state manager.
- Co-locate test files: `Button.tsx` and `Button.test.tsx` in the same directory.

### Composition over Configuration

```tsx
// BAD — mega-component with many boolean flags
<Modal
    showHeader={true}
    showFooter={true}
    showCloseButton={true}
    footerContent={<Button>Save</Button>}
    headerContent={<h2>Edit User</h2>}
/>

// GOOD — composable parts
<Modal>
    <Modal.Header>Edit User</Modal.Header>
    <Modal.Body>...</Modal.Body>
    <Modal.Footer>
        <Button>Save</Button>
    </Modal.Footer>
</Modal>
```

## State Management

### State Location Hierarchy

```
1. URL params/search       ← shareable state (filters, selected tab, page)
2. useState               ← local UI state (open/closed, hover, form value)
3. useReducer             ← complex local state with multiple sub-values
4. Context               ← state shared across a subtree (theme, auth user)
5. Server state cache     ← remote data (React Query, SWR)
6. Global store           ← complex cross-cutting state (Zustand, Redux)
```

Use the simplest option that works. Don't reach for a global store until you've exhausted context.

### Server State with React Query

```typescript
// Fetching
const { data: user, isLoading, error } = useQuery({
    queryKey: ['users', userId],
    queryFn: () => api.users.get(userId),
    staleTime: 5 * 60 * 1000,   // 5 minutes before refetch
});

// Mutations with cache invalidation
const { mutate: updateUser } = useMutation({
    mutationFn: (data) => api.users.update(userId, data),
    onSuccess: () => {
        queryClient.invalidateQueries({ queryKey: ['users', userId] });
    },
});
```

- Don't store server data in `useState` — React Query handles caching, loading, error, and refetch.
- Use `queryKey` arrays for granular cache invalidation.

## Data Fetching in Next.js

```typescript
// App Router — Server Component (preferred for initial data)
// No loading state management — server renders complete
async function UserProfile({ userId }: { userId: string }) {
    const user = await db.users.findUnique({ where: { id: userId } });
    if (!user) notFound();
    return <UserCard user={user} />;
}

// Client Component — for interactive or user-specific data
'use client';
function UserActivity({ userId }: { userId: string }) {
    const { data } = useQuery(['activity', userId], () => fetchActivity(userId));
    // ...
}
```

- Default to Server Components for data fetching in Next.js App Router.
- Use Client Components only for interactivity (onClick, useState, browser APIs).
- Stream slow data with React `Suspense` and Next.js `loading.tsx`.

## Performance Patterns

### Code Splitting

```typescript
// Dynamic import for heavy components
const Chart = dynamic(() => import('./Chart'), {
    loading: () => <ChartSkeleton />,
    ssr: false,  // if Chart uses window/browser APIs
});
```

### Memoization

```typescript
// useMemo — expensive computation
const sortedItems = useMemo(
    () => items.slice().sort(compareByDate),
    [items]  // only recompute when items changes
);

// useCallback — stable function reference for child props
const handleSubmit = useCallback(
    async (data: FormData) => { await save(data); },
    [save]   // recreate only when save changes
);

// React.memo — skip re-render when props unchanged
const ExpensiveTable = React.memo(function ExpensiveTable({ rows }) {
    return <table>...</table>;
});
```

Don't over-memoize — add `useMemo`/`useCallback` only when profiling shows a real issue.

### Image and Font Optimization

```tsx
// Next.js Image — automatic sizing, WebP, lazy loading
import Image from 'next/image';
<Image src="/hero.jpg" alt="Hero" width={1200} height={600} priority />

// Next.js Font — no layout shift, no external request
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'] });
```

## Forms

```typescript
// React Hook Form — minimal re-renders, schema validation
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const schema = z.object({
    email: z.string().email(),
    password: z.string().min(8),
});

function LoginForm() {
    const { register, handleSubmit, formState: { errors } } = useForm({
        resolver: zodResolver(schema),
    });

    return (
        <form onSubmit={handleSubmit(onSubmit)}>
            <input {...register('email')} />
            {errors.email && <span>{errors.email.message}</span>}
        </form>
    );
}
```

## Constraints

- Never import all of lodash — use native methods or targeted imports.
- Never use `any` in TypeScript without justification.
- Accessibility is not optional — use semantic HTML and ARIA attributes. Every interactive element must be keyboard-reachable.
