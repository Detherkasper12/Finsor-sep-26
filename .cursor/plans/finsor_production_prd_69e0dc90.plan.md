---
name: Finsor Production PRD
overview: Create a comprehensive, production-ready PRD for Finsor that expands significantly on existing documentation, adding detailed personas, complete feature specs, AI architecture, screen-by-screen UX, security/privacy, edge cases, QA requirements, release plan, and store requirements.
todos:
  - id: section-1-3
    content: Write Product Context, Goals, and User Personas sections
    status: completed
  - id: section-4-5
    content: Write Core Features and Analytics specifications
    status: completed
  - id: section-6
    content: Write AI Assistant architecture and UX details
    status: completed
  - id: section-7
    content: Write complete UX/UI System with screen specifications
    status: completed
  - id: section-8-9
    content: Write Technical Architecture and Security/Privacy sections
    status: completed
  - id: section-10-12
    content: Write Settings, Edge Cases, and QA Testing sections
    status: completed
  - id: section-13-15
    content: Write Release Plan, Metrics, and Future Extensions
    status: completed
isProject: false
---

# Finsor Production-Ready PRD

## Current State Assessment

**Existing Documentation** ([finsor_document_all_documentation.md](finsor_document_all_documentation.md)):

- Basic PRD with feature tables and priorities (P0/P1/P2)
- Technology stack (Flutter, Supabase, Hive, PostgreSQL)
- Database schema with 10 tables
- User flows for onboarding, transactions, AI alerts, budgeting
- Styling guidelines with color palette and typography

**Current Implementation** (updated 2026-02):

- Flutter app with Riverpod state management
- Models: Transaction, Wallet, Category, Budget, RecurringTransaction, Goal, SyncOperation, UserSettings
- Hive local persistence (offline-first, encrypted), AnalyticsRepository, BudgetRepository
- Supabase Cloud Sync: outbox push, delta pull, conflict resolution, realtime, bootstrap (DEV + PROD)
- Auth: Apple Sign-In, Google Sign-In (web OAuth + native), **Email+Password (Sign in / Sign up, Verify email code, Forgot password)**, session persistence, AuthGate
- RecurringService, GoalService with reconciliation
- Real IAP integration (sandbox-ready), store-backed Premium entitlements
- AI Insights: InsightContextBuilder + InsightsService (prioritized, de-duplicated, explainable)
- Observability: Sentry crash/error reporting + usage event logging
- Error boundaries: AI, IAP, Export with friendly fallback UI
- Security: App lock (PIN + biometrics), service_role key guard, RLS on all tables
- Core screens: Home, Analytics, AI Insights (Premium-gated), Settings, Transactions, Budgets, Goals, Categories, Onboarding, Auth (Sign in/up, Verify email, Forgot password)
- ENV wiring: `.env.dev` / `.env.prod`, `Env` class with validation, web origin support
- Supabase CLI: 4 SQL migrations, `config.toml`, comprehensive troubleshooting docs
- **299 tests passing** across 15 sprints (S0–S15)
- **Sprint 14**: Full Supabase cloud sync, web auth fix (OAuth redirect, auth-callback route), CLI workdir fix
- **Sprint 19.1**: Auth + Sync critical fixes — AuthGate session-based (no auto-login), hard logout + Google disconnect, Google account chooser, deep links (reset-password, auth-callback), ResetPasswordScreen, sync on login/logout; `docs/sprint19_1_auth_fix_summary.md`, `docs/auth_deeplink_setup.md`
- **Paused:** Sign-in temporarily off via `AppConfig.authEnabled` / `googleSignInEnabled` (Google Sign-In paused) — set both to `true` to restore AuthGate + CTAs
- **Sprint 15 (NEXT)**: AI Smart Categorization — see below.

**Next sprint — S15: AI Smart Categorization** (sequential; no rework of auth/sync after this):

- Edge Function proxy for categorization (no OpenAI key in client).
- Local rules + AI fallback; free 20/month quota, Premium unlimited.
- AddTransactionBottomSheet: suggestion + metadata.
- EditTransactionScreen: handleCorrection + snackbar.
- retryPendingCategorizations on sync complete.
- After S15: S16 AI Chat polish / Advanced features → Beta release prep → Premium IAP polish → Store prep → Launch (order fixed so nothing is redone).

---

## PRD Structure (15 Sections)

### 1. Product Context

- Product identity and positioning
- Core idea expanded with competitive analysis
- Target user segments (refined)
- Market opportunity statement

### 2. Product Goals

- **Primary goals**: Financial clarity, sub-3-second workflows, AI-driven insights
- **Secondary goals**: Habit formation, premium conversion
- **Non-goals**: Investment advice, tax filing, crypto trading, social features
- **Differentiators vs 1Money, Mint, YNAB, Money Manager**
- **12-24 month vision**: Bank sync, family sharing, investment tracking

### 3. User Personas (5 Detailed)

Each persona includes: demographics, goals, pain points, daily/weekly flows, success metrics

- **Daily Tracker (Alex, 24)**: Quick expense logging, visual feedback
- **Power User (Sarah, 35)**: Multi-wallet, envelope budgeting, exports
- **Casual Tracker (Mike, 28)**: Monthly check-ins, trend awareness
- **Budget-Focused (Lisa, 42)**: Strict budgets, goal savings, alerts
- **Insight-Driven (James, 31)**: AI recommendations, pattern detection

### 4. Core Features (Detailed Specifications)

**4.1 Wallets & Accounts**

- Wallet types: Cash, Debit, Credit, Savings, Investment (future)
- Multi-currency with conversion rates
- Transfer logic and balance calculations
- Edge cases: negative balance handling, closed wallets, currency conversion timing

**4.2 Transactions**

- Manual entry flow (amount → category → wallet → save)
- Quick add with smart defaults
- Edit history with audit trail
- Recurring transaction engine
- Transaction states: pending, cleared, reconciled
- Split transactions across categories

**4.3 Categories**

- Default hierarchy (12 expense, 5 income categories)
- Custom categories with parent/child relationships
- Icon library (100+ icons)
- AI auto-categorization rules
- Category merge/archive operations

**4.4 Budgets**

- Period types: weekly, monthly, custom
- Category budgets with pace indicators
- Rollover logic (surplus/deficit carry)
- Envelope budgeting implementation
- Goal-based saving with target dates
- Budget alerts at 50%, 80%, 100%

### 5. Analytics & Insights

**Analytics Modules**:

- Monthly overview (income, expenses, net, savings rate)
- Category breakdown (pie/bar charts)
- Trend analysis (3-month, 6-month, YTD, YoY)
- Spending velocity (daily average, pace indicator)
- Cash flow timeline
- Net worth tracking (Assets - Liabilities)
- Category heatmap (month × category matrix)
- Merchant insights

**Chart Specifications**:

- Chart types: Line, Bar, Pie, Stacked Area, Heatmap
- Filters: Date range, wallet, category, amount threshold
- Time ranges: This week, this month, last 3/6/12 months, custom
- Progressive disclosure: summary → detailed → drill-down

### 6. AI Assistant (Critical Section)

**Capabilities**:

- Natural language queries about spending
- Smart categorization (>90% accuracy target)
- Pattern detection (spikes, trends, anomalies)
- Budget recommendations
- Behavioral insights ("Why did I spend more?")
- Predictive cash flow

**Architecture**:

- Hybrid approach: on-device for categorization, cloud for insights
- Context window: Last 90 days transactions + current budgets + goals
- Prompt structure: System role + financial context + user query
- Privacy safeguards: No raw data transmitted, aggregated summaries only

**Constraints**:

- No investment/tax advice (legal disclaimer)
- No hallucinated numbers (strict data binding)
- User data only (no external assumptions)
- Graceful degradation when offline

**UX**:

- Chat UI with suggested questions
- Insight cards on dashboard
- Alert-driven interactions
- Explainability ("Based on your last 30 days...")

### 7. UX/UI System

**Design Principles**:

- Minimal, calm, professional
- One-hand usage optimized
- ADHD-friendly (low cognitive load)
- Visual hierarchy (numbers prominent)
- 8pt grid system

**Screen Specifications** (10 screens):


| Screen            | Purpose            | Key Components                                              | Empty State                      | Error State               |
| ----------------- | ------------------ | ----------------------------------------------------------- | -------------------------------- | ------------------------- |
| Onboarding        | Setup              | Currency, wallet, initial balance                           | N/A                              | Validation errors         |
| Home/Dashboard    | Overview           | Balance card, quick stats, recent transactions, AI insights | "Add your first transaction"     | Sync failed banner        |
| Wallets           | Account management | Wallet cards, transfer FAB                                  | "Create your first wallet"       | Balance mismatch warning  |
| Add Transaction   | Data entry         | Numpad, category picker, wallet selector                    | Pre-filled defaults              | Validation inline         |
| Transactions List | History            | Filterable list, search, bulk actions                       | "No transactions yet"            | Load failed, retry        |
| Analytics         | Insights           | Charts, filters, time selector                              | "Track for 7 days to see trends" | Chart load error          |
| Budgets           | Planning           | Budget cards, progress bars, goals                          | "Set your first budget"          | Calculation error         |
| AI Assistant      | Chat               | Message list, input, suggestions                            | Welcome + example prompts        | "AI unavailable" fallback |
| Settings          | Configuration      | Theme, currency, export, account                            | N/A                              | Save failed toast         |
| Category Manager  | Customization      | Category list, icons, colors                                | Default categories shown         | N/A                       |


### 8. Technical Architecture

**Frontend (Flutter)**:

- State: Riverpod with AsyncNotifier
- Navigation: GoRouter with deep linking
- Local DB: Hive with encryption
- Performance: Lazy loading, virtualized lists

**Backend (Supabase + Cloud Functions)**:

- Auth: Email/password, Google, Apple SSO
- Database: PostgreSQL with RLS
- Sync: Real-time subscriptions with conflict resolution
- AI: Cloud Functions calling OpenAI API

**Offline-First Strategy**:

- All CRUD operations work offline
- Queue pending syncs
- Conflict resolution: Last-write-wins with user notification
- Sync indicator in UI

**Database Migration Strategy**:

- Versioned schema migrations
- Backward compatibility for 2 versions
- Data export before major migrations

### 9. Security & Privacy

**Encryption**:

- Local: AES-256 via Hive encryption
- Transit: TLS 1.3
- At rest (cloud): Supabase encryption + column-level for sensitive fields

**Authentication**:

- Biometric unlock (Face ID, Touch ID, Fingerprint)
- Session timeout: 15 minutes inactive
- Secure token storage: iOS Keychain, Android Keystore

**Privacy**:

- Local-first by default
- Cloud sync opt-in only
- No third-party analytics (or privacy-safe alternatives only)
- GDPR compliance: Data export, deletion, consent management
- No selling user data (privacy policy commitment)

### 10. Settings & Customization

- **Display**: Theme (light/dark/system), language (EN, RU, ES, DE, FR)
- **Currency**: Base currency, decimal places, symbol position
- **Security**: Biometric lock, auto-lock timeout, PIN backup
- **Data**: Export (CSV, JSON), backup/restore, clear all data
- **AI**: Enable/disable, verbosity level (brief/detailed)
- **Notifications**: Budget alerts, recurring reminders, AI insights
- **Sync**: Enable cloud sync, sync frequency, conflict preference

### 11. Edge Cases & Failure Modes

**App Lifecycle**:

- App reinstall: Detect existing local data, prompt restore
- Data corruption: Checksum validation, auto-recovery from backup
- Version upgrade: Migration wizard for breaking changes

**Sync Issues**:

- Partial sync: Transaction-level retry, show sync status
- Conflict: Merge dialog for non-trivial conflicts
- Offline duration: Queue management, bulk sync on reconnect

**User Errors**:

- Duplicate transactions: Detection algorithm, merge suggestion
- Category deletion with linked transactions: Reassignment wizard
- Wallet deletion: Archive instead, historical data preserved

**AI Errors**:

- Wrong categorization: One-tap correction, learning feedback
- Nonsensical response: Fallback to canned response, error logging
- API timeout: Local fallback insights

### 12. QA & Testing Requirements

**Unit Testing**:

- Business logic (budget calculations, balance updates)
- Data transformations (currency, date formatting)
- AI prompt generation
- Coverage target: 80%

**Widget Testing**:

- All form validations
- Chart rendering
- State transitions
- Empty/error states

**Integration Testing**:

- Transaction CRUD flow
- Sync cycle
- AI conversation
- Onboarding to first transaction

**Performance Benchmarks**:

- Cold start: <2s
- Transaction save: <500ms
- Dashboard load (10k transactions): <2s
- Search: <300ms
- Scroll: 60 FPS

**Device Matrix**:

- iOS: iPhone 15, 16, 17 Pro; iPad
- Android: Pixel 6, Samsung S23 Ultra, mid-range (Redmi Note 12)

### 13. Release Plan

**Phase 1: MVP (Weeks 1-8)**

- Wallets, transactions, categories
- Basic budgets (no rollover)
- Simple analytics (monthly summary)
- Local storage only
- Target: Internal testing

**Phase 2: Beta (Weeks 9-14)**

- AI assistant (basic)
- Cloud sync
- Advanced budgets
- Full analytics
- Target: 100-500 TestFlight/Firebase users

**Phase 3: Public Launch (Weeks 15-18)**

- Polish and bug fixes
- Store optimization
- Premium subscription integration
- Target: App Store + Google Play

**Store Requirements**:

- **App Store**: 
  - Screenshots: 6.5" (iPhone 15 Pro Max), 5.5" (iPhone 8 Plus), 12.9" (iPad Pro)
  - App Preview video (optional but recommended)
  - Privacy nutrition labels
  - Age rating: 4+
  - Category: Finance
- **Google Play**:
  - Feature graphic: 1024x500
  - Screenshots: Phone + 7" tablet
  - Privacy policy URL
  - Target API level: 34
  - Category: Finance

**Permissions Required**:

- Camera (receipt scanning, future)
- Biometrics (authentication)
- Notifications (alerts)
- Internet (sync, AI)

### 14. Metrics & Success Criteria

**Activation**:

- First transaction within 24h: >60%
- Onboarding completion: >85%
- Second session within 7 days: >50%

**Engagement**:

- DAU/MAU ratio: >25%
- Transactions per active user per week: >5
- AI queries per Premium user per month: >10

**Retention**:

- Day 1: >70%
- Day 7: >50%
- Day 30: >35%
- Day 90: >25%

**Monetization**:

- Free to Premium conversion: 3-5%
- Subscription retention (annual): >70%
- Trial to paid: >40%

**Performance**:

- Crash-free rate: >99.5%
- ANR rate: <0.5%
- App Store rating: >4.5

**AI-Specific**:

- Categorization acceptance rate: >70%
- AI insight engagement: >30% of Premium users weekly

### 15. Future Extensions (Post-Launch)

**P1 (3-6 months post-launch)**:

- Bank sync integration (Plaid/regional providers)
- Widgets (iOS/Android home screen)
- Receipt OCR scanning
- Shared wallets (family mode)

**P2 (6-12 months)**:

- Investment tracking (manual first)
- Net worth dashboard
- Tax report generation
- Multi-device sync improvements

**Experimental (12+ months)**:

- Voice input for transactions
- Subscription tracker (auto-detect recurring)
- Credit score integration (US)
- Gamification elements (optional)

**Explicitly NOT planned**:

- Cryptocurrency tracking
- Stock trading
- Peer-to-peer payments
- Social features (spending comparisons)

---

## Deliverable

A single comprehensive Markdown document (`FINSOR_PRD_COMPLETE.md`) containing all 15 sections, formatted with:

- Clear headings and subheadings
- Tables for structured data
- Bullet lists for specifications
- Code snippets for technical details where helpful
- Mermaid diagrams for architecture and flows

**Estimated length**: 4000-5000 lines (comprehensive but not bloated)