# Skill: Database Migrations

## Trigger

Use when creating, reviewing, or applying database schema changes in any stack (Prisma, Drizzle, Django, golang-migrate, or raw SQL).

## Pre-Migration Checklist

Before writing a migration:
- [ ] Confirm the migration is additive only (no destructive ops without expand-contract plan).
- [ ] Identify every table/column/index touched and its current production row count.
- [ ] Check whether the change requires application code to deploy before or after.
- [ ] Verify a rollback migration (down script) exists and is tested.
- [ ] Confirm the migration has been run against a staging copy of production data.

## Process

### 1. Lifecycle: create → review → apply → rollback

```
create      write migration file, run linter / diff check
review      PR review: backward-compat, index coverage, lock risk
staging     apply on staging with real-scale data, measure lock time
production  apply with monitoring — one migration per deploy
rollback    know the exact rollback command before you apply
```

### 2. Naming Conventions

| Tool | Convention | Example |
|------|-----------|---------|
| Prisma | auto-timestamp + description | `20240315120000_add_user_timezone` |
| Drizzle | sequential + description | `0012_add_user_timezone.sql` |
| Django | sequential + auto-description | `0024_user_timezone` |
| golang-migrate | timestamp + verb_noun | `20240315120000_add_user_timezone.up.sql` |

Never use generic names like `fix`, `update`, or `misc`. Name must describe the schema change.

### 3. Backward-Compatible Migrations (Additive Only)

**Safe operations (deploy any time):**
- Adding a nullable column
- Adding a new table
- Adding an index (use `CONCURRENTLY` in Postgres)
- Adding a foreign key after data is populated
- Widening a varchar (e.g., 100 → 255)

**Unsafe — requires expand-contract (see section below):**
- Renaming a column or table
- Changing a column type
- Adding NOT NULL to an existing column
- Dropping a column or table
- Narrowing a varchar

### 4. Dangerous Operations Checklist

Before performing any of the following, get explicit sign-off:

| Operation | Risk | Mitigation |
|-----------|------|-----------|
| Column rename | App reads old name → 500s | Expand-contract: add new, dual-write, migrate, drop old |
| Type change (e.g., int → bigint) | Lock whole table | Add new column, backfill, swap, drop |
| NOT NULL on existing column | Fails if any row is NULL | Backfill first, then add constraint |
| DROP COLUMN / TABLE | Irreversible data loss | Soft-delete first (rename with `_deprecated_`), drop in later release |
| Adding FK without index | Lock + slow writes | Index FK column before adding constraint |
| Large backfill in single transaction | Table lock for minutes | Batch update in chunks of 1 000–10 000 rows |

### 5. Expand-Contract Pattern (Zero-Downtime)

Use for any rename or type change:

```
Phase 1 — Expand   (deploy with old app running)
  - Add new column alongside old column
  - Write to both columns in application code

Phase 2 — Backfill  (run as background job, not in migration)
  UPDATE users SET username_new = username_old WHERE username_new IS NULL LIMIT 10000;
  -- repeat in batches until complete

Phase 3 — Contract  (deploy after backfill is 100% done)
  - Switch reads to new column
  - Stop writing to old column

Phase 4 — Cleanup   (separate deploy, one week later)
  - Drop old column
```

### 6. Tool-Specific Examples

#### Prisma

```bash
# Create a migration
npx prisma migrate dev --name add_user_timezone

# Preview SQL without applying
npx prisma migrate dev --create-only --name add_user_timezone

# Apply in production (no dev prompts)
npx prisma migrate deploy

# Rollback: Prisma has no built-in rollback.
# Write a manual migration that reverses the change.
```

```prisma
// schema.prisma — safe additive change
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  timezone  String?  // nullable — safe to add any time
  createdAt DateTime @default(now())
}
```

```sql
-- Generated SQL Prisma produces — always review before applying
ALTER TABLE "User" ADD COLUMN "timezone" TEXT;
```

#### Drizzle

```typescript
// drizzle/schema.ts — adding a nullable column
import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id:        uuid('id').primaryKey().defaultRandom(),
  email:     text('email').notNull().unique(),
  timezone:  text('timezone'),            // nullable — safe
  createdAt: timestamp('created_at').defaultNow().notNull(),
});
```

```bash
# Generate migration file
npx drizzle-kit generate:pg

# Apply pending migrations
npx drizzle-kit push:pg           # dev only
# In production: use drizzle-orm/migrator in your deploy script

# Inspect what SQL will run
npx drizzle-kit up:pg --dry-run
```

```typescript
// Production migration runner
import { drizzle } from 'drizzle-orm/postgres-js';
import { migrate } from 'drizzle-orm/postgres-js/migrator';
import postgres from 'postgres';

const client = postgres(process.env.DATABASE_URL!);
const db = drizzle(client);

await migrate(db, { migrationsFolder: './drizzle' });
await client.end();
```

#### Django

```python
# models.py — safe additive change
class User(models.Model):
    email    = models.EmailField(unique=True)
    timezone = models.CharField(max_length=64, null=True, blank=True)  # nullable
    created_at = models.DateTimeField(auto_now_add=True)
```

```bash
# Create migration
python manage.py makemigrations --name add_user_timezone

# Preview SQL
python manage.py sqlmigrate myapp 0024

# Apply
python manage.py migrate

# Rollback to previous migration
python manage.py migrate myapp 0023
```

```python
# migrations/0024_add_user_timezone.py
from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [('myapp', '0023_previous_migration')]

    operations = [
        migrations.AddField(
            model_name='user',
            name='timezone',
            field=models.CharField(max_length=64, null=True, blank=True),
        ),
    ]
```

#### golang-migrate

```bash
# Install
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Create migration pair (.up.sql and .down.sql)
migrate create -ext sql -dir db/migrations -seq add_user_timezone

# Apply all pending
migrate -path db/migrations -database "$DATABASE_URL" up

# Apply exactly N steps
migrate -path db/migrations -database "$DATABASE_URL" up 1

# Rollback 1 step
migrate -path db/migrations -database "$DATABASE_URL" down 1

# Check version
migrate -path db/migrations -database "$DATABASE_URL" version
```

```sql
-- db/migrations/000012_add_user_timezone.up.sql
ALTER TABLE users ADD COLUMN timezone TEXT;
CREATE INDEX CONCURRENTLY idx_users_timezone ON users(timezone);

-- db/migrations/000012_add_user_timezone.down.sql
DROP INDEX CONCURRENTLY IF EXISTS idx_users_timezone;
ALTER TABLE users DROP COLUMN IF EXISTS timezone;
```

### 7. Index Creation (Zero-Downtime in Postgres)

```sql
-- WRONG: locks the table for the duration of the build
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- CORRECT: concurrent build, no table lock
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- Verify index is VALID (not INVALID) after creation
SELECT indexname, indisvalid
FROM pg_indexes
JOIN pg_index ON pg_indexes.indexname::text = pg_class.relname
WHERE tablename = 'orders';
```

Never create indexes inside a transaction — `CONCURRENTLY` cannot run inside a transaction block.

### 8. Migration Testing

```bash
# Always test the rollback, not just the apply
migrate up 1    # apply
# run smoke tests against staging
migrate down 1  # rollback
# verify data integrity

# Measure lock time on large tables
psql $STAGING_URL -c "
  SET lock_timeout = '3s';
  ALTER TABLE big_table ADD COLUMN flag BOOLEAN;
"
# If it times out, use expand-contract instead of inline ALTER
```

### 9. Rollback Plan Requirement

Every migration PR must include a rollback plan in the PR description:

```
## Migration Rollback Plan
- Migration: 0024_add_user_timezone
- Rollback command: `migrate down 1` (golang-migrate)
  OR `python manage.py migrate myapp 0023` (Django)
  OR manual SQL: `ALTER TABLE users DROP COLUMN timezone;`
- Data loss on rollback: NONE (column is nullable, no data written yet)
- Estimated rollback time: < 1 second (no index to drop)
- Who approves rollback: Ahmed
```

## Anti-Patterns

- **Never use `migrate up` on production without first running on staging** — production data volume reveals lock problems staging hides.
- **Never add NOT NULL without a DEFAULT or backfill** — any existing row causes the migration to fail mid-flight.
- **Never drop a column the current application version still reads** — deploy the app change first, then drop.
- **Never put data migrations inside schema migrations** — keep DDL and DML separate.
- **Never rename a table/column in one step** — use expand-contract across multiple deploys.
- **Never run migrations inside a deploy with zero downtime target without testing lock time first.**

## Safe Behavior

- Read-only analysis unless Ahmed explicitly confirms apply.
- Flags any migration that is not backward-compatible.
- Flags missing rollback plan in PR.
- CRITICAL findings (data loss, lock risk on large table) require Ahmed's approval before merge.
- Does not execute `migrate deploy` or `python manage.py migrate` on production autonomously.
