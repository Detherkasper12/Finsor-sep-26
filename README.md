# Finsor

Finsor is a cross-platform personal finance application built with Flutter. The product focuses on fast daily money tracking, wallets/accounts, transactions, budgets, analytics, goals, recurring transactions, privacy-aware AI assistance, and optional cloud synchronization.

> Status: active development. This repository is **not** represented as production-ready until release gates, platform builds, store configuration, security review, and CI are verified.

## Architecture at a glance

- **Flutter / Dart** — client application.
- **Riverpod** — state management and dependency wiring.
- **Hive** — local-first persistence for core finance data.
- **Repositories and services** — finance logic, persistence, sync, auth, AI, export, premium and integrations.
- **Supabase** — optional cloud sync, authentication, realtime, PostgreSQL migrations/RLS and Edge Functions.
- **Sentry** — observability.
- **in_app_purchase** — current premium purchase integration.

Core finance tracking is designed to remain useful offline. Supabase extends the local experience rather than replacing local persistence.

## Getting started

Install a current stable Flutter SDK and verify it with:

```bash
flutter doctor
```

Clone the repository and create local public environment files:

```bash
git clone https://github.com/Detherkasper12/Finsor-sep-26.git
cd Finsor-sep-26
cp .env.example .env.dev
cp .env.example .env.prod
```

Fill `.env.dev` / `.env.prod` with the public Supabase project URL and **anon/public** key when cloud features are needed. Never put a Supabase service-role key or an AI-provider secret in the Flutter client.

Then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=ENV=dev
```

Without valid Supabase configuration, the application is expected to degrade to offline mode for supported core functionality.

## Repository guidance

`AGENTS.md` is the canonical guide for coding agents and engineering invariants. Current code and Supabase migrations take precedence over historical plans or completion reports. Canonical engineering documentation lives under `docs/`.

Important locations:

```text
lib/                  Flutter application code
test/                 unit and widget tests
integration_test/     device/browser integration smoke tests
supabase/migrations/  database schema, RLS and migrations
supabase/functions/   server-side Edge Functions
.cursor/rules/         Cursor project instructions
.github/workflows/     CI workflows
```

## Development principles

Keep changes small and reviewable. Preserve offline-first behavior and financial data integrity. Do not weaken RLS to work around client bugs. Required screens and flows must fail tests when missing rather than being silently skipped. Update canonical documentation when architecture, environment setup, schema, sync, or product behavior changes.

## Current development note

The repository contains historical sprint/planning documents created during earlier development. They can provide context, but they are not authoritative when they conflict with current code, `AGENTS.md`, or canonical docs.
