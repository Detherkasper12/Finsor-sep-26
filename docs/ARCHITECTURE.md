# Finsor Architecture

This document describes the current implementation direction. The executable code and Supabase migrations remain authoritative when this document falls behind.

## System shape

Finsor is a Flutter application with a local-first data model. UI screens consume Riverpod providers. Providers expose state and wire repositories/services. Hive persists core finance data locally. Supabase is an optional cloud extension for authentication, synchronization, realtime updates, PostgreSQL storage, RLS, and Edge Functions.

```text
Flutter UI
   |
Riverpod providers
   |
Repositories / application services
   |
Hive local persistence  <->  SyncService  <->  Supabase
                                      |
                               Edge Functions
```

## Client layers

`lib/screens/` and `lib/widgets/` contain presentation code. `lib/providers/` contains Riverpod state and dependency wiring. `lib/repositories/` contains higher-level data queries/calculations used by presentation state. `lib/services/` contains persistence, synchronization, authentication, AI, export, premium and integration logic. `lib/models/` contains core application data models.

The current folder layout is horizontal. New work should avoid a repository-wide migration. Where a feature becomes hard to maintain, it may be moved toward feature-local organization incrementally as part of a scoped refactor with tests.

## Local-first invariant

Hive is the local persistence path used by current Riverpod database wiring. Core money tracking should not require an active Supabase connection. Cloud synchronization must tolerate offline operation, retries, conflicts and application restarts without corrupting local financial data.

## Supabase

Database migrations under `supabase/migrations/` are the schema/RLS source of truth. Client operations must respect per-user RLS. Edge Functions under `supabase/functions/` are the correct place for provider secrets and privileged server-side integrations.

Never add a service-role key or AI-provider secret to Flutter code or Flutter assets.

## State management

Riverpod is the current standard. Do not introduce BLoC/GetIt or a second global state-management/DI framework without an explicit architecture decision and migration plan.

## Startup

`lib/main.dart` initializes Flutter bindings, Hive/local services, recurring transactions, environment configuration, optional Supabase, platform UI configuration and observability before starting `FinsorApp`. `lib/app.dart` currently owns MaterialApp setup and several startup/auth/sync gates. This file is a future decomposition candidate, but should be refactored incrementally rather than rewritten wholesale.

## High-risk areas

Changes involving wallet balances, transaction edits/deletes/transfers, recurring generation, budgets, sync conflict handling, authentication, RLS, premium entitlements and AI financial data binding require focused tests. Financial values and AI context must be deterministic and traceable to user data.

## Legacy code

The repository has evolved through multiple architectures and may contain older services/documents that no longer participate in runtime paths. Do not delete them based on naming alone. Verify imports/references and tests first, then remove them in a dedicated cleanup change.
