# Web + ARG Hooks

Web development commands that may trigger ARG.

## Build and Bundler Operations

- `npm run build` or `vite build`: executes arbitrary build scripts and plugins
- `webpack --config custom.js`: runs a custom config file
- PostCSS and Babel plugins execute during build — can modify files or make network calls

## Package Management

- `npm install` / `yarn install` / `pnpm install`: executes lifecycle scripts (`preinstall`, `postinstall`)
- Lifecycle scripts in packages can run arbitrary code with full filesystem access
- `npm publish`: uploads package to the public registry

## Dev Server Operations

- `vite --host 0.0.0.0`: exposes dev server on all interfaces
- `next dev` or `nuxt dev`: starts a server with hot-reload
- Custom `--port` flags that conflict with other services

## Code Generation

- `npx` commands execute remote packages inline
- Framework generators (`ng generate`, `vue create`, `create-react-app`) write files
- OpenAPI codegen scripts overwrite existing source files

## Browser Automation

- Playwright or Puppeteer scripts that:
  - Clear cookies or localStorage
  - Perform authenticated actions (form submits, purchases)
  - Export or download user data

## Sensitive Web Assets

- `.env.local`, `.env.production` files with API keys
- `src/config/` files with backend URLs and service credentials
- Private keys for code signing or VAPID web push

ARG pays extra attention to `npx` with non-pinned packages and lifecycle scripts in freshly installed packages.
