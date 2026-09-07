# Finsor Development Setup

This document describes the current setup. Historical Firebase/Firestore instructions no longer apply to the current implementation.

## Prerequisites

Install the current stable Flutter SDK for your operating system, including the platform toolchains you need (Android Studio/Android SDK for Android, Xcode/CocoaPods on macOS for iOS).

Verify the environment:

```bash
flutter doctor
flutter --version
```

## Project setup

```bash
git clone https://github.com/Detherkasper12/Finsor-sep-26.git
cd Finsor-sep-26
flutter pub get
```

Create local environment files from the committed public template:

```bash
cp .env.example .env.dev
cp .env.example .env.prod
```

On Windows PowerShell, the equivalent is:

```powershell
Copy-Item .env.example .env.dev
Copy-Item .env.example .env.prod
```

For cloud features, set the following public client values:

```dotenv
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_PUBLIC_KEY
ENV_NAME=dev
GOOGLE_WEB_CLIENT_ID=
```

Use `ENV_NAME=prod` in `.env.prod`. The Flutter client may use a Supabase anon/public key; it must never contain a Supabase service-role key, OpenAI/provider secret, signing secret, or other privileged credential.

## Run locally

Development environment:

```bash
flutter run --dart-define=ENV=dev
```

Production configuration during a local build/test:

```bash
flutter run --dart-define=ENV=prod
```

If Supabase is not configured, supported core finance functionality should continue in offline mode.

## Quality checks

Before merging normal Flutter changes, run:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

For startup/navigation/auth/sync changes, also run the integration smoke test on an available target:

```bash
flutter test integration_test/app_test.dart -d <device_id>
```

## Supabase development

The repository stores database migrations under `supabase/migrations/` and Edge Functions under `supabase/functions/`. Treat migrations as the source of truth for schema/RLS changes. Review per-user RLS and sync compatibility before applying schema changes.

Use separate development and production Supabase projects/configuration. Prefer development access for agent/MCP tooling; keep production access read-only unless a production write is intentionally required and reviewed.

## Authentication status

Authentication and Google Sign-In are currently feature-gated in `lib/config/app_config.dart`. Do not assume those flows are active merely because the implementation exists. Re-enable them only as an intentional product/release change with platform OAuth configuration and tests.

## Troubleshooting

If packages/build state becomes inconsistent:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

For Android SDK problems, use `flutter doctor` and Android Studio's SDK Manager. For iOS platform problems, use `flutter doctor`, Xcode, and CocoaPods on macOS. Do not commit `local.properties`, IDE caches, generated coverage, local test output, `.env.*`, or Supabase CLI temporary state.

## AI/provider secrets

AI-provider keys belong behind server-side infrastructure such as Supabase Edge Functions. Never add a raw provider secret to Dart source, Flutter assets, `.env.dev`, or `.env.prod`.

For project architecture and agent instructions, read `AGENTS.md` first.
