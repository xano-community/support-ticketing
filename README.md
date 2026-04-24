# Support Ticketing

An IT / customer-support ticketing app built on Xano. Backend is XanoScript you push to your own Xano instance; frontend is a single-file HTML app that asks for your instance's base URL the first time it loads.

Tickets have a subject, description, priority (`low` / `medium` / `high` / `urgent`), status (`open` / `in_progress` / `pending` / `resolved` / `closed`), a category, a requester, an optional assignee, and an auto-computed SLA due-date. Agents leave comments (optionally internal-only), and a dashboard endpoint surfaces counts by status plus overdue tickets.

## Repo layout

```
backend/            # XanoScript — push to your Xano workspace
  workspace/
  table/            # user, ticket, ticket_comment, ticket_category
  api/
    enterprise_auth/  # signup, login, me, users
    ticketing/        # tickets, categories, stats, seed
frontend/
  index.html        # single-file static app
```

## Quick start

### 1. Push the backend to your Xano instance

Install the [Xano CLI](https://www.npmjs.com/package/@xano/cli) and configure a profile, then push:

```bash
npm install -g @xano/cli
xano profile:wizard

cd backend
xano workspace:push
```

This creates 4 tables (`user`, `ticket`, `ticket_comment`, `ticket_category`), an `EnterpriseAuth` API group, and a `Ticketing` API group in your workspace.

### 2. Seed demo data

A seed endpoint populates 8 users, 6 categories, 20 tickets in varied states, and comments. Idempotent — safe to re-run.

```bash
curl -X POST https://YOUR-INSTANCE.n7d.xano.io/api:support-ticketing/seed \
  -d '{}' -H 'Content-Type: application/json'
```

All seeded users share password `DemoPass1`. Emails are `alice.johnson@acme.enterprise` … `henry.tanaka@acme.enterprise`.

### 3. Run the frontend

No build step — it's one HTML file. Serve it any way you like:

```bash
cd frontend
python3 -m http.server 8000
# open http://localhost:8000
```

On first load the page asks for your **Xano base URL** (e.g. `https://xxsw-1d5c-nopq.n7d.xano.io`). Paste it and save — it's stored in `localStorage`. Click "Reconfigure instance" on the login screen to change it later.

## API surface

All endpoints except `/seed` require `Authorization: Bearer <token>` from a successful login.

```
POST   /api:enterprise-auth/signup         { name, email, password }
POST   /api:enterprise-auth/login          { email, password }
GET    /api:enterprise-auth/me
GET    /api:enterprise-auth/users

POST   /api:support-ticketing/seed
GET    /api:support-ticketing/tickets           ?status&priority&category_id&assignee_id&page&per_page
POST   /api:support-ticketing/tickets
GET    /api:support-ticketing/tickets/{id}
PATCH  /api:support-ticketing/tickets/{id}
DELETE /api:support-ticketing/tickets/{id}
GET    /api:support-ticketing/tickets/{id}/comments
POST   /api:support-ticketing/tickets/{id}/comments
GET    /api:support-ticketing/categories
POST   /api:support-ticketing/categories
GET    /api:support-ticketing/stats/dashboard
```

## Schema

- **`user`** — id, name, email (unique), password, created_at — shared auth table with `auth = true`
- **`ticket`** — id, subject, description, status, priority, category_id → ticket_category, requester_id → user, assignee_id → user, sla_due_at, resolved_at, created_at, updated_at
- **`ticket_category`** — id, name (unique), description
- **`ticket_comment`** — id, ticket_id → ticket, author_id → user, body, is_internal

## Frontend features

- Stats dashboard (open / in-progress / resolved / urgent / overdue)
- Ticket table with filters on status, priority, and category
- Server-side pagination
- Create-ticket modal with live category and assignee dropdowns
- Ticket detail modal with inline status/priority editing and a comment thread
- Configurable Xano instance URL (no hardcoded endpoints)

## License

MIT.
