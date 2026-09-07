# FINSOR DOCUMENT

## Project Description
Finsor is a cross-platform personal finance tracking app designed to help users clearly understand, control, and improve their financial life. The app allows users to track income and expenses, manage multiple wallets, set budgets, and analyze spending through clean, visual analytics.

Finsor focuses on simplicity, speed, and clarity, inspired by minimal finance apps like 1Money, while adding smart AI features. An integrated AI assistant helps users categorize transactions, detect spending patterns, provide insights, and suggest ways to save money and optimize budgets.

The target audience includes young adults and everyday users who want an easy, modern, and intelligent way to manage their money without complexity. Finsor is built to be fast, intuitive, privacy-focused, and visually polished, with support for manual and automated tracking, detailed statistics, and future scalability.

## Product Requirements Document
# FINSOR DOCUMENT: PRODUCT REQUIREMENTS DOCUMENT (PRD)

## 1. Introduction

### 1.1 Purpose and Scope
This Product Requirements Document (PRD) details the requirements, goals, features, and specifications for Finsor, a cross-platform personal finance tracking application. Finsor aims to provide users with a simple, fast, and intelligent platform for understanding and managing their financial life, leveraging an integrated AI assistant.

This document serves as the guiding source for design, engineering, and quality assurance teams throughout the development lifecycle.

### 1.2 Goals and Objectives
1.  **Clarity & Simplicity:** Deliver an extremely intuitive, fast, and visually polished user experience, minimizing cognitive load (inspired by 1Money).
2.  **Intelligence:** Integrate a practical AI assistant to automate categorization, surface actionable insights, and improve user financial literacy.
3.  **Control:** Provide robust, flexible budgeting and tracking mechanisms that accommodate diverse user needs, from basic tracking to advanced planning.
4.  **Performance:** Ensure near-instantaneous performance across all core user flows, regardless of data volume.
5.  **Privacy:** Establish a privacy-first architecture where local storage is prioritized, and data transmission is secure and minimal.

### 1.3 Target Audience
The primary audience consists of:
*   **Young Professionals (18-30):** Seeking an easy way to build tracking habits and awareness.
*   **Budget-Conscious Individuals (25-45):** Needing flexible tools to stick to complex budgets and analyze trends.
*   **Financially Curious Users:** Users of any age who want deep insights without the complexity of enterprise-level software.

### 1.4 Monetization Strategy
Finsor will utilize a **Freemium model**:
*   **Free Tier:** Core functionality including manual transaction entry, basic budgets, categorization, essential analytics, and limited data export. Offline usage is fully supported.
*   **Premium Subscription:** Unlocks advanced features: Full AI Assistant suite, automated bank synchronization (where available), advanced budgeting tools (Rollover, Envelope, Goals), deep analytics, cloud sync, widgets, and enhanced privacy controls.
*   **Lifetime Purchase:** An optional, one-time purchase option equivalent to multiple years of subscription.

## 2. Features and Requirements

### 2.1 Core Tracking and Data Management

| ID | Feature | Description | Priority | Requirements |
| :--- | :--- | :--- | :--- | :--- |
| T-101 | Transaction Entry (Manual) | Fastest possible input method for income/expense. | P0 (Must Have) | Must support Amount, Date, Category, Wallet, Notes, Tags, and Photo attachment (future). Must reflect instantly in UI. |
| T-102 | Wallet/Account Management | Ability to create, manage, and track balances across multiple distinct financial accounts (e.g., Checking, Savings, Cash). | P0 (Must Have) | Support initial balance setup. Support transfers between user-defined wallets. |
| T-103 | Categorization System | Hierarchical and customizable categories. | P0 (Must Have) | Support user-defined subcategories. Must integrate seamlessly with AI categorization (A-101). |
| T-104 | Transaction Editing | Full ability to edit all transaction details post-entry. | P0 (Must Have) | Must trigger immediate recalculations for budgets and analytics. |
| T-105 | Transaction Splitting | Ability to divide a single transaction across multiple categories or wallets. | P1 (High) | Essential for handling combined purchases (e.g., a single store trip covering groceries and supplies). |
| T-106 | Recurrence Definition | Ability to mark transactions as recurring (e.g., monthly rent, salary). | P1 (High) | Future-proofed schema required for predictive analysis (F-103). |
| T-107 | Automated Tracking Integration | Architecture must support integration with banking aggregation services (Premium Feature). | P2 (Medium - Architectural) | Requires robust security framework and regional adaptability via third-party APIs. |
| T-108 | Receipt Scanning (OCR) | Ability to photograph a receipt and extract key data (merchant, amount, date) for quick manual entry prep. | P1 (High) | Acts as a bridge between manual control and automation. |

### 2.2 AI Assistant Functionality (Premium)

The AI Assistant is central to the value proposition of the Premium tier, focusing on critical functions (Scope 2).

| ID | Feature | Description | Priority | Requirements |
| :--- | :--- | :--- | :--- | :--- |
| A-101 | Smart Transaction Categorization | Automatically suggest or assign categories based on merchant data, location (if provided), and historical user behavior. | P0 (Core Premium) | Accuracy must exceed 90% baseline. Must learn from user corrections instantly and permanently update its models. |
| A-102 | Spending Pattern Analysis & Alerts | Proactively monitor transactions for anomalies and trends. | P0 (Core Premium) | Alerts must include: sudden category spikes (e.g., "Your dining spend is 40% higher than the 3-month average"), recurring payment changes, and unusual large transactions. Alerts must be clear and actionable. |
| A-103 | Personalized Financial Insights | Generate human-readable suggestions for optimization. | P1 (High Premium) | Examples: "If you reduce coffee spending by $50 this month, you could fully fund your vacation savings goal," or "You consistently underspend in 'Utilities'; consider reducing that budget buffer." |
| A-104 | Predictive Cash Flow | Based on recurring income/bills, forecast net balance at the end of the current cycle. | P2 (Medium Premium) | Requires T-106 (Recurrence). Display projection clearly on the dashboard. |

### 2.3 Budgeting System (Advanced Flexibility)

Finsor budgeting must be powerful under the hood while remaining visually simple (Complexity: Advanced/Flexible).

| ID | Feature | Description | Priority | Requirements |
| :--- | :--- | :--- | :--- | :--- |
| B-101 | Category Budgets | Standard budget limits per category (Monthly, Weekly, Custom Period). | P0 (Must Have) | Must clearly show: Amount allocated, Amount spent, Remaining, Pace Indicator (Are you ahead/behind schedule?). |
| B-102 | Rollover Budgets (Premium) | Unused budget amounts carry over to the next period; overspending reduces the next period's allowance. | P1 (High Premium) | Clear visual indication of the rolled-over amount applied. |
| B-103 | Envelope Budgeting (Premium) | Ability to pre-allocate funds into virtual envelopes/buckets at the start of a period. | P1 (High Premium) | Users must only be able to spend what is allocated in the envelope, preventing accidental use of general funds. |
| B-104 | Goals-Based Saving (Premium) | Define specific financial goals (e.g., $5,000 for a car by Dec 2025). | P1 (High Premium) | Must track progress toward the total target and calculate required periodic contribution. |
| B-105 | Income-Aware Planning | Budgets and goals must be viewable in the context of expected income cycles (e.g., paycheck dates). | P2 (Medium) | Users should be able to view budgets relative to their next expected income event. |
| B-106 | Budget Rules & Exceptions | Ability to exclude specific types of transactions (e.g., internal transfers, refunds) from affecting a budget calculation. | P1 (High) | Essential for accuracy when using advanced budget types. |

### 2.4 Analytics and Reporting

Reporting must go beyond basic charts, offering deep, comparative insights (Depth: Comprehensive).

| ID | Feature | Description | Priority | Requirements |
| :--- | :--- | :--- | :--- | :--- |
| R-101 | Core Dashboard Summary | Immediate view of current balances, recent activity, and high-level budget health. | P0 (Must Have) | Must adhere to P-201 (Performance) standards. |
| R-102 | Trend Line Analysis | Visual representation of spending, income, and net savings over selectable periods (Week, Month, Year, Custom). | P1 (High) | Must overlay data for comparison (e.g., Q1 2024 vs Q1 2023). |
| R-103 | Cash Flow View | Timeline view showing the inflow and outflow rhythm over time, culminating in the net result. | P1 (High) | Helps users visualize liquidity. |
| R-104 | Net Worth Tracking | Historical tracking of Assets minus Liabilities. | P2 (Medium) | Requires users to define and track liability accounts. |
| R-105 | Category Heatmap | Matrix visualization comparing spending across all categories over multiple months. | P1 (High) | Quick identification of spending creep over time. |
| R-106 | Budget Performance Reporting | Detailed report showing budget adherence, pace, and projected end-of-period status for all active budgets. | P1 (High) | Must integrate B-102/B-103 indicators clearly. |
| R-107 | Merchant Insights | Report detailing top spending merchants, tracking spending changes with specific vendors over time. | P2 (Medium) | Requires accurate transaction tagging/merchant normalization. |
| R-108 | Data Export (Premium) | Ability to export filtered/selected data into CSV, Excel (XLSX), and PDF formats. | P1 (High Premium) | User must select the exact date range and filters applied to the report. |

## 3. Technical and Design Specifications

### 3.1 Cross-Platform Implementation
Finsor must feel native and performant on its primary platforms: iOS and Android.
*   **Primary Framework:** Flutter is strongly recommended to ensure UI/UX consistency and high performance across mobile targets.
*   **Mobile First:** All core functionality (Tracking, Budgeting, AI interaction) must be fully realized and optimized on mobile devices first.
*   **Web Complement:** A complementary web application will provide read-only dashboards, deep analytics review, and account management, but transactional speed is secondary to mobile.

### 3.2 Native Platform Requirements
The following native features must be implemented correctly for each mobile OS:
*   **Biometric Security:** Face ID/Touch ID (iOS) and Fingerprint/Biometrics (Android) required for app entry and confirming sensitive actions (e.g., deleting all data, setting up bank sync).
*   **Widgets:** Support for home screen widgets displaying key metrics (Current Balance, Monthly Spend remaining, Budget Pace).
*   **Notifications:** Robust handling for OS-level notifications for budget alerts (A-102) and upcoming recurring payments (T-106).
*   **Secure Storage:** Use of platform-specific secure storage (Keychain/Keystore) for encrypting local API tokens or sensitive configuration data.

### 3.3 Performance Benchmarks
Finsor must prioritize speed to maintain user engagement. Failure to meet these benchmarks requires immediate engineering review.

*   **App Cold Start:** < 2.0 seconds on mid-range target devices.
*   **Main Dashboard Load:** < 1.0 second (up to 500 transactions); < 2.0 seconds (up to 10,000 transactions).
*   **Add Transaction Flow:** UI interaction < 200ms; persistence and UI reflection < 500ms.
*   **Search/Filtering:** Results update < 300ms for typical queries.
*   **Scrolling List:** Consistent 60 FPS using virtualization techniques.
*   **Analytics Generation:** Cached reports must load instantly. Heavy, uncached reports < 3.0 seconds.
*   **Stability:** Performance metrics must be maintained during offline mode, while local encryption is active, and during background synchronization processes.

### 3.4 Design and Polish Constraints
The aesthetic must be professional, calm, and highly readable.
*   **Inspiration:** Minimalist finance apps (e.g., 1Money).
*   **Aesthetic:** Clean, modern, high use of negative space. Focus on clarity and visual hierarchy.
*   **Color Palette:** Restrained. Neutral backgrounds (light/dark mode support) with purposeful accent colors used only for status (positive/negative) and category identification.
*   **Animation:** Subtle, purposeful transitions that aid navigation, avoiding distraction or gamification elements.

### 3.5 Data Security and Privacy Architecture
Privacy is a fundamental architectural constraint (Constraint 5).
*   **Local Priority:** Financial data must reside primarily on the user's device by default.
*   **Cloud Sync (Optional):** Cloud synchronization is strictly an opt-in Premium feature. When active, data transmission must use TLS 1.2+ and all stored cloud data must be encrypted using AES-256 or stronger standards.
*   **Encryption:** All data stored locally (if applicable beyond OS defaults) and transmitted must utilize strong, industry-standard encryption. Encryption keys must be managed securely (referencing 3.2 for secure storage usage).
*   **Data Minimization:** The system should not collect unnecessary PII. Insights generation should rely on anonymized or aggregate data paths where possible.
*   **User Control:** Users must have clear, accessible paths to export their entire dataset (T-108) and permanently delete their account/data.

### 3.6 Future Scalability Priorities
The underlying data schema must accommodate future requirements without significant refactoring:
*   **Multi-Currency Support:** Schema must natively support transaction amounts in various currencies, tracked against a user-defined base currency, applying historical FX rates where necessary.
*   **Shared/Family Features:** Data structures must allow for user roles and permissions associated with specific wallets or budgets.
*   **Investment Tracking:** Schema must allow for asset holding records separate from cash transactions (e.g., quantity, cost basis, market price).
*   **Rules Engine:** Support for persistent, user-defined automation rules (e.g., "Any transaction over $100 from Amazon goes to the Shopping category").
*   **Cloud Sync/Conflict Resolution:** Schema must support audit trails necessary for reliable multi-device synchronization and conflict resolution.

## 4. Success Metrics

Success will be measured against the following KPIs:

1.  **Engagement:** Daily Active Users (DAU) / Monthly Active Users (MAU) ratio > 25%.
2.  **Retention:** 90-day user retention rate > 40%.
3.  **Monetization:** Free-to-Premium conversion rate target of 3-5%.
4.  **Performance:** 99th percentile load times consistently meeting Section 3.3 benchmarks.
5.  **AI Adoption:** Percentage of users who accept the AI's category suggestion > 70% for new transactions.

## Technology Stack
# FINSOR: TECHNOLOGY STACK DOCUMENT (TECHSTACK)

This document outlines the recommended technology stack for the development of Finsor, a cross-platform personal finance tracking application focusing on performance, design minimalism, and integrated AI intelligence.

## 1. Mobile Application Development (Core Product)

The primary focus is delivering a high-performance, visually consistent experience across iOS and Android, aligning with design constraints and performance benchmarks.

**Technology:** Flutter (Dart)
**Justification:**
*   **Cross-Platform Efficiency:** Enables simultaneous development for iOS and Android from a single codebase, meeting the need for consistent UI/UX and faster feature parity.
*   **Performance:** Flutter compiles to native code, ensuring performance benchmarks (sub-2-second load times, 60 FPS scrolling) are achievable, crucial for a data-heavy finance app.
*   **Design Fidelity:** Excellent support for custom, polished UIs, declarative rendering, and subtle animations required by the minimal, design-driven aesthetic.
*   **Platform Integration:** Good ecosystem support for accessing native features like Biometric Lock (KeyStore/Keychain integration) and Home Screen Widgets via platform channels or dedicated plugins.

**Key Dependencies (Flutter Ecosystem):**
*   **State Management:** Provider or Riverpod for scalable, predictable state handling, essential for complex budget calculations and real-time dashboard updates.
*   **Local Persistence:** Hive or Isar (NoSQL databases optimized for Flutter) for fast, local, and encrypted storage of core transaction data, meeting strict performance and privacy goals.
*   **Charting/Visualization:** Custom or specialized libraries (e.g., fl_chart) tailored to produce the required deep analytics (heatmap, trend lines, cash flow).

## 2. Backend Services & Data Processing

The backend supports subscription management, secure cloud synchronization (for premium users), and, critically, the computationally intensive AI/ML processing pipeline.

### 2.1. Core Backend Framework

**Technology:** Kotlin (JVM) with Spring Boot or Go (Golang)
**Justification:**
*   **Scalability & Performance:** Both are excellent choices for high-concurrency, high-throughput services required for handling periodic syncs, analytics jobs, and secure user management. Kotlin/Spring Boot offers a mature ecosystem; Go excels at network I/O and lightweight microservices.
*   **AI Integration:** The JVM ecosystem (Kotlin) has robust libraries for integrating machine learning models (via Python deployment or direct integration).

### 2.2. Database (Backend)

**Technology:** PostgreSQL
**Justification:**
*   **Data Integrity & Transactions:** Financial data demands ACID compliance, which PostgreSQL excels at. It natively supports complex JSON structures (for flexible schema evolution needed for future scalability features like investment tracking).
*   **Geospatial/Advanced Indexing:** Supports features necessary for potential future location-based analysis or advanced rule processing.

### 2.3. Cloud Synchronization & Authentication

**Technology:** Firebase (Auth & Cloud Messaging) / AWS Cognito
**Justification:**
*   **Authentication:** Secure, managed user authentication supporting standard flows required for freemium monetization models and secure account management.
*   **Notifications:** Firebase Cloud Messaging (FCM) or similar for budget alerts and spending pattern notifications across iOS and Android.

## 3. AI & Machine Learning Pipeline

The AI Assistant is a critical premium feature, requiring a robust pipeline for inference and model training.

**Technology:** Python ecosystem (TensorFlow/PyTorch) hosted on cloud compute (e.g., AWS SageMaker, Google AI Platform).
**Justification:**
*   **Model Development:** Python offers the industry standard for NLP and predictive modeling necessary for smart categorization and personalized insights.
*   **Transaction Categorization:** Utilizes NLP techniques (e.g., text classification on transaction descriptions) trained on aggregated/anonymized data. Models must adapt via transfer learning based on user corrections fed back to the system.
*   **Pattern Analysis:** Time-series analysis (e.g., Prophet, specialized RNNs) for detecting anomalies and forecasting budget performance, respecting the complex budgeting requirements (rollover, goals).

## 4. Data Security and Local Persistence (Critical Path)

Meeting the non-negotiable privacy constraints requires robust local security.

**Technology:**
1.  **Local Database Encryption:** Built-in AES-256 encryption provided by the chosen local DB (Hive/Isar configuration).
2.  **Key Management:** Integration with **iOS Keychain** and **Android Keystore** for secure storage of encryption keys, database access tokens, and biometric authentication secrets.
3.  **Transmission Security:** Mandatory HTTPS/TLS 1.3 across all communications. Sensitive data payloads must be encrypted end-to-end where possible (e.g., using Signal Protocol concepts for sync).

## 5. Third-Party Integrations (Automation)

The architecture must remain flexible to accommodate various regional bank integration needs.

**Technology:** Plaid, Yodlee, or regional equivalents (via standardized APIs).
**Justification:**
*   **Bank Aggregation:** Provides the necessary framework to handle differing security protocols and authentication methods across numerous financial institutions globally, supporting the automation tier of the premium offering.
*   **OCR Processing:** Cloud-based service (e.g., Google Vision API or Tesseract wrapper) for initial receipt scanning, feeding into the local transaction entry workflow.

## 6. Infrastructure and Deployment

**Technology:** Docker, Kubernetes (for AI/Backend scaling), Cloud Provider (AWS or GCP)
**Justification:**
*   **Containerization (Docker):** Ensures environment consistency between development, testing, and production for all backend and ML services.
*   **Scalability (Kubernetes):** Necessary for managing the potentially high load spikes associated with nightly syncs or batch analytics processing jobs for the AI pipeline.

## Summary of Recommended Stack

| Component | Primary Technology | Rationale Summary |
| :--- | :--- | :--- |
| **Frontend (Mobile)** | Flutter (Dart) | Performance, single codebase, design fidelity. |
| **Backend Logic** | Kotlin (Spring Boot) / Go | Scalability, concurrency, robust ecosystem. |
| **Core Database (Backend)**| PostgreSQL | ACID compliance, data integrity for finance. |
| **Local Storage (Mobile)** | Hive / Isar | Speed, local encryption compliance. |
| **AI/ML Processing** | Python (TF/PyTorch) | Industry standard for ML development and inference. |
| **Security/Keys** | iOS Keychain / Android Keystore | Mandatory hardware-backed secure storage. |
| **CI/CD & Ops** | Docker, Kubernetes | Consistent deployment and service scaling. |

## Project Structure
PROJECT STRUCTURE DOCUMENT: FINSOR

1. OVERVIEW

This document outlines the definitive file and folder structure for the Finsor cross-platform personal finance application development. The structure is designed to support a high-performance Flutter codebase, facilitate clear separation of concerns (UI, Business Logic, Data/Persistence), and ensure scalability for future features like advanced AI integration and multi-currency support.

2. CORE DIRECTORY STRUCTURE

The primary structure resides within the root development directory:

FINSOR/
├── .vscode/             # VS Code specific configurations (settings.json, launch.json)
├── android/             # Native Android project files (for Flutter build)
├── ios/                 # Native iOS project files (for Flutter build)
├── assets/              # Static resources (images, fonts, locale files)
├── lib/                 # Main application source code (Flutter/Dart)
├── test/                # Unit, widget, and integration tests
├── web/                 # Web specific files (index.html, manifest, if necessary)
├── .analysis_options    # Dart analyzer configuration
├── .gitignore
├── pubspec.yaml         # Project dependencies and metadata
└── README.md            # Project introduction and setup guide

3. DETAILED lib/ DIRECTORY STRUCTURE

The lib/ directory follows a feature-sliced/layered architecture focusing on clarity and maintainability.

lib/
├── core/                # Foundational elements, shared utilities, and architectural constants
│   ├── constants/       # Global constants (e.g., API keys placeholders, initial setup data)
│   ├── navigation/      # App routing definitions, named routes, navigation services
│   ├── services/        # Low-level, platform-agnostic services (e.g., logging, secure storage wrappers)
│   ├── theming/         # Color schemes, typography definitions, app dimensions (inspired by 1Money aesthetic)
│   └── utils/           # General purpose helper functions (formatters, validators)
│
├── data/                # Data layer: Repositories, Data Sources (Local/Remote), Models
│   ├── models/          # Data structures (e.g., Transaction, Wallet, Budget, Account, AIInsight)
│   ├── sources/
│   │   ├── local/       # Database interaction (e.g., Hive/Sqflite wrappers, local encryption logic)
│   │   └── remote/      # (Placeholder for future bank sync providers or cloud sync APIs)
│   └── repositories/    # Interface implementations linking business logic to data sources
│
├── domain/              # Business logic layer: Entities, Use Cases (Interactors)
│   ├── entities/        # Core business objects (independent of implementation details)
│   └── usecases/        # Specific business operations (e.g., AddTransactionUseCase, GetBudgetPerformanceUseCase)
│
├── features/            # Modularization by functional area/feature (Recommended for growth)
│   ├── authentication/  # Login, Sign Up, Biometric setup
│   │   ├── presentation/ (UI & State Management)
│   │   └── data/
│   │
│   ├── dashboard/       # Main landing screen and quick overview
│   │   ├── presentation/
│   │   └── application/ (State management for dashboard data aggregation)
│   │
│   ├── transactions/    # CRUD operations for income/expenses, manual entry flow, receipt scanning integration
│   │   ├── presentation/
│   │   └── application/
│   │
│   ├── wallets/         # Wallet management (creation, selection, balance view)
│   │   ├── presentation/
│   │   └── application/
│   │
│   ├── budgeting/       # Advanced budgeting logic (Rollover, Envelopes, Goals)
│   │   ├── presentation/
│   │   └── application/
│   │
│   └── analytics/       # Reporting engines, trend calculations, complex queries
│       ├── presentation/
│       └── application/
│
├── services_integration/ # Cross-cutting concerns or platform-specific integrations
│   ├── ai_assistant/    # Interface and implementation for AI categorization and insights generation (Critical component)
│   ├── notifications/   # Local and remote notification handlers (budgets, alerts)
│   └── platform_interface/ # Abstractions for native features (Widgets, Secure Storage interaction)
│
└── main.dart            # Application entry point, dependency injection setup, theme initialization

4. FEATURE/MODULE STRUCTURE DETAIL

Each module within `features/` follows a standard presentation/application separation for clear separation of UI/state management from core business logic orchestration:

[FeatureName]/
├── presentation/         # UI components, screen widgets, state management (Provider/Riverpod/BLoC)
│   ├── pages/            # Full-screen views
│   ├── widgets/          # Reusable UI elements specific to this feature
│   └── state/            # State controllers/managers for the feature
│
└── application/          # Orchestrates use cases, handles feature-specific business flow
    ├── manager/          # (Optional) High-level service for coordinating multiple use cases within the feature
    └── usecase_calls/    # Direct calls to domain layer use cases (often thin wrappers)

5. ASSETS DIRECTORY

assets/
├── fonts/               # Custom typography (if required, prioritizing system fonts for minimalism)
├── images/
│   ├── icons/           # Core app icons (minimalist vector/SVG preferred)
│   └── illustrations/   # Used sparingly, for empty states or onboarding
└── l10n/                # Localization files (JSON or Arb for planned multi-language support)

6. TESTING DIRECTORY

test/
├── unit/                # Tests for Domain Use Cases and Data Repository implementations
├── widget/              # Tests for specific UI components and state changes
└── integration/         # End-to-end scenario tests

## Database Schema Design
SCHEMADESIGN: FINSOR DOCUMENT DATABASE SCHEMA V1.0

1. INTRODUCTION AND GOALS
This document outlines the proposed relational database schema design for Finsor, a personal finance tracking application. The design prioritizes performance, data integrity, flexibility to support advanced budgeting and AI features, and adherence to privacy constraints (local-first, encrypted storage).

2. CORE PRINCIPLES DRIVING SCHEMA DESIGN
*   **Performance Focus:** Optimized indexing and schema structure to support fast queries for dashboards and analytics (10k+ transactions).
*   **Budget Flexibility:** Schema must accommodate complex budgeting rules (rollover, envelope, goals).
*   **AI Readiness:** Data structure must allow for easy pattern extraction (time series, transaction attributes).
*   **Scalability:** Support for future features like multi-currency and shared accounts is considered.
*   **Data Integrity:** Strong foreign key constraints and clear ownership (User ID).

3. ENTITY RELATIONSHIP DIAGRAM (Conceptual Overview)
The core entities are Users, Wallets (Accounts), Transactions, Categories, Budgets, and AI/System Metadata.

4. DETAILED TABLE STRUCTURES

4.1. Users Table
Stores core user authentication and configuration data.

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| user_id | UUID | PK, NOT NULL | Unique identifier for the user. |
| email | VARCHAR(255) | UNIQUE, NULLABLE | User's email (for sync/auth, optional if local-only). |
| auth_provider_id | VARCHAR(255) | NULLABLE | ID from external auth provider. |
| created_at | TIMESTAMP | NOT NULL | Record creation time. |
| last_login | TIMESTAMP | NULLABLE | Last active time. |
| base_currency_code | CHAR(3) | NOT NULL, Default 'USD' | ISO 4217 code for user's base currency. |
| subscription_status | ENUM | NOT NULL, Default 'Free' | Free, Premium, Lifetime. |
| settings_json | JSONB | NULLABLE | Stores UI preferences, notifications settings. |

4.2. Wallets Table (Accounts)
Represents the user's financial accounts (Checking, Savings, Cash, Credit Card, etc.). Supports future multi-currency expansion.

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| wallet_id | UUID | PK, NOT NULL | Unique identifier for the wallet. |
| user_id | UUID | FK (Users), NOT NULL | Owner of the wallet. |
| name | VARCHAR(100) | NOT NULL | User-defined wallet name (e.g., "Main Checking"). |
| type | ENUM | NOT NULL | Asset, Liability, Cash, Investment (Future). |
| initial_balance | DECIMAL(19, 4) | NOT NULL | Balance when the wallet was created/imported. |
| current_balance | DECIMAL(19, 4) | NOT NULL | Calculated/current balance (optimally stored and updated via aggregates, but needed for instant display). |
| currency_code | CHAR(3) | NOT NULL | Currency specific to this wallet. |
| is_hidden | BOOLEAN | NOT NULL, Default FALSE | Hides from main dashboard view. |
| last_synced_at | TIMESTAMP | NULLABLE | Timestamp of last automated update (if automation is used). |

4.3. Categories Table
Defines the hierarchy for classification. Supports flexibility for user customization.

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| category_id | UUID | PK, NOT NULL | Unique identifier. |
| user_id | UUID | FK (Users), NOT NULL | Owner (null if system default category). |
| name | VARCHAR(100) | NOT NULL | Category name (e.g., Groceries, Rent). |
| type | ENUM | NOT NULL | Expense, Income, Transfer. |
| parent_category_id | UUID | FK (Categories), NULLABLE | For hierarchical grouping (e.g., Utilities -> Electricity). |
| icon_name | VARCHAR(50) | NULLABLE | Reference to the icon asset. |
| is_default | BOOLEAN | NOT NULL | True for system defaults. |

4.4. Transactions Table (The core tracking table - optimized for read speed)

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| transaction_id | UUID | PK, NOT NULL | Unique identifier. |
| user_id | UUID | FK (Users), NOT NULL | Owner. |
| wallet_id | UUID | FK (Wallets), NOT NULL | Source wallet. |
| category_id | UUID | FK (Categories), NULLABLE | Primary category (can be NULL for pending/unclassified transfers). |
| amount | DECIMAL(19, 4) | NOT NULL | Transaction amount (positive for income/deposits, negative for expenses/withdrawals in standard accounting practice, OR handled via separate type field). **Decision:** Store as absolute value, use `type` to denote flow. |
| absolute_amount | DECIMAL(19, 4) | NOT NULL | The monetary value exchanged. |
| flow_type | ENUM | NOT NULL | Expense, Income, Transfer. |
| date | DATE | NOT NULL | Date of transaction. |
| datetime | TIMESTAMP | NOT NULL | Precise time (for performance ordering). |
| description | VARCHAR(255) | NULLABLE | Short description/merchant name. |
| notes | TEXT | NULLABLE | Longer user notes. |
| merchant_name | VARCHAR(100) | NULLABLE | Extracted or standardized merchant name. |
| is_recurring | BOOLEAN | NOT NULL, Default FALSE | Flag for recurring transactions/bills. |
| source_metadata | JSONB | NULLABLE | Details from bank sync provider, or OCR scan data. |
| is_cleared | BOOLEAN | NOT NULL, Default TRUE | Manual transactions are cleared; automated may temporarily be pending. |

4.5. Transaction Splits Table
Supports splitting a single transaction across multiple categories (e.g., a single grocery run that includes "Groceries" and "Household supplies").

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| split_id | UUID | PK, NOT NULL | Unique identifier. |
| transaction_id | UUID | FK (Transactions), NOT NULL | The parent transaction. |
| category_id | UUID | FK (Categories), NOT NULL | The category this portion belongs to. |
| amount | DECIMAL(19, 4) | NOT NULL | The amount attributed to this category. |
| description_override | VARCHAR(255) | NULLABLE | Optional override description for the split item. |

4.6. Budgets Table
Designed to handle flexible budgeting requirements (Category, Rollover, Envelope).

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| budget_id | UUID | PK, NOT NULL | Unique identifier. |
| user_id | UUID | FK (Users), NOT NULL | Owner. |
| name | VARCHAR(100) | NOT NULL | Budget name (e.g., "Monthly Spending Limit"). |
| start_date | DATE | NOT NULL | Start of the budget period. |
| period_type | ENUM | NOT NULL | Monthly, Weekly, Custom, Goal_Based. |
| status | ENUM | NOT NULL | Active, Archived, Paused. |
| budget_type | ENUM | NOT NULL | Category_Limit, Envelope, Goal_Funding. |
| is_rollover_enabled | BOOLEAN | NOT NULL, Default FALSE | Controls rollover logic. |

4.7. Budget Allocations Table
Links budgets to specific constraints (categories or goals).

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| allocation_id | UUID | PK, NOT NULL | Unique identifier. |
| budget_id | UUID | FK (Budgets), NOT NULL | Parent budget. |
| category_id | UUID | FK (Categories), NULLABLE | The category this allocation targets (if budget_type is Category_Limit). |
| target_amount | DECIMAL(19, 4) | NOT NULL | The planned monetary allocation. |
| related_goal_id | UUID | FK (Goals), NULLABLE | Links to Goals if budget_type is Goal_Funding. |
| envelope_name | VARCHAR(100) | NULLABLE | Name used if this is an Envelope budget partition. |

4.8. Goals Table (Savings Goals)
Supports Goal-based saving/debt payoff.

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| goal_id | UUID | PK, NOT NULL | Unique identifier. |
| user_id | UUID | FK (Users), NOT NULL | Owner. |
| name | VARCHAR(100) | NOT NULL | Goal name (e.g., "New Car Deposit"). |
| target_amount | DECIMAL(19, 4) | NOT NULL | Final amount needed. |
| current_progress | DECIMAL(19, 4) | NOT NULL | Current funds allocated towards this goal. |
| target_date | DATE | NULLABLE | Desired completion date. |
| funding_category_id | UUID | FK (Categories), NULLABLE | Optional category used to track funding contributions. |
| status | ENUM | NOT NULL | In_Progress, Achieved, Abandoned. |

4.9. Recurring Schedule Table
Stores patterns for recurring transactions and bills (critical for AI forecasting).

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| schedule_id | UUID | PK, NOT NULL | Unique identifier. |
| user_id | UUID | FK (Users), NOT NULL | Owner. |
| template_transaction_id | UUID | FK (Transactions), NULLABLE | Link to the initial transaction that established the pattern. |
| description | VARCHAR(255) | NOT NULL | Recurring name. |
| amount | DECIMAL(19, 4) | NOT NULL | Expected amount. |
| category_id | UUID | FK (Categories), NOT NULL | Expected category. |
| recurrence_rule | VARCHAR(255) | NOT NULL | iCalendar (RRULE) format string or similar structure defining frequency. |
| next_due_date | DATE | NOT NULL | The next expected date. |
| type | ENUM | NOT NULL | Income, Expense, Transfer, Bill_Payment. |
| prediction_confidence | DECIMAL(3, 2) | NOT NULL | AI score of how certain this recurrence is (0.00 to 1.00). |

4.10. AI Insights & Audit Tables (Future State/Metadata)

4.10.1. AIPatterns Table (For AI Learning)
Stores generated insights derived from user behavior.

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| pattern_id | UUID | PK, NOT NULL | Unique identifier. |
| user_id | UUID | FK (Users), NOT NULL | Owner. |
| pattern_type | ENUM | NOT NULL | Spending_Spike, Monthly_Trend, Saving_Opportunity, Categorization_Correction. |
| generated_at | TIMESTAMP | NOT NULL | When the pattern was identified. |
| related_data_ids | JSONB | NULLABLE | Array of related transaction_ids or budget_ids. |
| insight_summary | TEXT | NOT NULL | Short, human-readable summary. |
| suggested_action | TEXT | NULLABLE | Actionable advice generated by AI. |
| is_actioned | BOOLEAN | NOT NULL, Default FALSE | Whether the user acted on the insight. |

4.10.2. Attachments Table
Supports linking receipts and documents to transactions.

| Field Name | Data Type | Constraints | Description |
|---|---|---|---|
| attachment_id | UUID | PK, NOT NULL | Unique identifier. |
| transaction_id | UUID | FK (Transactions), NOT NULL | The transaction this applies to. |
| file_uri | VARCHAR(512) | NOT NULL | Path/Reference to secure storage (local or cloud encrypted blob). |
| mime_type | VARCHAR(50) | NOT NULL | Type of file (e.g., image/jpeg). |
| storage_key | VARCHAR(255) | NOT NULL | Key used for encryption/retrieval. |

5. INDEXING STRATEGY (Performance Critical)
To meet performance benchmarks, the following indexes are mandatory:

*   **Transactions:** Index on `(user_id, datetime)` for dashboard loading and time-series analysis.
*   **Transactions:** Index on `(user_id, category_id, date)` for detailed category reports.
*   **Wallets:** Index on `user_id`.
*   **Budgets/Allocations:** Index on `(budget_id, category_id)`.
*   **Recurrence Schedule:** Index on `user_id` for quick prediction generation.

6. DATA SECURITY CONSIDERATIONS
All PII and financial data stored in the database (including transaction descriptions and amounts) must be encrypted at rest using AES-256 or equivalent, managed via device-specific keys (Keystore/Keychain) as per the privacy mandate. Synchronization mechanisms must enforce TLS 1.3 and server-side encryption.

## User Flow
USERFLOW DOCUMENTATION: FINSOR APP

VERSION: 1.0
DATE: OCTOBER 2023
AUTHORS: DOCUMENTATION TEAM

---
## 1. Introduction to User Flows

This document outlines the key user flows for the Finsor personal finance tracking application. Finsor aims to deliver a fast, intuitive, and intelligent experience, balancing core manual tracking capabilities with advanced AI-driven insights and flexible budgeting tools.

These flows focus on the primary mobile application experience (iOS/Android), reflecting the clean, minimal design constraints and performance benchmarks.

---
## 2. Core User Flows

### 2.1 Flow 1: First-Time User Onboarding & Setup

**Goal:** Get the user set up quickly, capturing essential starting data while highlighting Premium features (AI/Automation).

| Step | User Action | System Response/Screen | Wireframe Notes | Interaction Pattern |
| :--- | :--- | :--- | :--- | :--- |
| 1.0 | App Launch (Cold Start) | Splash screen (<2s load) followed by Welcome Carousel (3-4 slides summarizing core value: Track, Analyze, Save). | Minimal design, focused text, subtle background animation or gradient. | Swipe navigation, Skip option visible. |
| 1.1 | Completes Carousel/Taps "Get Started" | Account Creation/Login screen (Email/Password, Google/Apple SSO). | Standard authentication forms. Emphasis on privacy notice link. | SSO prioritized for speed. |
| 1.2 | Creates Account | Initial Setup Wizard: Step 1/3 - Base Currency Selection. | Single selection list of major currencies. | Quick selection, clear confirmation. |
| 1.3 | Selects Currency | Initial Setup Wizard: Step 2/3 - Initial Wallet Setup. User can set up a primary Wallet (e.g., Checking, Cash). | Prompt to name wallet, set initial balance (optional). | Manual setup focus; subtle hint about future bank sync (Premium). |
| 1.4 | Sets Initial Balance | Initial Setup Wizard: Step 3/3 - Budget Introduction. Brief explanation of basic budgeting vs. advanced options. | Simple call-to-action: "Set a Quick Budget" or "Skip for Now." | Encourages immediate engagement with a core feature. |
| 1.5 | Taps "Finish Setup" | Navigates to the **Main Dashboard**. | Dashboard loads (<1s). Displays zero/initial balance. AI Assistant suggests first action (e.g., "Add your first transaction"). | Immediate access to core functionality. |

---
### 2.2 Flow 2: Rapid Manual Transaction Entry (Expense)

**Goal:** Log an expense in the fewest possible taps, prioritizing speed and accurate categorization (leveraging AI learning). (Target: <5 seconds total)

| Step | User Action | System Response/Screen | Wireframe Notes | Interaction Pattern |
| :--- | :--- | :--- | :--- | :--- |
| 2.0 | Accesses App | Dashboard loaded (or via Biometric Unlock). | Primary Floating Action Button (FAB) labeled "+" is prominently displayed. | High visibility, single point of entry. |
| 2.1 | Taps FAB (+) | Transaction Entry Modal opens, defaulting to Expense mode. Focus immediately on the Amount field. | Large, clean numeric keypad appears overlaid. Currency symbol fixed. | Optimized for quick numeric input. |
| 2.2 | Enters Amount (e.g., 15.50) | System automatically transitions focus or waits for user confirmation (e.g., next field tap). | Input field updates instantly (<200ms). | Direct input method. |
| 2.3 | Enters Description (Optional) | User types "Coffee with Sarah." | Standard text input field. | Basic text entry. |
| 2.4 | Taps Category Field | Category Picker screen appears. Displays frequently used categories first, then AI-suggested based on keywords ("Coffee" -> Food/Drink). | Scrollable list with category icons. Suggested category is highlighted. | AI Suggestion significantly reduces selection time. |
| 2.5 | Selects Category | Returns to Entry Modal. Category is populated. Focus moves to Date/Wallet selector. | Displays chosen category name/icon clearly. | Confirm selection. |
| 2.6 | Taps "Save" | Transaction is saved, modal closes. User returns to Dashboard. | Dashboard refreshes instantly. New transaction appears at the top of the recent list. Analytics/Budget indicators update (<500ms). | Seamless return to tracking view. |

*Note: If the user enables Receipt Scanning (Advanced Feature), Step 2.1 redirects to the camera, and the system attempts OCR extraction, pre-filling Amount, Merchant, and suggesting Category.*

---
### 2.3 Flow 3: Reviewing AI-Powered Spending Alert

**Goal:** User interacts with an automated alert, understands the insight, and takes corrective action (e.g., adjusting a budget).

| Step | User Action | System Response/Screen | Wireframe Notes | Interaction Pattern |
| :--- | :--- | :--- | :--- | :--- |
| 3.0 | Receives Push Notification | System alert: "Heads up! Your Dining Out spending is 40% higher than average this week. Pace suggests you'll exceed your budget by $50." | Clear, non-alarming language. Deep link to the relevant Insight/Budget. | Notification driven interaction. |
| 3.1 | Taps Notification | Opens the **Insights/Alerts View**. The specific alert card is highlighted. | Dedicated view summarizing the detected trend (e.g., Spike in Restaurant Category, identified merchants). | Focuses attention on the issue. |
| 3.2 | Reviews Insight Details | User taps "View Details" on the spike analysis. | Displays a mini-chart comparing current period spending vs. historical average for that category. Shows contributing transactions. | Visual clarity supporting the AI finding. |
| 3.3 | Decides Action | User taps the linked action: "Adjust Budget for Dining Out." | Navigates directly to the specific Category Budget setup screen. | Contextual action linking. |
| 3.4 | Adjusts Budget | User modifies the monthly budget limit from $200 to $250, or enables a **Rollover Budget** setting for this category. | Slider or numeric input for adjustment. Real-time feedback on projected impact (if possible). | Advanced Budgeting feature utilized. |
| 3.5 | Confirms Change | Taps "Apply Changes." | Returns to the Insights View, showing the updated budget status and a confirmation toast. | Confirmation loop completion. |

---
### 2.4 Flow 4: Setting Up an Advanced Goal-Based Savings Budget

**Goal:** A Budget-Conscious or Financially Curious user sets up a specific savings goal using the advanced budgeting tools.

| Step | User Action | System Response/Screen | Wireframe Notes | Interaction Pattern |
| :--- | :--- | :--- | :--- | :--- |
| 4.0 | Navigates to Budget Screen | User taps the "Budgets" tab from the main navigation. | Overview of active category budgets and existing goals. FAB (+) is present. | Standard navigation path. |
| 4.1 | Taps FAB (+) and Selects "New Goal" | Goal Creation Wizard initiates. Step 1/3: Define Goal Target. | Input field for Goal Name (e.g., "New Laptop"), Target Amount ($1500), and Deadline (Date Picker). | Structured step-by-step input. |
| 4.2 | Enters Goal Details | System calculates required monthly contribution based on target/timeline. User can accept or modify contribution frequency/amount. | Displays calculated required funding pace prominently. | Income-aware planning integration hint. |
| 4.3 | Moves to Funding Source | Step 2/3: Link Funding Source. User selects the Wallet/Account that will feed the Goal. | Selection list of existing Wallets. Prompt regarding "Envelope Allocation." | Links funding mechanism. |
| 4.4 | Defines Rules (Optional) | Step 3/3: Advanced Rules. User opts to "Only fund if Spending Pace is on track" (Rule/Exception). | Toggle switches for common goal rules. | Advanced Budgeting flexibility exposed. |
| 4.5 | Finalizes Goal | Taps "Create Goal." | Returns to Budget Overview. The new Goal appears with a dedicated progress bar visualization (Target vs. Funded). | Visual confirmation of progress tracking. |

---
## 3. Secondary User Flows (Key Interactions)

### 3.1 Flow: Data Synchronization Check (Offline Handling)

1.  **Offline State:** User opens app while offline. Dashboard displays transaction data as of the last sync. A subtle, persistent banner/icon indicates "Offline Mode."
2.  **New Entry:** User manually adds a transaction. It is saved instantly to local storage. The entry shows a temporary 'Pending Sync' marker (e.g., a small cloud with a diagonal line).
3.  **Reconnection:** App detects network availability.
4.  **Sync Process:** A brief background sync initiates (handling local changes, applying automated imports if Premium is active). The 'Pending Sync' marker disappears upon successful merge.
5.  **Performance Note:** All offline operations must adhere to the sub-500ms write performance target.

### 3.2 Flow: Accessing Advanced Analytics (Premium Feature Demo)

1.  User navigates to the "Analytics" tab.
2.  The main view displays basic charts (Income/Expense summary, Top Categories).
3.  User attempts to select "Net Worth Tracking" or "Category Heatmap" from the sub-navigation.
4.  A non-intrusive modal overlay appears, showcasing a blurred/watermarked preview of the advanced chart (e.g., Heatmap).
5.  The modal clearly states: "Unlock deep trend analysis and Net Worth tracking with Finsor Premium." Includes clear pricing/subscription CTA.
6.  User can close the modal to return to basic analytics, maintaining focus on core free features while showcasing Premium value.

### 3.3 Flow: Customizing Transaction Categorization (AI Learning)

1.  User reviews a transaction categorized automatically by the AI (e.g., "Amazon Purchase" auto-categorized as "Shopping").
2.  User taps the transaction and selects "Edit Category."
3.  User manually changes the category to "Hobby Supplies."
4.  A confirmation prompt appears: "Learn from this change? Finsor will use this correction for future 'Amazon Purchase' transactions." (Opt-in learning).
5.  User confirms. The system logs the user correction, ensuring the AI model adapts for future consistency, satisfying the "learns from user corrections" requirement.

## Styling Guidelines
FINSOR DOCUMENT: STYLING GUIDELINES

1. INTRODUCTION

1.1 Purpose
This document outlines the visual styling and interface principles for the Finsor cross-platform personal finance application. Adherence to these guidelines ensures consistency, speed, and clarity across iOS, Android, and future web platforms, reinforcing Finsor's commitment to a minimal, professional, and intuitive user experience.

1.2 Core Design Philosophy
Finsor's visual language prioritizes:
*   **Clarity and Readability:** Financial data must be consumed quickly and accurately.
*   **Minimalism and Calm:** A restrained aesthetic avoids visual noise, promoting focus on the numbers. Inspired by 1Money.
*   **Purposeful Polish:** Every visual element—color, spacing, animation—must serve a functional purpose.
*   **Speed Perception:** Design choices enhance the feeling of instantaneous performance (under 200ms UI response goal).

2. COLOR PALETTE

The palette is neutral-dominant, using accents strictly for status, primary actions, and categorization.

2.1 Primary Colors (Neutrals)
These form the backbone of the interface, ensuring excellent contrast and readability.

| Name | Usage | Hex/RGBA | Notes |
| :--- | :--- | :--- | :--- |
| Background - Primary | Main screen background, main content areas. | #FFFFFF (White) / #121212 (Dark Mode Equivalent) | Use generous negative space. |
| Background - Secondary | Cards, modals, elevated surfaces (light mode only). | #F5F5F5 | Provides subtle depth. |
| Surface - Dark Mode | Primary background in dark mode. | #121212 | Deep, true black preferred for OLED efficiency and focus. |
| Surface - Dark Mode Elevated | Cards/modals in dark mode. | #1E1E1E | Slight offset from primary dark surface. |
| Text - Primary | Main headers, body text. | #1A1A1A (Near Black) | High contrast against white background. |
| Text - Secondary | Subtitles, metadata, helper text, disabled states. | #6B7280 (Gray 500 equivalent) | Lower emphasis. |
| Text - White/Inverse | Text used on dark backgrounds or accent colors. | #FFFFFF | |

2.2 Accent & Status Colors
Accents are used sparingly to denote financial states, primary CTAs, and category groupings.

| Name | Usage | Hex/RGBA | Meaning/Context |
| :--- | :--- | :--- | :--- |
| Action - Primary | Main Call-to-Actions (CTA), active tabs, confirmation buttons. | #007AFF (Standard iOS Blue/Primary Accent) | Trustworthy, forward momentum. |
| Status - Positive (Income/Savings) | Income entries, savings goal progress, positive budget status. | #34C759 (Standard Green) | Growth, gain, on track. |
| Status - Negative (Expense/Over-budget) | Expense entries, over-budget warnings, critical alerts. | #FF3B30 (Standard Red) | Warning, spending, loss. |
| Status - Neutral/Warning | Pending transactions, neutral balance indicators, minor alerts. | #FF9500 (Standard Orange) | Caution, attention required, waiting. |
| Category Palette | Assigned dynamically to expense categories (Max 12 core colors needed initially). | HSL rotation based on primary accent. | Use vibrant but legible colors. Ensure sufficient contrast against white/dark backgrounds. |

2.3 Transparency and Opacity
Opacity should be used to create subtle hierarchy within dark mode backgrounds or for faint divider lines (e.g., 12% opacity of primary text color for light dividers).

3. TYPOGRAPHY

Typography must be clean, highly legible across different screen sizes, and consistent across iOS and Android. The use of system default fonts (San Francisco for iOS, Roboto for Android) is preferred for performance and platform familiarity, unless a unified custom font offers significant measurable benefits.

3.1 Font Selection
*   **Recommendation:** Use the system UI font stack for optimal rendering and performance: `SF Pro Display, SF Pro Text, Roboto, system-ui`.

3.2 Font Sizing Scale (Example Scale - Adjust for specific Flutter/Native implementation)

| Element | Target Size (pt/sp) | Weight | Usage Context |
| :--- | :--- | :--- | :--- |
| H1 - Screen Title | 34 | Bold | Primary dashboard titles (e.g., "Overview") |
| H2 - Section Header | 28 | Semibold | Major analytic sections. |
| H3 - Card Title | 20 | Medium | Title within cards or modals. |
| Body - Primary | 16 | Regular | Main descriptive text, transaction descriptions. |
| Body - Secondary | 14 | Regular | Metadata, minor labels. |
| Label - Button/CTA | 16 | Semibold | Primary actions. |
| Small - Balance/Amount | 48 - 64 (Display dependent) | Bold/Heavy | Primary displayed balances. Needs excellent legibility. |
| Small - Budget Meter | 12 | Medium | Progress bar labels, pace indicators. |

3.3 Number Formatting
Financial figures must use locale-aware formatting (commas/dots, currency symbols). Amounts should generally align right, especially in lists and tables, to facilitate comparison. Negative values (expenses) should use the Status - Negative color or be prefixed with a minus sign (–) without parentheses, unless user locale dictates otherwise.

4. UI/UX PRINCIPLES

4.1 Layout and Spacing
*   **Grid System:** Adopt an 8pt grid system for consistent vertical and horizontal rhythm across all elements (padding, margins, component heights).
*   **Negative Space:** Generous use of white/dark space is crucial to achieving the calm, minimal aesthetic and improving data comprehension. Avoid cramming information.
*   **Card Design:** Information chunks (budgets, wallet summaries, insights) should reside in distinct cards. Cards should have subtle elevation (light mode) or defined borders/background contrast (dark mode).

4.2 Interaction Design
*   **Speed & Responsiveness:** All primary inputs (e.g., Add Transaction) must feel instant (<200ms feedback). Utilize skeleton loaders or shimmer effects for content that loads asynchronously (e.g., Analytics reports).
*   **Gestures:** Use standard platform gestures (swipe navigation, pull-to-refresh). Limit non-standard gestures to avoid confusing new users.
*   **Haptics:** Subtle haptic feedback should be used judiciously for critical actions (e.g., successfully saving a large transaction, biometric unlock).

4.3 Data Visualization (Analytics)
*   **Clarity over Complexity:** Visualizations must instantly convey meaning. Avoid 3D charts or overly complex layered graphs.
*   **Color Use in Charts:** Use the Accent Colors consistently. Income should align with Status - Positive; Expenses with Status - Negative. Category colors must be consistent across all related charts (e.g., Groceries is always the same color).
*   **Budget Visualization:** Budget feedback must be immediate:
    *   **Pace Line:** A visual indication showing if current spending rate is sustainable for the period.
    *   **Remaining Amount:** Displayed prominently in Body - Primary text size.
    *   **Status Indicators:** Small, clear icons or color chips showing "On Track," "Warning," or "Over Budget."

4.4 Iconography
*   **Style:** Line-based, minimalist, and highly recognizable icons (e.g., Feather or Material Icons equivalents).
*   **Weight:** Use thin or regular stroke weights that harmonize with the typography.
*   **Consistency:** Icons used for categories, navigation, and status must share a unified visual language.

4.5 AI Assistant Integration (Critical Feature)
The AI Assistant interface must feel integrated, not bolted on.
*   **Presentation:** Insights and suggestions should appear in clearly defined, non-intrusive cards or modal notifications using the Primary Action color for emphasis, ensuring the user knows this is actionable feedback.
*   **Language:** The tone is helpful, professional, and human-readable—avoiding technical jargon, aligning with the goal of simplicity for everyday users.

5. PLATFORM CONSIDERATIONS

While Flutter aims for unified rendering, platform idioms must be respected where necessary for user comfort.

5.1 Mobile (iOS & Android)
*   **Navigation:** Use standard bottom tab navigation for primary flows (Dashboard, Transactions, Budgets, Insights).
*   **Transaction Entry:** The primary Floating Action Button (FAB) for adding transactions should be prominent, using the Action - Primary color, and accessible with one thumb.
*   **Security Access:** Biometric prompts must adhere strictly to native OS guidelines for seamless integration.

5.2 Widgets (Home Screen)
Widgets must adhere to the principle of instant glanceability. Use high-contrast text against the selected background color (light/dark) and prioritize displaying the most critical data points (e.g., Current Balance, % of Budget Remaining).

6. ACCESSIBILITY CONSIDERATIONS

*   **Contrast Ratios:** Maintain AA compliance (4.5:1) for all text/background combinations, especially for Status colors used against white/black.
*   **Scalability:** Text sizes must respect OS dynamic type settings to allow users to scale the interface comfortably.
*   **Tap Targets:** All interactive elements (buttons, list items) must have a minimum accessible tap target size of 44x44dp/pt.
