# Skill: PM2 Patterns

## Trigger

Use when managing Node.js multi-service applications with PM2: setting up process management, configuring cluster mode, managing logs, handling zero-downtime deployments, or debugging PM2-related issues.

## Core Concepts

- **PM2** is a production process manager for Node.js — it keeps processes alive, handles restarts, and manages logs.
- **Ecosystem file** (`ecosystem.config.js` or `.cjs`) is the source of truth for all app configs — always use it, never raw `pm2 start` commands in production.
- **Cluster mode** forks the app across CPU cores — use for stateless HTTP servers to maximize throughput.
- **Fork mode** (default) runs a single process — use for workers, cron jobs, or stateful services.

## Ecosystem File Pattern

```js
// ecosystem.config.cjs
module.exports = {
    apps: [
        {
            name: 'api-server',
            script: './dist/server.js',
            instances: 'max',          // or a number; 'max' = number of CPUs
            exec_mode: 'cluster',
            watch: false,              // never watch in production
            max_memory_restart: '500M',
            env: {
                NODE_ENV: 'development',
                PORT: 3000,
            },
            env_production: {
                NODE_ENV: 'production',
                PORT: 3000,
            },
            error_file: './logs/api-error.log',
            out_file: './logs/api-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
            merge_logs: true,          // merge cluster instance logs into one file
        },
        {
            name: 'worker',
            script: './dist/worker.js',
            instances: 1,
            exec_mode: 'fork',         // workers are typically stateful
            cron_restart: '0 3 * * *', // optional: restart nightly at 3 AM
            env_production: {
                NODE_ENV: 'production',
            },
        },
    ],
};
```

## Key Commands

```bash
# Start all apps from ecosystem file
pm2 start ecosystem.config.cjs --env production

# Reload (zero-downtime for cluster mode)
pm2 reload ecosystem.config.cjs --env production

# Restart (brief downtime — use reload for cluster)
pm2 restart ecosystem.config.cjs

# Stop and delete from PM2 registry
pm2 delete ecosystem.config.cjs

# Status overview
pm2 status

# Real-time logs (all apps)
pm2 logs

# Real-time logs (specific app)
pm2 logs api-server --lines 100

# Save current PM2 process list (for startup auto-recovery)
pm2 save

# Generate startup script (run once per server)
pm2 startup
```

## Zero-Downtime Deployment Pattern

```bash
# 1. Pull new code
git pull origin main

# 2. Install dependencies (if changed)
npm ci --omit=dev

# 3. Build
npm run build

# 4. Reload in-place (cluster mode — no downtime)
pm2 reload ecosystem.config.cjs --env production

# 5. Verify
pm2 status
pm2 logs api-server --lines 20 --nostream
```

- `pm2 reload` sends `SIGINT` to old workers one at a time, waits for new workers to be ready, then terminates old ones.
- Requires cluster mode (`exec_mode: 'cluster'`). Fork mode has brief downtime on reload.

## Log Management

- Set `error_file` and `out_file` in the ecosystem file — never rely on default paths.
- Rotate logs with `pm2-logrotate` module:

```bash
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7
pm2 set pm2-logrotate:compress true
```

- Do not let logs grow unbounded in production — they will fill disk.

## Common Issues

| Symptom | Cause | Fix |
|---|---|---|
| Process keeps restarting | Crash on startup | `pm2 logs <name>` to read error |
| `EADDRINUSE` in cluster mode | Port binding conflict | Ensure `server.listen` doesn't bind before cluster fork |
| Memory leak / growing RAM | Application leak | Set `max_memory_restart` to trigger auto-restart |
| Old code running after deploy | Reload didn't pick up new build | Verify build output path matches `script` in ecosystem |
| Logs missing after rotation | `merge_logs: false` + multiple instances | Set `merge_logs: true` |

## Constraints

- Never use `pm2 start app.js` with inline flags in production — use the ecosystem file for reproducibility.
- Never disable `watch: false` in production — file watching causes unnecessary restarts and CPU overhead.
- Always run `pm2 save` after config changes so the process list survives server reboots.
