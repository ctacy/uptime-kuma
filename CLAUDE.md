# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
- `npm run dev` - Run frontend + backend in development mode (concurrently)
- `npm run start-server-dev` - Start backend in dev mode (without frontend)
- `npm run start-frontend-dev` - Start frontend Vite dev server only
- `npm run build` - Build frontend for production
- `npm run start` - Start production server

### Linting & Formatting
- `npm run lint` - Run ESLint (JS/Vue) + Stylelint (CSS)
- `npm run lint-fix:js` - Fix ESLint issues
- `npm run lint-fix:style` - Fix Stylelint issues
- `npm run fmt` - Prettier format all files

### Testing
- `npm run test` - Run all tests (backend + e2e)
- `npm run test-backend` - Run backend unit tests
- `npm run test-backend-22` - Run backend tests with Node.js test runner
- `npm run test-e2e` - Run Playwright E2E tests
- `npm run test-e2e-ui` - Run Playwright E2E tests in UI mode
- `npm run tsc` - TypeScript type check for backend

### Useful Utilities
- `npm run reset-password` - Reset a user password
- `npm run remove-2fa` - Remove 2FA from a user
- `npm run vite-preview-dist` - Preview production build locally

## Architecture Overview

Uptime Kuma is a self-hosted monitoring service.

### Tech Stack
- **Backend**: Node.js + Express
- **Frontend**: Vue 3 + Vite + Bootstrap 5
- **Database**: SQLite (default) / MySQL / MariaDB / PostgreSQL via knex + redbean-node ORM
- **Real-time**: Socket.io WebSocket for live dashboard updates

### Directory Structure

```
server/                # Backend
├── server.js          # Entry point (DO NOT import this circularly)
├── config.js          # Configuration
├── database.js        # Database connection/setup
├── model/             # Data models (monitor.js, heartbeat.js, etc.)
├── monitor-types/     # Different monitor type implementations
├── monitor-conditions/ # Condition checking logic
├── socket-handlers/   # WebSocket event handlers
├── routers/           # Express API routes
├── notification.js    # Notification core
├── notification-providers/ # 90+ notification providers
├── jobs/              # Background jobs
└── modules/           # Shared modules

src/                   # Frontend
├── components/        # Vue components
│   ├── notifications/ # Notification provider UIs
│   └── ...
├── pages/             # Page components
├── i18n/              # Internationalization
├── utils.js           # Utilities
└── main.js            # Frontend entry

test/
├── backend-test/      # Backend unit tests
└── ...                # Playwright E2E tests

db/                   # Database migrations and seeds
public/               # Static assets
config/               # Build configs (vite, playwright)
extra/                # Release/deployment utilities
docker/               # Dockerfiles
```

### Key Architecture Points

1. **WebSocket-first**: Most client-server communication happens via Socket.io instead of REST. Socket handlers are in `server/socket-handlers/`. Entry in `server/server.js`.

2. **Monitors**: Core monitoring logic. Each monitor type has its own implementation in `server/monitor-types/`. Base logic in `server/model/monitor.js`. Tick/interval scheduling in background jobs.

3. **Notifications**: 90+ notification providers. Backend providers in `server/notification-providers/`, frontend components in `src/components/notifications/`. See `server/notification.js` for core sending logic.

4. **Database**: Uses `redbean-node` as a simple ORM wrapper over knex. Migrations live in `db/migrations/`. Supports multiple databases.

5. **Entry Point Constraints**: `server/server.js` cannot be required by other modules due to circular dependency risks. Don't break this.

## Development Workflow

1. Install dependencies: `npm install`
2. Run dev: `npm run dev`
3. Access: http://localhost:3000
4. Backend API runs on http://localhost:3001

## Running Single Tests

```bash
# Backend test - run a single test file
node test/test-backend.mjs test/backend-test/monitor-http.test.js

# Or with Node test runner:
npx node --test test/backend-test/[filename].js

# E2E single test:
npx playwright test --config ./config/playwright.config.js [test-file]
```

## Code Style

- ESLint + Prettier + Stylelint configured
- Run `npm run lint-fix:js && npm run fmt` before committing
- Node.js >= 20.4.0 required
