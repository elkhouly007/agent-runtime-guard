# Web Architecture Patterns

Patterns for scalable, maintainable web applications.

## Component Composition

Prefer composition over configuration:

```tsx
// Composable: caller controls structure
<Card>
  <CardHeader>Title</CardHeader>
  <CardBody>Content</CardBody>
  <CardFooter><Button>Action</Button></CardFooter>
</Card>

// Monolithic: limited flexibility
<Card title="Title" content="Content" actionLabel="Action" />
```

## Custom Hooks (React)

Extract stateful logic into hooks:

```tsx
function useUserProfile(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchUser(userId)
      .then(setUser)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [userId]);

  return { user, loading, error };
}
```

## Server-Side Rendering Patterns

- Static Generation for content that changes infrequently (docs, marketing).
- Server-Side Rendering for personalized or real-time content.
- ISR (Incremental Static Regeneration) for content that changes on a schedule.
- Client-side data fetching only for user-specific, post-auth content.

## State Architecture

Divide state by scope:
- Server state: React Query / SWR — caching, revalidation, background sync
- URL state: query params — shareable, bookmarkable
- Local UI state: component `useState` — transient, ephemeral
- Global app state: Zustand/Jotai — only for truly cross-cutting concerns

## Error Boundaries

Wrap sections in error boundaries to isolate failures:

```tsx
<ErrorBoundary fallback={<SectionErrorState />}>
  <DataTable query={complexQuery} />
</ErrorBoundary>
```

## Route-Based Code Splitting

```tsx
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings  = lazy(() => import('./pages/Settings'));

<Suspense fallback={<PageSkeleton />}>
  <Routes>
    <Route path="/dashboard" element={<Dashboard />} />
    <Route path="/settings"  element={<Settings />} />
  </Routes>
</Suspense>
```
