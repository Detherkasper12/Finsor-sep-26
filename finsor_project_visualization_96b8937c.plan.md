---
name: Finsor Project Visualization
overview: Create 4 comprehensive Mermaid diagrams visualizing Finsor's roadmap from current state to public launch, based on the PRD.
todos:
  - id: diagram-a
    content: Roadmap flowchart showing phases to milestones to outputs
    status: completed
  - id: diagram-b
    content: Dependency graph showing workstream interconnections
    status: completed
  - id: diagram-c
    content: Sprint timeline with key deliverables per sprint
    status: completed
  - id: diagram-d
    content: Release pipeline with gates and criteria
    status: completed
isProject: false
---

# Finsor Project Visualization

Based on `FINSOR_PRD_COMPLETE.md` analysis, the project has significant foundation code in place (models, providers, screens, services) corresponding to mid-Phase 1. The diagrams below visualize the complete journey from current state to public launch.

**Done:** Full auth system (Sign in / Sign up tabs, Email+Password, Google, Verify email code screen, Forgot password, session persistence, AuthGate). See `docs/auth_supabase_email_templates.md` and `docs/IMPLEMENTATION_SUMMARY_AUTH.md`. **Sprint 19.1:** Auth + Sync critical fixes: AuthGate depends on session (no auto-login after logout), hard logout (SignOutScope.global + Google disconnect), Google account chooser, deep links (reset-password + auth callback), ResetPasswordScreen, sync start/stop on login/logout; see `docs/sprint19_1_auth_fix_summary.md` and `docs/auth_deeplink_setup.md`.

**Paused:** Sign-in temporarily off (`AppConfig.authEnabled = false`, `googleSignInEnabled = false`) while Google Sign-In is paused — app opens to MainScreen offline; flip both flags to `true` to restore.

## A) High-Level Roadmap Flowchart

```mermaid
flowchart TB
    subgraph CurrentState ["✅ Foundation — DONE"]
        CS1["✅ Flutter Project Setup"]
        CS2["✅ Core Models Defined"]
        CS3["✅ Basic UI Screens"]
        CS4["✅ Local Providers"]
        CS5["✅ Hive Database"]
    end

    subgraph Phase1 ["✅ Phase 1: MVP — DONE"]
        P1M1["✅ Auth Integration"]
        P1M2["✅ Hive Local Storage"]
        P1M3["✅ Transaction CRUD"]
        P1M4["✅ Wallet Management"]
        P1M5["✅ Category System"]
        P1M6["✅ Basic Budgets"]
        P1M7["✅ Monthly Analytics"]
        P1M8["✅ Internal Release"]
    end

    subgraph Phase2 ["🔶 Phase 2: Beta — IN PROGRESS"]
        P2M1["✅ Supabase Setup"]
        P2M2["✅ Cloud Sync Engine"]
        P2M3["✅ Offline-First Logic"]
        P2M4["✅ AI Categorization (S15)"]
        P2M5["✅ AI Chat Interface (S15.5 unified finance-aware flow)"]
        P2M6["⬜ Advanced Budgets"]
        P2M7["⬜ Full Analytics Suite"]
        P2M8["⬜ Beta Release - 500 Users"]
    end

    subgraph Phase3 ["⬜ Phase 3: Launch - Weeks 15-18"]
        P3M1["✅ Premium IAP Setup"]
        P3M2["⬜ Feature Gating"]
        P3M3["⬜ Store Assets Prep"]
        P3M4["⬜ Final QA Pass"]
        P3M5["⬜ Store Submission"]
        P3M6["⬜ Public Launch"]
    end

    subgraph PostLaunch ["⬜ Post-Launch P1 Features"]
        PL1[Bank Sync Integration]
        PL2[Home Screen Widgets]
        PL3[Receipt OCR]
        PL4[Family Shared Wallets]
    end

    CS1 --> P1M1
    CS2 --> P1M3
    CS3 --> P1M4
    CS4 --> P1M2
    CS5 --> P1M2

    P1M1 --> P1M3
    P1M2 --> P1M3
    P1M3 --> P1M4
    P1M4 --> P1M5
    P1M5 --> P1M6
    P1M6 --> P1M7
    P1M7 --> P1M8

    P1M8 --> P2M1
    P2M1 --> P2M2
    P2M2 --> P2M3
    P2M3 --> P2M4
    P2M4 --> P2M5
    P2M5 --> P2M6
    P2M6 --> P2M7
    P2M7 --> P2M8

    P2M8 --> P3M1
    P3M1 --> P3M2
    P3M2 --> P3M3
    P3M3 --> P3M4
    P3M4 --> P3M5
    P3M5 --> P3M6

    P3M6 --> PL1
    P3M6 --> PL2
    P3M6 --> PL3
    P3M6 --> PL4

    style CS1 fill:#00C853,color:#fff
    style CS2 fill:#00C853,color:#fff
    style CS3 fill:#00C853,color:#fff
    style CS4 fill:#00C853,color:#fff
    style CS5 fill:#00C853,color:#fff
    style P1M1 fill:#00C853,color:#fff
    style P1M2 fill:#00C853,color:#fff
    style P1M3 fill:#00C853,color:#fff
    style P1M4 fill:#00C853,color:#fff
    style P1M5 fill:#00C853,color:#fff
    style P1M6 fill:#00C853,color:#fff
    style P1M7 fill:#00C853,color:#fff
    style P1M8 fill:#00C853,color:#fff
    style P2M1 fill:#00C853,color:#fff
    style P2M2 fill:#00C853,color:#fff
    style P2M3 fill:#00C853,color:#fff
    style P2M4 fill:#FFD600,color:#000
    style P2M5 fill:#FFD600,color:#000
    style P2M6 fill:#FFD600,color:#000
    style P2M7 fill:#FFD600,color:#000
    style P2M8 fill:#FFD600,color:#000
    style P3M1 fill:#00C853,color:#fff
    style P3M2 fill:#E0E0E0,color:#333
    style P3M3 fill:#E0E0E0,color:#333
    style P3M4 fill:#E0E0E0,color:#333
    style P3M5 fill:#E0E0E0,color:#333
    style P3M6 fill:#E0E0E0,color:#333
    style PL1 fill:#E0E0E0,color:#333
    style PL2 fill:#E0E0E0,color:#333
    style PL3 fill:#E0E0E0,color:#333
    style PL4 fill:#E0E0E0,color:#333
```



## B) Detailed Dependency Graph

```mermaid
flowchart LR
    subgraph Mobile [Mobile - Flutter]
        UI_Dashboard[Dashboard Screen]
        UI_Transactions[Transaction Screens]
        UI_Analytics[Analytics Screens]
        UI_Budgets[Budget Screens]
        UI_AI[AI Chat Screen]
        UI_Settings[Settings Screen]
        UI_Onboarding[Onboarding Flow]
    end

    subgraph Data [Data Layer]
        MOD_Transaction[Transaction Model]
        MOD_Wallet[Wallet Model]
        MOD_Category[Category Model]
        MOD_Budget[Budget Model]
        DB_Hive["Hive Encrypted DB - CRITICAL"]
        SYNC_Queue[Sync Queue Manager]
        SYNC_Conflict[Conflict Resolver]
    end

    subgraph Backend [Backend - Supabase]
        AUTH_Supabase[Auth Service]
        DB_Postgres[PostgreSQL + RLS]
        EDGE_Functions[Edge Functions]
        STORAGE_Cloud[Cloud Storage]
    end

    subgraph AI [AI Workstream]
        AI_OnDevice[On-Device ML Model]
        AI_Categorization[Smart Categorization]
        AI_Context[Context Builder]
        AI_OpenAI[OpenAI API Integration]
        AI_Insights[Insight Generator]
    end

    subgraph Security [Security + Privacy]
        SEC_Encryption[AES-256 Encryption]
        SEC_Biometric[Biometric Auth]
        SEC_TLS[TLS 1.3 + Pinning]
        SEC_RLS[Row Level Security]
        SEC_GDPR[GDPR Compliance]
    end

    subgraph QA [QA + Testing]
        QA_Unit[Unit Tests 70 pct]
        QA_Widget[Widget Tests 50 pct]
        QA_Integration[Integration Tests]
        QA_E2E[E2E Critical Paths]
        QA_Performance[Performance Benchmarks]
    end

    subgraph Launch [Launch Workstream]
        LAUNCH_Screenshots[Store Screenshots]
        LAUNCH_Metadata[App Metadata]
        LAUNCH_Privacy[Privacy Policy]
        LAUNCH_Review[App Review Prep]
        LAUNCH_IAP[IAP Products]
    end

    MOD_Transaction --> UI_Transactions
    MOD_Wallet --> UI_Dashboard
    MOD_Category --> UI_Transactions
    MOD_Budget --> UI_Budgets

    DB_Hive --> MOD_Transaction
    DB_Hive --> MOD_Wallet
    DB_Hive --> MOD_Category
    DB_Hive --> MOD_Budget

    AUTH_Supabase --> UI_Onboarding
    AUTH_Supabase --> SYNC_Queue

    SYNC_Queue --> DB_Postgres
    SYNC_Conflict --> SYNC_Queue
    DB_Postgres --> STORAGE_Cloud

    AI_OnDevice --> AI_Categorization
    AI_Categorization --> UI_Transactions
    AI_Context --> AI_OpenAI
    AI_OpenAI --> EDGE_Functions
    AI_Insights --> UI_AI
    AI_Insights --> UI_Dashboard

    SEC_Encryption --> DB_Hive
    SEC_Biometric --> UI_Settings
    SEC_TLS --> SYNC_Queue
    SEC_RLS --> DB_Postgres
    SEC_GDPR --> LAUNCH_Privacy

    QA_Unit --> MOD_Transaction
    QA_Widget --> UI_Dashboard
    QA_Integration --> SYNC_Queue
    QA_E2E --> UI_Onboarding
    QA_Performance --> DB_Hive

    QA_E2E --> LAUNCH_Review
    LAUNCH_IAP --> UI_Settings
    LAUNCH_Metadata --> LAUNCH_Review
```



## C) Sprint Timeline

```mermaid
gantt
    title Finsor Development Sprints
    dateFormat YYYY-MM-DD
    
    section Phase 1 MVP ✅
    S0 Setup ✅               :done, s0, 2026-02-03, 1d
    S1 Auth+Nav ✅             :done, s1, 2026-02-03, 1d
    S2 Data Models ✅          :done, s2, 2026-02-03, 1d
    S3 Hive CRUD ✅            :done, s3, 2026-02-03, 1d
    S4 Dashboard UI ✅         :done, s4, 2026-02-03, 1d
    S5 Transactions ✅         :done, s5, 2026-02-03, 1d
    S6 Budgets ✅              :done, s6, 2026-02-04, 1d
    S7 Analytics ✅            :done, s7, 2026-02-04, 1d
    S8 MVP Polish ✅           :done, s8, 2026-02-04, 1d

    section Phase 2 Beta 🔶
    S9 Recurring+Goals ✅      :done, s9, 2026-02-05, 1d
    S10 IAP+AI Insights ✅     :done, s10, 2026-02-05, 1d
    S11 Observability ✅       :done, s11, 2026-02-05, 1d
    S12 AppLock+Backup ✅      :done, s12, 2026-02-06, 1d
    S13 Goals+Recurring ✅     :done, s13, 2026-02-06, 1d
    S14 Supabase Sync ✅       :done, s14, 2026-02-06, 2d
    S15 AI Categorization      :active, s15, 2026-02-08, 3d
    S16 AI Chat Interface      :s16, after s15, 3d
    S17 Adv Budgets+Analytics  :s17, after s16, 3d
    S18 Beta Release           :milestone, s18, after s17, 1d

    section Phase 3 Launch ⬜
    S19 Feature Gating         :s19, after s18, 3d
    S20 Store Prep             :s20, after s19, 3d
    S21 Final QA + Submission  :crit, s21, after s20, 3d
    S22 Public Launch          :milestone, s22, after s21, 1d
```



## D) Release Pipeline

```mermaid
flowchart TB
    subgraph Development [Development]
        DEV_Local[Local Development]
        DEV_Feature[Feature Branch]
        DEV_PR[Pull Request]
        DEV_Review[Code Review]
    end

    subgraph CI [CI Pipeline]
        CI_Lint[Flutter Analyze]
        CI_Unit[Unit Tests]
        CI_Widget[Widget Tests]
        CI_Coverage["Coverage Check 70 pct"]
        CI_Build[Build Artifacts]
    end

    subgraph QAGate [QA Gate]
        QA_Manual[Manual Testing]
        QA_Integration[Integration Tests]
        QA_Regression[Regression Suite]
        QA_Perf["Perf Benchmarks - CRITICAL"]
    end

    subgraph BetaRelease [Beta Release]
        BETA_TestFlight[iOS TestFlight]
        BETA_Firebase[Android Firebase Dist]
        BETA_Feedback[User Feedback Collection]
        BETA_Crash[Crash Monitoring]
    end

    subgraph PreLaunch [Pre-Launch Gates]
        GATE_CrashFree["Crash Free Rate 99.5 pct"]
        GATE_AIAccuracy["AI Accuracy 85 pct"]
        GATE_SyncReliable["Sync Reliability 99 pct"]
        GATE_NPS["Beta NPS 30 plus"]
        GATE_NoDataLoss[Zero Data Loss]
    end

    subgraph StoreSubmission [Store Submission]
        STORE_Screenshots[Screenshots All Sizes]
        STORE_Privacy[Privacy Nutrition Labels]
        STORE_DataSafety[Data Safety Form]
        STORE_IAP[IAP Product Config]
        STORE_Review[App Review Submission]
    end

    subgraph Compliance [Compliance Checklist]
        COMPLY_GDPR[GDPR Verified]
        COMPLY_Encryption[Encryption At Rest]
        COMPLY_TLS[TLS 1.3 Enforced]
        COMPLY_Biometric[Biometric Tested]
        COMPLY_Accessibility[Accessibility Audit]
    end

    subgraph PublicLaunch [Public Launch]
        LAUNCH_AppStore[App Store Release]
        LAUNCH_PlayStore[Play Store Release]
        LAUNCH_Monitor[24h Crash Monitoring]
        LAUNCH_Reviews[Review Response SLA]
    end

    DEV_Local --> DEV_Feature
    DEV_Feature --> DEV_PR
    DEV_PR --> DEV_Review
    DEV_Review --> CI_Lint

    CI_Lint --> CI_Unit
    CI_Unit --> CI_Widget
    CI_Widget --> CI_Coverage
    CI_Coverage -->|Pass| CI_Build
    CI_Coverage -->|Fail| DEV_Local

    CI_Build --> QA_Manual
    QA_Manual --> QA_Integration
    QA_Integration --> QA_Regression
    QA_Regression --> QA_Perf

    QA_Perf -->|Phase 2| BETA_TestFlight
    QA_Perf -->|Phase 2| BETA_Firebase
    BETA_TestFlight --> BETA_Feedback
    BETA_Firebase --> BETA_Feedback
    BETA_Feedback --> BETA_Crash

    BETA_Crash --> GATE_CrashFree
    BETA_Crash --> GATE_AIAccuracy
    BETA_Crash --> GATE_SyncReliable
    BETA_Feedback --> GATE_NPS
    GATE_SyncReliable --> GATE_NoDataLoss

    GATE_CrashFree --> COMPLY_GDPR
    GATE_AIAccuracy --> COMPLY_GDPR
    GATE_NPS --> COMPLY_GDPR
    GATE_NoDataLoss --> COMPLY_GDPR

    COMPLY_GDPR --> COMPLY_Encryption
    COMPLY_Encryption --> COMPLY_TLS
    COMPLY_TLS --> COMPLY_Biometric
    COMPLY_Biometric --> COMPLY_Accessibility

    COMPLY_Accessibility --> STORE_Screenshots
    STORE_Screenshots --> STORE_Privacy
    STORE_Privacy --> STORE_DataSafety
    STORE_DataSafety --> STORE_IAP
    STORE_IAP --> STORE_Review

    STORE_Review --> LAUNCH_AppStore
    STORE_Review --> LAUNCH_PlayStore
    LAUNCH_AppStore --> LAUNCH_Monitor
    LAUNCH_PlayStore --> LAUNCH_Monitor
    LAUNCH_Monitor --> LAUNCH_Reviews
```



## Sprint Progress

### Completed Sprints (S0 – S14) — as of 2026-02-07

| Sprint | What shipped | Tests |
|--------|-------------|-------|
| S0–S5 | Project setup, models, Hive CRUD, dashboard, transaction screens, wallet management, category system | ~80 |
| S6–S7 | Budgets with alerts, monthly + weekly + category analytics, period comparison | ~120 |
| S8 | MVP polish, nav drawer, bottom nav (6 tabs), performance benchmarks (<2s cold start) | ~140 |
| S9 | Recurring transactions (daily/weekly/monthly/yearly), goals (savings + debt), goal reconciliation | ~160 |
| S10 | IAP integration (sandbox-ready), AI Insights (prioritized, de-duplicated, explainable), premium gating | ~190 |
| S11 | Sentry observability, error boundaries (AI/IAP/Export), usage event logging | ~200 |
| S12 | App lock (PIN + biometrics), category delete w/ reassignment, export/import backup, manage categories | ~220 |
| S13 | Goals sync + reconciliation, recurring sync, wallet reassignment | ~240 |
| S14 | **Supabase Cloud Sync**: migrations (schema/RLS/indexes/triggers), auth (Apple/Google/Email OTP), sync engine (outbox/push/pull/conflict/realtime/bootstrap), DEV+PROD env wiring, web OAuth fix, auth-callback route, `config.toml` fix | **282** |

### What Sprint 14 delivered (detail)

- **4 SQL migrations** → 7 tables, RLS policies, indexes, `updated_at` triggers
- **Auth**: Google OAuth (web via Supabase, native via `google_sign_in`), Apple (native), Email OTP (6-digit code, not magic link)
- **Sync Engine**: outbox queue, push (oldest-first, exponential backoff), delta pull (`updated_at > lastSyncAt`), conflict resolution (newer wins, device_id tiebreak), realtime subscriptions, bootstrap
- **Env wiring**: `.env.dev` / `.env.prod` with real keys, `Env.webOrigin`, security guard against `service_role` keys
- **Web auth fix**: `/auth-callback` route, Supabase OAuth redirect, removed `google_sign_in` dependency on web
- **CLI fix**: created `supabase/config.toml` (missing file was causing wrong workdir), comprehensive README with troubleshooting

---

## Current State (2026-02-07)

| Layer | Status | Detail |
|-------|--------|--------|
| **Models** | ✅ Done | Transaction, Wallet, Category, Budget, RecurringTransaction, Goal, SyncOperation, UserSettings |
| **Local DB** | ✅ Done | Hive with encryption, offline-first, metadata store |
| **Providers** | ✅ Done | Database, Settings, Transaction, Wallet, Budget, Analytics, Auth, Sync, Premium |
| **Screens** | ✅ Done | Dashboard, Wallets, Transactions, Add/Edit Transaction, Analytics, Budgets, Goals, Categories, Settings, Onboarding, Login, AI Insights |
| **Auth** | ✅ Done | Apple / Google / Email OTP, provider-agnostic, web + native |
| **Cloud Sync** | ✅ Done | Supabase outbox push/pull, realtime, conflict resolution, bootstrap, DEV+PROD |
| **IAP** | ✅ Done | Sandbox-ready, store-backed premium entitlements |
| **AI Insights** | ✅ Partial | InsightContextBuilder + InsightsService (rule-based). Missing: OpenAI chat, smart categorization |
| **Observability** | ✅ Done | Sentry crash reporting, usage events, error boundaries |
| **Security** | ✅ Done | App lock (PIN + biometrics), service_role guard, RLS on all tables |
| **Tests** | ✅ 282 passing | Unit + widget + integration across 14 sprints |

---

## What's Next — Plan Forward

### S15: AI Smart Categorization (next)
- Train/integrate on-device or rule-based auto-categorization from transaction descriptions
- "Learn from corrections" feedback loop
- >70% acceptance rate target
- Tests for categorization accuracy

### S16: AI Chat Interface
- OpenAI API integration via Supabase Edge Function (or direct with API key)
- Chat UI with suggested questions
- Context window: last 90 days transactions + budgets + goals
- Premium-gated
- Graceful offline fallback

### S17: Advanced Budgets + Full Analytics
- Budget rollover (surplus/deficit carry)
- Envelope budgeting mode
- Spending velocity / pace indicator
- Cash flow timeline chart
- Category heatmap
- Net worth tracking

### S18: Beta Release
- TestFlight (iOS) + Firebase App Distribution (Android)
- Target: 100–500 users
- Crash-free >99.5%, sync reliability >99%

### S19–S22: Launch
- Feature gating polish, store screenshots/metadata, privacy policy, final QA, submission

---

## Critical Path Items Remaining

1. **AI Chat** — key differentiator, requires OpenAI integration + edge function
2. **Smart Categorization** — user-facing AI that improves daily experience
3. **Advanced Budgets** — rollover + envelope = competitive with YNAB
4. **Beta Distribution** — real user feedback before public launch
5. **Store Submission** — screenshots, metadata, privacy labels

## Risks

- OpenAI API cost per user (mitigate: context summarization, caching)
- Google Play review for finance apps (mitigate: privacy policy, data safety form early)
- Supabase free tier limits during beta (mitigate: monitor usage, upgrade plan if needed)

