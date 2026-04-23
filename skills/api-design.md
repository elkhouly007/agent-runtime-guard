# Skill: API Design

## Trigger

Use when designing a new REST API, reviewing an existing API for consistency and correctness, or defining contracts between services.

## Process

### New API Design

1. Define the resource model first: what are the domain entities, and what relationships exist between them?
2. Map CRUD operations to HTTP methods:
   - `GET /resources` — list (with pagination)
   - `POST /resources` — create
   - `GET /resources/:id` — read one
   - `PUT /resources/:id` — full replace
   - `PATCH /resources/:id` — partial update
   - `DELETE /resources/:id` — delete
3. Define the request/response shapes — use JSON Schema or TypeScript types.
4. Define error responses — consistent error envelope across all endpoints.
5. Define authentication and authorization model (who can do what).
6. Version the API from day one — even if v1 is the only version.

### URL Design Rules

```
# Resources are nouns, plural
GET /users
GET /users/:id
GET /users/:id/orders      ← nested resource (max 2 levels)

# Actions that don't map cleanly to CRUD
POST /users/:id/activate   ← use action noun as sub-resource
POST /payments/:id/refund

# Filters and search via query params
GET /users?role=admin&status=active
GET /orders?from=2024-01-01&to=2024-12-31

# Never verbs in the URL
GET /getUsers              ← BAD
POST /createUser           ← BAD
```

### Response Design

```json
// List response — always paginated
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 143,
    "next_cursor": "eyJpZCI6NTB9"
  }
}

// Single resource
{
  "data": {
    "id": "usr_abc123",
    "email": "user@example.com",
    "created_at": "2024-01-15T10:30:00Z"
  }
}

// Error envelope — consistent across ALL endpoints
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is invalid",
    "details": [
      { "field": "email", "message": "Must be a valid email address" }
    ]
  }
}
```

### HTTP Status Codes

| Code | When to use |
|---|---|
| 200 | Success (GET, PUT, PATCH) |
| 201 | Resource created (POST) |
| 204 | Success, no body (DELETE) |
| 400 | Bad request / validation error |
| 401 | Not authenticated |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict (duplicate, state mismatch) |
| 422 | Unprocessable entity (semantic error) |
| 429 | Rate limited |
| 500 | Server error |

### Versioning

- URL versioning: `/v1/users` — simple, widely supported, easy to route.
- Avoid header versioning for public APIs — it's invisible in browser URLs and hard to cache.
- Maintain backwards compatibility within a major version — additive changes are safe.
- Deprecation: add a `Sunset` header + `Deprecation` header 6+ months before removal.

### Pagination

- Prefer cursor-based pagination for large, frequently-updated datasets — page numbers go stale.
- Use offset-based pagination only for small, stable datasets where "page 3" is a user-visible concept.
- Always include `next_cursor` (or `next_page`) and `total` (if affordable) in the response.

### Authentication

- Stateless APIs: use JWTs in `Authorization: Bearer <token>` header.
- Admin/internal APIs: use API keys in `Authorization: Bearer <key>` or `X-API-Key` header.
- Never put tokens in URL query parameters — they end up in server logs.

## Output Format

- OpenAPI 3.0 spec (YAML) for the designed endpoints.
- Or: structured list of endpoints with method, path, request shape, response shape, status codes.
- Highlight any backwards-incompatible decisions that need stakeholder sign-off.

## Constraints

- Do not design APIs around implementation details — model the domain, not the database schema.
- Do not return HTTP 200 with an error body — use the correct status code.
