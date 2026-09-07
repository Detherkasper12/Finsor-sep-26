# Finsor Project Roadmap Visualization

> End-to-end project visualization from current state to public launch.
> Based on `FINSOR_PRD_COMPLETE.md` as the single source of truth.

---

## A) High-Level Roadmap Flowchart

**Phases → Milestones → Outputs**

```mermaid
flowchart TB
    subgraph CurrentState [Current State]
        CS1[Flutter Project Setup]
        CS2[Core Models Defined]
        CS3[Basic UI Screens]
        CS4[Local Providers]
        CS5[Mock Database]
    end

    subgraph Phase1 [Phase 1: MVP - Weeks 1-8]
        P1M1[Auth Integration]
        P1M2[Hive Local Storage]
        P1M3[Transaction CRUD]
        P1M4[Wallet Management]
        P1M5[Category System]
        P1M6[Basic Budgets]
        P1M7[Monthly Analytics]
        P1M8["Internal Release"]
    end

    subgraph Phase2 [Phase 2: Beta - Weeks 9-14]
        P2M1[Supabase Setup]
        P2M2[Cloud Sync Engine]
        P2M3[Offline-First Logic]
        P2M4[AI Categorization]
        P2M5[AI Chat Interface]
        P2M6[Advanced Budgets]
        P2M7[Full Analytics Suite]
        P2M8["Beta Release - 500 Users"]
    end

    subgraph Phase3 [Phase 3: Launch - Weeks 15-18]
        P3M1[Premium IAP Setup]
        P3M2[Feature Gating]
        P3M3[Store Assets Prep]
        P3M4[Final QA Pass]
        P3M5[Store Submission]
        P3M6["Public Launch"]
    end

    subgraph PostLaunch [Post-Launch P1 Features]
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
```

### Phase Summary

| Phase | Duration | Key Output | Exit Criteria |
|-------|----------|------------|---------------|
| **Current** | - | Foundation code | Models, providers, screens scaffolded |
| **Phase 1** | Weeks 1-8 | Internal MVP | All P0 features, 70% test coverage |
| **Phase 2** | Weeks 9-14 | Beta Release | AI 85% accuracy, sync 99% reliable |
| **Phase 3** | Weeks 15-18 | Public Launch | Store approved, crash-free 99.5% |
| **Post-Launch** | 3-6 months | P1 Features | Bank sync, widgets, OCR, family mode |

---

## B) Detailed Dependency Graph

**What depends on what across all workstreams**

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

### Critical Path Components

| Component | Why Critical | Blocks |
|-----------|--------------|--------|
| **Hive Encrypted DB** | Foundation for all data | All models, sync, AI |
| **Sync Engine** | Offline-first architecture | Cloud features, multi-device |
| **AI Chat** | Key product differentiator | Premium value proposition |
| **Performance Benchmarks** | User experience gate | Store submission |

---

## C) Sprint Timeline

**Sprint 0 → Sprint 19 with key deliverables**

```mermaid
gantt
    title Finsor Development Sprints
    dateFormat YYYY-MM-DD
    
    section Phase 1 MVP
    Sprint_0_Setup           :s0, 2026-02-03, 7d
    Sprint_1_Auth_Nav        :s1, after s0, 7d
    Sprint_2_Data_Models     :s2, after s1, 7d
    Sprint_3_Hive_CRUD       :crit, s3, after s2, 7d
    Sprint_4_Dashboard_UI    :s4, after s3, 7d
    Sprint_5_Transactions    :s5, after s4, 7d
    Sprint_6_Budgets         :s6, after s5, 7d
    Sprint_7_Analytics       :s7, after s6, 7d
    Sprint_8_MVP_Polish      :milestone, s8, after s7, 7d

    section Phase 2 Beta
    Sprint_9_Supabase        :s9, after s8, 7d
    Sprint_10_Sync_Engine    :crit, s10, after s9, 7d
    Sprint_11_Offline_First  :s11, after s10, 7d
    Sprint_12_AI_Categ       :s12, after s11, 7d
    Sprint_13_AI_Chat        :crit, s13, after s12, 7d
    Sprint_14_Adv_Features   :s14, after s13, 7d
    Sprint_15_Beta_Release   :milestone, s15, after s14, 7d

    section Phase 3 Launch
    Sprint_16_Premium_IAP    :s16, after s15, 7d
    Sprint_17_Store_Prep     :s17, after s16, 7d
    Sprint_18_Submission     :crit, s18, after s17, 7d
    Sprint_19_Launch         :milestone, s19, after s18, 7d
```

### Sprint Deliverables Detail

| Sprint | Name | Key Deliverables |
|--------|------|------------------|
| **0** | Setup | Project config, CI/CD, linting |
| **1** | Auth + Nav | Supabase auth, GoRouter, onboarding |
| **2** | Data Models | Transaction, Wallet, Category, Budget entities |
| **3** | Hive CRUD | Encrypted storage, basic CRUD operations |
| **4** | Dashboard UI | Home screen, balance card, wallet selector |
| **5** | Transactions | Add/edit/delete, list view, filters |
| **6** | Budgets | Category budgets, progress tracking, alerts |
| **7** | Analytics | Monthly overview, category breakdown, trends |
| **8** | MVP Polish | Bug fixes, QA pass, internal release |
| **9** | Supabase | Cloud config, schema, RLS policies |
| **10** | Sync Engine | Queue manager, conflict resolution |
| **11** | Offline-First | Background sync, connectivity handling |
| **12** | AI Categorization | On-device ML, smart suggestions |
| **13** | AI Chat | OpenAI integration, chat UI, insights |
| **14** | Adv Features | Rollover budgets, goals, full analytics |
| **15** | Beta Release | TestFlight + Firebase distribution |
| **16** | Premium IAP | StoreKit/Billing, feature gating |
| **17** | Store Prep | Screenshots, metadata, privacy labels |
| **18** | Submission | App Store + Play Store review |
| **19** | Launch | Public release, monitoring, support |

---

## D) Release Pipeline

**Dev → QA → Beta → Store Release with gates and criteria**

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

### Gate Criteria Summary

| Gate | Metric | Target | Blocker If |
|------|--------|--------|------------|
| **CI Coverage** | Line coverage | ≥70% | <70% |
| **Performance** | Cold start | <2s | >3s |
| **Performance** | Transaction save | <500ms | >1s |
| **Crash-Free** | Sessions without crash | ≥99.5% | <99% |
| **AI Accuracy** | Correct categorization | ≥85% | <80% |
| **Sync Reliability** | Successful syncs | ≥99% | <95% |
| **Beta NPS** | Net Promoter Score | ≥30 | <20 |
| **Data Loss** | Incidents | 0 | >0 |

### Store Submission Checklist

**App Store (iOS)**
- [ ] Screenshots: 6.7", 6.5", 5.5" sizes
- [ ] App Preview video (15-30s)
- [ ] Privacy nutrition labels completed
- [ ] In-app purchase products created
- [ ] Age rating: 4+
- [ ] Category: Finance

**Play Store (Android)**
- [ ] Feature graphic: 1024x500
- [ ] Screenshots: Phone + Tablet
- [ ] Data safety form completed
- [ ] Target API level ≥34
- [ ] Content rating questionnaire

---

## Current State Analysis

Based on existing `lib/` structure:

| Component | Status | Files |
|-----------|--------|-------|
| **Models** | DEFINED | transaction.dart, wallet.dart, category.dart, budget.dart |
| **Providers** | IN PROGRESS | database_provider.dart, wallet_provider.dart, transaction_provider.dart |
| **Screens** | SCAFFOLDED | home/, analytics/, ai/, settings/, transactions/ |
| **Services** | PARTIAL | database_service.dart, ai_service.dart, export_service.dart |
| **Utils** | COMPLETE | currency_formatter.dart, date_helper.dart, page_transitions.dart |

### Missing for MVP Completion

- [ ] Supabase auth integration
- [ ] Hive encryption setup
- [ ] Real database service (not mock)
- [ ] Complete transaction CRUD
- [ ] Budget tracking logic
- [ ] Analytics calculations

---

## TODO / Undefined in PRD

Items requiring clarification before implementation:

| Item | Status | Decision Needed |
|------|--------|-----------------|
| Bank API partner | TODO | Plaid vs regional providers |
| AI model version | TODO | GPT-3.5 vs GPT-4 (cost/quality) |
| Widget designs | TODO | Specific layouts not specified |
| OCR vendor | TODO | Google Vision vs Apple Vision vs third-party |
| Beta user selection | TODO | Criteria for 500 users |

---

*Generated from FINSOR_PRD_COMPLETE.md - February 2026*
