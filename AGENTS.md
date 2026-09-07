# Finsor Agent Guide

This file is the primary source of truth for AI coding agents working in this repository. When documentation conflicts with the current implementation, inspect the code and update the canonical docs rather than preserving stale assumptions.

## Product

Finsor is a cross-platform personal finance application focused on fast daily tracking, wallets/accounts, transactions, budgets, analytics, goals, recurring transactions, privacy-first AI assistance, and optional cloud sync. The UI direction is clean, modern, low-friction, and inspired by 1Money without copying it.

## Current Technical Architecture

- Flutter/Dart client.
- Riverpod for application state and dependency wiring.
- Hive as the local-first persistence layer and source for offline core functionality.
- Repository/service layers for finance logic, persistence, sync, auth, AI, export, premium, and related integrations.
- Supabase for authentication, optional cloud synchronization, realtime, PostgreSQL migrations/RLS, and Edge Functions.
- Sentry for observability.
- `in_app_purchase` for the current premium purchase integration.
- Environment configuration is loaded through `lib/config/env.dart`; only public client configuration belongs in Flutter assets.

Do not introduce BLoC, GetIt, Redux, another state-management framework, or a repository-wide architecture rewrite unless the task explicitly calls for an approved migration.

## Source-of-Truth Order

1. Current executable code and database migrations.
2. This `AGENTS.md` file.
3. Canonical documentation under `docs/`.
4. Current tests.
5. Historical plans, sprint reports, completion reports, and legacy root documents are context only and may be stale.

## Non-Negotiable Invariants

Core finance tracking must remain usable offline. Changes to transactions, wallets, balances, budgets, goals, recurring transactions, and sync must preserve data integrity and existing user data unless a migration is explicitly part of the task. Supabase access must continue to respect per-user RLS. Never place service-role keys, OpenAI/provider secrets, or other privileged credentials in the Flutter application. Financial values shown by AI must come from bound application data or deterministic calculations, not invented values.

Preserve localization, RTL support, currency behavior, accessibility, platform support, and graceful offline/error states. Prefer small, reviewable changes and feature-local refactors. Avoid opportunistic mass renames or folder migrations in unrelated tasks.

## Working Method

Before editing, trace the relevant UI -> provider -> repository/service -> persistence/integration path. Reuse existing abstractions when they are sound. If legacy code appears unused, verify references before deleting it. When architecture, environment setup, schema, sync rules, or product behavior changes, update the canonical documentation in the same change.

## Quality Gates

For normal Dart/Flutter changes, the expected baseline is:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Run targeted integration tests when navigation, startup, auth, persistence, sync, or critical user flows change. A test must fail when a required screen/control is missing; do not silently skip required assertions.

For Supabase changes, review the SQL migration, RLS impact, backward compatibility, and sync behavior. Never weaken production RLS merely to make a client operation pass.

## Repository Hygiene

Do not commit local SDK paths, generated coverage/output, Supabase temporary state, IDE caches, secret environment files, or temporary test databases/directories. Keep commits scoped and give reviewers enough context to understand behavior and risk.
