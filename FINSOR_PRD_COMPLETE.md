# FINSOR: COMPLETE PRODUCT REQUIREMENTS DOCUMENT

**Version:** 1.0  
**Last Updated:** February 2026  
**Status:** Production-Ready  
**Document Owner:** Product Team

---

## Table of Contents

1. [Product Context](#1-product-context)
2. [Product Goals](#2-product-goals)
3. [User Personas & Use Cases](#3-user-personas--use-cases)
4. [Core Features](#4-core-features)
5. [Analytics & Insights](#5-analytics--insights)
6. [AI Assistant](#6-ai-assistant)
7. [UX/UI System](#7-uxui-system)
8. [Technical Architecture](#8-technical-architecture)
9. [Security & Privacy](#9-security--privacy)
10. [Settings & Customization](#10-settings--customization)
11. [Edge Cases & Failure Modes](#11-edge-cases--failure-modes)
12. [QA & Testing Requirements](#12-qa--testing-requirements)
13. [Release Plan](#13-release-plan)
14. [Metrics & Success Criteria](#14-metrics--success-criteria)
15. [Future Extensions](#15-future-extensions)

---

# 1. PRODUCT CONTEXT

## 1.1 Product Identity

**Product Name:** Finsor  
**Tagline:** "Clarity for your finances"  
**Product Type:** Cross-platform mobile application (iOS & Android)  
**Framework:** Flutter (Dart)

## 1.2 Core Idea

Finsor is a next-generation personal finance tracking and analysis application that combines:

- **Manual + Semi-Automatic Tracking:** Users maintain control while AI reduces friction
- **Clean, Minimal UI:** Inspired by 1Money's simplicity, designed for focus
- **Deep Analytics:** Beyond basic charts—trend analysis, velocity tracking, behavioral insights
- **Smart AI Assistant:** Not a gimmick, but a genuinely useful financial companion
- **Behavioral Focus:** Understanding *why* you spend, not just *what* you spend

## 1.3 Target User Segments

| Segment | Age Range | Characteristics | Primary Need |
|---------|-----------|-----------------|--------------|
| Young Professionals | 22-30 | First job, building habits | Simple tracking, awareness |
| Budget-Conscious Adults | 28-45 | Family, mortgage, goals | Budget control, planning |
| Financially Curious | 25-40 | Data-driven, analytical | Deep insights, patterns |
| ADHD/Low-Friction Users | Any | Need simplicity | Quick entry, visual clarity |
| Side Hustlers | 25-40 | Multiple income streams | Multi-wallet, categorization |

## 1.4 Market Opportunity

**Problem Statement:**  
Most finance apps fall into two extremes:
1. **Too simple:** Basic tracking with no insights (Notes app level)
2. **Too complex:** Enterprise-level features that overwhelm (Quicken, enterprise tools)

**Finsor's Position:**  
The "Goldilocks zone"—powerful enough for serious tracking, simple enough for daily use.

## 1.5 Competitive Analysis

| App | Strengths | Weaknesses | Finsor Advantage |
|-----|-----------|------------|------------------|
| **1Money** | Beautiful UI, fast | Limited analytics, no AI | AI + deeper insights |
| **Mint** | Bank sync, comprehensive | Bloated, US-focused, ads | Clean UI, global, privacy |
| **YNAB** | Philosophy, budgeting | Steep learning curve, expensive | Simpler onboarding, AI guidance |
| **Money Manager** | Free, feature-rich | Dated UI, no AI | Modern design, intelligence |
| **Wallet by BudgetBakers** | Bank sync, planning | Complex, premium-heavy | Balanced free tier |

## 1.6 Value Proposition

**For users who want financial clarity without complexity:**

> Finsor gives you the insights of a financial advisor and the simplicity of a notes app. Track in seconds, understand in minutes.

**Key Value Drivers:**
1. **Speed:** Add a transaction in under 5 seconds
2. **Clarity:** Know exactly where your money goes
3. **Intelligence:** AI that actually helps, not just impresses
4. **Privacy:** Your data stays yours

---

# 2. PRODUCT GOALS

## 2.1 Primary Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| **Financial Clarity** | Users understand their spending patterns within 7 days of use | 70% report improved awareness (survey) |
| **Frictionless Entry** | Transaction entry feels instant | <5 seconds for manual entry |
| **Actionable Insights** | AI provides useful, specific recommendations | 30% of insights acted upon |
| **Habit Formation** | Users return daily to track | DAU/MAU > 25% |

## 2.2 Secondary Goals

| Goal | Description | Success Metric |
|------|-------------|----------------|
| **Premium Conversion** | Free users see enough value to upgrade | 3-5% conversion rate |
| **User Retention** | Users stay engaged long-term | 90-day retention > 25% |
| **Word of Mouth** | Users recommend to others | NPS > 50 |
| **Platform Excellence** | High store ratings | App Store/Play Store > 4.5 |

## 2.3 Non-Goals (Explicit Scope Boundaries)

Finsor will **NOT** provide:

| Non-Goal | Reason |
|----------|--------|
| **Investment Advice** | Regulatory complexity, liability risk |
| **Tax Filing/Preparation** | Requires certified expertise, regional complexity |
| **Cryptocurrency Tracking** | Volatile space, specialized requirements |
| **Stock Trading** | Different product category entirely |
| **Peer-to-Peer Payments** | Requires banking licenses, security complexity |
| **Social Features** | Spending comparisons create negative psychology |
| **Bill Negotiation** | Requires third-party integrations, legal exposure |
| **Credit Score Management** | Regional limitations, data partnerships |

## 2.4 Differentiators

### vs. Generic Trackers
- AI-powered categorization that learns
- Behavioral insights, not just numbers
- Premium analytics rivaling expensive tools

### vs. Bank Apps
- Works across all accounts
- Consistent experience regardless of bank
- Privacy-first (no data selling)

### vs. Complex Financial Tools
- 5-minute onboarding
- No accounting knowledge required
- Beautiful, calming interface

## 2.5 Long-Term Vision (12-24 Months)

```
Phase 1 (Launch)         Phase 2 (6 months)       Phase 3 (12-24 months)
┌─────────────────┐     ┌─────────────────┐      ┌─────────────────┐
│ Manual Tracking │ ──► │ Bank Sync       │ ──►  │ Family Sharing  │
│ Basic AI        │     │ Advanced AI     │      │ Investment View │
│ Local Storage   │     │ Cloud Sync      │      │ Tax Reports     │
│ Core Budgets    │     │ Widgets         │      │ API Access      │
└─────────────────┘     └─────────────────┘      └─────────────────┘
```

**12-Month Targets:**
- Bank sync integration (Plaid, regional providers)
- Home screen widgets (iOS/Android)
- Receipt OCR scanning
- Shared wallets (couples/family)

**24-Month Targets:**
- Investment tracking (manual entry first)
- Net worth dashboard
- Tax report generation
- Multi-device real-time sync

---

# 3. USER PERSONAS & USE CASES

## 3.1 Persona: The Daily Tracker (Alex)

### Demographics
- **Age:** 24
- **Occupation:** Junior Software Developer
- **Income:** $55,000/year
- **Location:** Urban apartment
- **Tech Comfort:** High

### Goals
- Build awareness of spending habits
- Stop wondering "where did my money go?"
- Save for a trip to Japan ($5,000)
- Quick logging that doesn't interrupt life

### Pain Points
- Forgets to track if app is slow
- Gets overwhelmed by complex budgeting
- Previous apps felt like homework
- Wants visual feedback, not spreadsheets

### Daily Flow
```
Morning:    Coffee purchase → Quick add ($5.50, Food)
Lunch:      Split bill with coworker → Quick add with note
Evening:    Check daily spending total on dashboard
Weekly:     Review spending breakdown, adjust behavior
Monthly:    Check progress toward Japan savings goal
```

### Success Metrics
- Tracks 80%+ of transactions
- Opens app daily
- Achieves savings goal within 12 months
- Recommends to 2+ friends

### Feature Priorities
1. Quick transaction entry (P0)
2. Visual spending summary (P0)
3. Savings goals (P1)
4. AI suggestions (P1)

---

## 3.2 Persona: The Power User (Sarah)

### Demographics
- **Age:** 35
- **Occupation:** Marketing Manager
- **Income:** $95,000/year + freelance
- **Location:** Suburban home
- **Tech Comfort:** High
- **Family:** Married, 1 child

### Goals
- Track personal and freelance income separately
- Manage multiple accounts (checking, savings, credit cards)
- Strict envelope budgeting for discretionary spending
- Export data for tax purposes

### Pain Points
- Needs multi-wallet support
- Wants detailed exports (CSV, PDF)
- Previous apps couldn't handle complexity
- Hates apps that feel "dumbed down"

### Weekly Flow
```
Daily:      Log 3-5 transactions across wallets
            Review budget pace indicators
Weekly:     Analyze category breakdown
            Transfer between envelopes
Monthly:    Review all budgets vs actuals
            Export freelance expenses for records
Quarterly:  Generate spending reports
            Adjust annual budget allocations
```

### Success Metrics
- Uses 5+ wallets actively
- Exports data monthly
- Budget adherence > 90%
- Uses envelope budgeting feature

### Feature Priorities
1. Multi-wallet management (P0)
2. Envelope budgeting (P1)
3. Data export (P1)
4. Advanced analytics (P1)

---

## 3.3 Persona: The Casual Tracker (Mike)

### Demographics
- **Age:** 28
- **Occupation:** Graphic Designer
- **Income:** $65,000/year
- **Location:** Urban
- **Tech Comfort:** Medium

### Goals
- General awareness of spending
- Not looking to be "strict"
- Wants occasional insights
- Minimal time investment

### Pain Points
- Doesn't want daily commitment
- Gets annoyed by too many notifications
- Previous apps made him feel guilty
- Wants "just enough" tracking

### Monthly Flow
```
Week 1:     Log major purchases only (>$50)
Week 2:     Ignore app mostly
Week 3:     Open app, see summary, feel informed
Week 4:     Quick review before paycheck
```

### Success Metrics
- Opens app 4-8x per month
- Logs 10+ transactions monthly
- Reads AI summary when available
- Doesn't uninstall

### Feature Priorities
1. Monthly summary view (P0)
2. Smart notifications (not spammy) (P1)
3. Trend insights (P1)
4. Passive tracking (bank sync, future) (P2)

---

## 3.4 Persona: The Budget-Focused User (Lisa)

### Demographics
- **Age:** 42
- **Occupation:** School Teacher
- **Income:** $52,000/year
- **Location:** Suburban
- **Family:** Single parent, 2 kids
- **Tech Comfort:** Medium

### Goals
- Stick to strict monthly budget
- Never overdraft again
- Save for kids' college fund
- Get alerts before overspending

### Pain Points
- Money feels unpredictable
- Needs proactive warnings
- Previous apps only showed problems after the fact
- Wants simple, not "financial advisor" complex

### Daily Flow
```
Morning:    Check remaining budget before day starts
Day:        Log every purchase immediately
            Get alert if approaching category limit
Evening:    Review daily total, feel in control
Weekly:     Adjust category allocations if needed
Monthly:    Celebrate staying on budget (or analyze misses)
```

### Success Metrics
- Zero overdrafts
- Budget adherence > 95%
- Uses alert system actively
- Achieves savings goal

### Feature Priorities
1. Budget alerts (50%, 80%, 100%) (P0)
2. Real-time budget tracking (P0)
3. Goal savings (P1)
4. Spending pace indicator (P1)

---

## 3.5 Persona: The Insight-Driven User (James)

### Demographics
- **Age:** 31
- **Occupation:** Data Analyst
- **Income:** $85,000/year
- **Location:** Urban
- **Tech Comfort:** Very High

### Goals
- Understand spending patterns deeply
- Use AI to find optimization opportunities
- Make data-driven financial decisions
- Experiment with different budgeting strategies

### Pain Points
- Most apps' "insights" are shallow
- Wants to ask questions, not just view dashboards
- Needs pattern detection, anomaly alerts
- Previous apps felt like they weren't learning

### Weekly Flow
```
Daily:      Quick transaction logging
            Scan AI insights card on dashboard
Weekly:     Deep dive into analytics
            Ask AI specific questions
            Compare week-over-week trends
Monthly:    Review spending velocity
            Analyze category heatmap
            Test new budget strategies
Quarterly:  Year-over-year comparison
            Adjust financial strategy based on patterns
```

### Success Metrics
- Uses AI chat weekly
- Engages with 5+ analytics views
- Acts on AI recommendations
- Subscription retention > 1 year

### Feature Priorities
1. AI Assistant (full capabilities) (P0)
2. Advanced analytics (P0)
3. Pattern detection (P1)
4. Custom date range analysis (P1)

---

## 3.6 Use Case Matrix

| Use Case | Alex | Sarah | Mike | Lisa | James |
|----------|------|-------|------|------|-------|
| Quick transaction entry | ★★★ | ★★☆ | ★★☆ | ★★★ | ★★☆ |
| Multi-wallet management | ★☆☆ | ★★★ | ★☆☆ | ★★☆ | ★★☆ |
| Budget tracking | ★★☆ | ★★★ | ★☆☆ | ★★★ | ★★☆ |
| AI insights | ★★☆ | ★★☆ | ★★☆ | ★☆☆ | ★★★ |
| Advanced analytics | ★☆☆ | ★★☆ | ★☆☆ | ★☆☆ | ★★★ |
| Data export | ★☆☆ | ★★★ | ★☆☆ | ★☆☆ | ★★☆ |
| Goal savings | ★★★ | ★★☆ | ★☆☆ | ★★★ | ★★☆ |
| Envelope budgeting | ★☆☆ | ★★★ | ★☆☆ | ★★☆ | ★☆☆ |

**Legend:** ★★★ Critical | ★★☆ Important | ★☆☆ Nice-to-have

---

# 4. CORE FEATURES

## 4.1 Wallets & Accounts

### 4.1.1 Overview

Wallets represent the user's financial accounts—where money is stored and spent from. Finsor supports multiple wallets to reflect real-world account diversity.

### 4.1.2 Wallet Types

| Type | Description | Balance Behavior | Example |
|------|-------------|------------------|---------|
| **Cash** | Physical currency | Always positive (no overdraft) | Wallet, Cash at home |
| **Debit** | Bank debit account | Can go negative (overdraft) | Checking account |
| **Credit** | Credit card | Balance represents debt (negative = owed) | Visa, Mastercard |
| **Savings** | Savings account | Always positive, typically no spending | Emergency fund |
| **Investment** | Investment accounts (future) | Asset value tracking | Brokerage (Phase 2) |

### 4.1.3 Wallet Properties

```
Wallet {
  id: UUID
  name: String (max 50 chars)
  type: WalletType
  currency: ISO 4217 code (e.g., "USD", "EUR")
  initialBalance: Decimal
  currentBalance: Decimal (calculated)
  icon: IconReference
  color: HexColor
  isArchived: Boolean
  isHidden: Boolean (hide from dashboard totals)
  sortOrder: Integer
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

### 4.1.4 Multi-Currency Support

**Currency Handling Rules:**
1. Each wallet has a single currency
2. User sets a "base currency" for reporting
3. Transactions are stored in wallet's currency
4. Analytics convert to base currency using daily rates
5. Exchange rates fetched daily from reliable API (e.g., exchangerate-api.com)

**Conversion Display:**
```
Transaction: €50.00 (EUR wallet)
Dashboard shows: €50.00 (~$54.25 USD)
Analytics aggregate: $54.25 (converted at transaction date rate)
```

### 4.1.5 Transfers Between Wallets

**Transfer Logic:**
- A transfer creates TWO linked transactions:
  - Outgoing from source wallet (expense-like)
  - Incoming to destination wallet (income-like)
- Both transactions share a `transferId` for linking
- Transfers are excluded from spending analytics by default

**Cross-Currency Transfers:**
```
Transfer $100 USD → €92 EUR
- Source: -$100 (USD wallet)
- Destination: +€92 (EUR wallet)
- Exchange rate recorded: 0.92
- User can manually adjust received amount
```

### 4.1.6 Balance Calculations

**Current Balance Formula:**
```
currentBalance = initialBalance 
                 + SUM(income transactions)
                 - SUM(expense transactions)
                 + SUM(incoming transfers)
                 - SUM(outgoing transfers)
```

**Balance Integrity:**
- Recalculated on every transaction change
- Checksum validation on app start
- Mismatch triggers recalculation + user notification

### 4.1.7 Edge Cases

| Scenario | Behavior |
|----------|----------|
| **Negative cash balance** | Warning shown, allowed (user may have tracking lag) |
| **Credit card positive balance** | Allowed (overpayment/credits exist) |
| **Wallet deletion with transactions** | Archive only, never hard delete |
| **Currency change on wallet** | Blocked if transactions exist |
| **Duplicate wallet names** | Allowed (user might have multiple "Cash") |
| **Zero initial balance** | Allowed and common |

---

## 4.2 Transactions

### 4.2.1 Transaction Types

| Type | Description | Amount Sign | Affects Budget |
|------|-------------|-------------|----------------|
| **Expense** | Money spent | Negative (deducted) | Yes |
| **Income** | Money received | Positive (added) | No (unless income budget) |
| **Transfer** | Movement between wallets | Neutral (linked pair) | No |

### 4.2.2 Transaction Properties

```
Transaction {
  id: UUID
  type: TransactionType (expense/income/transfer)
  amount: Decimal (always positive, type determines sign)
  walletId: UUID
  toWalletId: UUID? (for transfers only)
  categoryId: UUID
  description: String? (max 200 chars)
  notes: String? (max 1000 chars)
  date: Date
  time: Time?
  
  // Recurring support
  isRecurring: Boolean
  recurringPattern: String? (RRULE format)
  recurringParentId: UUID? (links instances to template)
  
  // State tracking
  state: TransactionState (pending/cleared/reconciled)
  
  // Metadata
  merchantName: String? (extracted or manual)
  location: GeoPoint? (optional, future)
  attachmentIds: UUID[] (receipts, future)
  tags: String[] (custom labels)
  
  // AI/System
  aiCategoryConfidence: Float? (0.0-1.0)
  aiSuggested: Boolean
  
  // Audit
  createdAt: Timestamp
  updatedAt: Timestamp
  createdBy: DeviceId
}
```

### 4.2.3 Manual Entry Flow

**Optimized for speed (target: <5 seconds)**

```
Step 1: Tap FAB (+)
        → Modal opens, focus on amount field
        → Numeric keypad appears
        
Step 2: Enter amount (e.g., "12.50")
        → Amount displays with currency symbol
        → "Next" or tap category field
        
Step 3: Select category
        → Shows recent/frequent categories first
        → AI suggestion highlighted if confident
        → Search available for long lists
        
Step 4: Select wallet (optional if default set)
        → Current wallet pre-selected
        → Quick switch via horizontal scroll
        
Step 5: Add description (optional)
        → Keyboard with suggestions
        → Can skip
        
Step 6: Tap "Save"
        → Haptic feedback
        → Modal closes
        → Dashboard updates instantly
```

**Quick Add Shortcuts:**
- Double-tap FAB: Repeat last transaction (same amount, category, wallet)
- Long-press FAB: Voice input (future)
- Swipe gestures on dashboard for common amounts

### 4.2.4 Edit History & Audit Trail

Every transaction maintains an edit history:

```
TransactionHistory {
  historyId: UUID
  transactionId: UUID
  changeType: create/update/delete
  previousValues: JSON
  newValues: JSON
  changedAt: Timestamp
  changedBy: DeviceId
}
```

**Visible to User:**
- "Last edited: Feb 1, 2026 at 3:45 PM"
- Tap to see change history (Premium)

### 4.2.5 Recurring Transactions

**Supported Patterns:**
| Pattern | RRULE | Example |
|---------|-------|---------|
| Daily | `FREQ=DAILY` | Medication |
| Weekly | `FREQ=WEEKLY;BYDAY=MO` | Therapy |
| Bi-weekly | `FREQ=WEEKLY;INTERVAL=2` | Paycheck |
| Monthly | `FREQ=MONTHLY;BYMONTHDAY=1` | Rent |
| Yearly | `FREQ=YEARLY` | Insurance premium |

**Recurring Engine:**
1. Template transaction stored with `isRecurring=true`
2. System generates instances up to 30 days ahead
3. User can modify individual instances or all future
4. Skipped instances marked, not deleted

**Notification:**
- Optional reminder 1 day before due date
- "Upcoming: Rent - $1,500 due tomorrow"

### 4.2.6 Transaction States

| State | Description | Editable | In Analytics |
|-------|-------------|----------|--------------|
| **Pending** | Entered but not finalized | Full | Yes (marked) |
| **Cleared** | Confirmed transaction | Full | Yes |
| **Reconciled** | Matched with bank statement | Limited | Yes |

**State Transitions:**
```
Pending → Cleared (user confirms or auto after 24h)
Cleared → Reconciled (manual, or via bank sync future)
Reconciled → Cleared (unlock for editing)
```

### 4.2.7 Split Transactions

For purchases spanning multiple categories:

```
Original: $150 at Costco

Split into:
- Groceries: $100
- Household: $35
- Entertainment: $15

Total: $150 (must equal original)
```

**Split Rules:**
- Original transaction becomes "parent"
- Split items are child transactions
- Parent amount must equal sum of children
- Each split can have different category
- Budget impact distributed across categories

---

## 4.3 Categories

### 4.3.1 Default Category System

**Expense Categories (12 defaults):**

| Category | Icon | Color | Subcategories |
|----------|------|-------|---------------|
| Food & Dining | 🍽️ | #FF6B6B | Groceries, Restaurants, Coffee, Delivery |
| Transportation | 🚗 | #4ECDC4 | Gas, Public Transit, Rideshare, Parking |
| Shopping | 🛍️ | #45B7D1 | Clothing, Electronics, Home, Online |
| Entertainment | 🎬 | #96CEB4 | Movies, Games, Streaming, Events |
| Bills & Utilities | 📄 | #FFEAA7 | Electric, Water, Internet, Phone |
| Health | ❤️ | #DDA0DD | Medical, Pharmacy, Fitness, Insurance |
| Personal | 👤 | #98D8C8 | Haircut, Beauty, Subscriptions |
| Education | 📚 | #F7DC6F | Courses, Books, Supplies |
| Travel | ✈️ | #BB8FCE | Flights, Hotels, Activities |
| Gifts & Donations | 🎁 | #F8B500 | Gifts, Charity |
| Home | 🏠 | #85C1E9 | Rent, Mortgage, Repairs, Furniture |
| Other | 📦 | #AEB6BF | Uncategorized |

**Income Categories (5 defaults):**

| Category | Icon | Color |
|----------|------|-------|
| Salary | 💼 | #27AE60 |
| Freelance | 💻 | #3498DB |
| Investments | 📈 | #9B59B6 |
| Gifts | 🎁 | #F39C12 |
| Other Income | 💰 | #1ABC9C |

### 4.3.2 Category Properties

```
Category {
  id: UUID
  name: String (max 30 chars)
  type: expense/income/transfer
  parentId: UUID? (for subcategories)
  icon: IconName (from icon library)
  color: HexColor
  isDefault: Boolean (system-provided)
  isArchived: Boolean
  sortOrder: Integer
  budgetDefault: Decimal? (suggested budget amount)
  
  // AI training
  keywords: String[] (for auto-categorization)
  merchantPatterns: String[] (regex patterns)
  
  createdAt: Timestamp
}
```

### 4.3.3 Custom Categories

**User Capabilities:**
- Create unlimited custom categories
- Create subcategories (one level deep)
- Rename default categories
- Change icons and colors
- Archive (hide but preserve history)
- Set category-specific budgets

**Category Creation:**
1. Navigate to Categories screen
2. Tap "Add Category"
3. Enter name
4. Select type (expense/income)
5. Choose parent (optional, for subcategory)
6. Pick icon from library (100+ options)
7. Select color from palette
8. Save

### 4.3.4 Icon Library

**100+ icons organized by theme:**

| Theme | Count | Examples |
|-------|-------|----------|
| Food | 15 | Coffee, Pizza, Grocery cart, Restaurant |
| Transport | 12 | Car, Bus, Train, Airplane, Bike |
| Shopping | 10 | Cart, Bag, Tag, Store |
| Home | 12 | House, Bed, Sofa, Tools |
| Health | 10 | Heart, Pill, Hospital, Gym |
| Entertainment | 15 | Movie, Music, Game, Book |
| Finance | 10 | Dollar, Euro, Bank, Card |
| Nature | 8 | Tree, Sun, Beach, Mountain |
| General | 20+ | Star, Flag, Pin, Clock |

### 4.3.5 AI Auto-Categorization

**How It Works:**
1. User enters description (e.g., "Starbucks")
2. AI matches against:
   - User's historical patterns for this merchant
   - Global merchant database
   - Keyword matching
3. Category suggested with confidence score
4. High confidence (>85%): Auto-select, user can change
5. Low confidence (<85%): Highlight suggestion, require confirmation

**Learning Loop:**
```
User enters "Uber" → AI suggests Transportation (95%)
User changes to Entertainment → 
  System learns: For this user, "Uber" → Entertainment
  Next time: Suggests Entertainment first
```

### 4.3.6 Category Operations

| Operation | Behavior |
|-----------|----------|
| **Archive** | Hidden from new transactions, visible in history |
| **Delete** | Only if zero transactions; else forced archive |
| **Merge** | Combine two categories, reassign all transactions |
| **Rename** | Name change only, no impact on transactions |
| **Change Parent** | Move subcategory to different parent |

---

## 4.4 Budgets

### 4.4.1 Budget Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Category Budget** | Limit spending in specific category | "Max $500 on Food" |
| **Total Budget** | Overall spending limit | "Max $3000 total spending" |
| **Envelope** | Pre-allocated funds for category | YNAB-style budgeting |
| **Goal** | Save toward specific target | "Save $5000 for vacation" |

### 4.4.2 Budget Properties

```
Budget {
  id: UUID
  name: String
  type: BudgetType
  amount: Decimal (target/limit)
  spent: Decimal (calculated)
  remaining: Decimal (calculated)
  
  // Period
  periodType: weekly/monthly/custom
  startDate: Date
  endDate: Date? (custom only)
  
  // Scope
  categoryIds: UUID[] (empty = all categories)
  walletIds: UUID[] (empty = all wallets)
  
  // Behavior
  rolloverEnabled: Boolean
  rolloverAmount: Decimal (carried from previous)
  alertThresholds: Integer[] (e.g., [50, 80, 100])
  
  // State
  status: active/paused/completed/archived
  
  createdAt: Timestamp
}
```

### 4.4.3 Period Types

| Period | Start | End | Reset |
|--------|-------|-----|-------|
| **Weekly** | User-defined day | 7 days later | Auto |
| **Monthly** | User-defined date | Same date next month | Auto |
| **Custom** | User-defined | User-defined | Manual |

**Monthly Edge Cases:**
- Start date: 31st → Next month with fewer days uses last day
- February handling: 29th/30th/31st → Feb 28 (or 29 leap year)

### 4.4.4 Rollover Logic

**When Enabled:**

```
January Budget: $500 | Spent: $450 | Surplus: $50
February Budget: $500 + $50 rollover = $550 available

January Budget: $500 | Spent: $550 | Deficit: -$50
February Budget: $500 - $50 rollover = $450 available
```

**Rollover Rules:**
- Surplus: Added to next period (bonus)
- Deficit: Subtracted from next period (penalty)
- User can manually adjust rollover amount
- Maximum rollover cap: 50% of budget (configurable)

### 4.4.5 Envelope Budgeting (Premium)

**Philosophy:** Every dollar has a job before it's spent.

**Flow:**
1. Income arrives ($5000)
2. User allocates to envelopes:
   - Rent: $1500
   - Food: $600
   - Transportation: $300
   - Entertainment: $200
   - Savings: $1000
   - Buffer: $1400
3. Spending deducts from envelope
4. If envelope empty: Warning before transaction
5. Can transfer between envelopes anytime

**Visual:**
```
┌────────────────────────────────┐
│ 💳 Food                        │
│ ████████████░░░░░ $450 / $600  │
│ Remaining: $150                │
└────────────────────────────────┘
```

### 4.4.6 Goal-Based Saving (Premium)

**Goal Properties:**
```
SavingsGoal {
  id: UUID
  name: String ("Japan Trip")
  targetAmount: Decimal ($5000)
  currentAmount: Decimal ($2300)
  targetDate: Date? (Dec 2026)
  monthlyContribution: Decimal (calculated or manual)
  linkedWalletId: UUID? (dedicated savings wallet)
  iconUrl: String? (custom image)
}
```

**Progress Calculation:**
```
Target: $5000 by Dec 2026 (10 months away)
Current: $2300
Remaining: $2700
Required monthly: $270
On track: Yes/No based on actual contributions
```

### 4.4.7 Budget Alerts

| Threshold | Notification | UI Indicator |
|-----------|--------------|--------------|
| **50%** | "Halfway through your Food budget" | Yellow progress |
| **80%** | "80% of Food budget used - $100 remaining" | Orange progress |
| **100%** | "Food budget reached - consider slowing down" | Red progress |
| **110%+** | "Food budget exceeded by $50" | Red + overage shown |

**Alert Delivery:**
- Push notification (if enabled)
- In-app badge on Budgets tab
- Dashboard warning card
- Sound/haptic: Optional

### 4.4.8 Pace Indicator

Shows if spending rate is sustainable for the period:

```
Day 10 of 30 (33% of month elapsed)
Budget: $600 | Spent: $250 (42% used)

Pace: ⚠️ Slightly ahead
Daily average: $25/day
To stay on budget: $11.67/day remaining
```

**Pace States:**
| State | Condition | Color |
|-------|-----------|-------|
| On Track | Spent % ≤ Elapsed % + 5% | Green |
| Slightly Ahead | Spent % ≤ Elapsed % + 15% | Yellow |
| Over Pace | Spent % > Elapsed % + 15% | Red |

---

# 5. ANALYTICS & INSIGHTS

## 5.1 Analytics Philosophy

**Principles:**
1. **Clarity over complexity:** Every chart must answer a clear question
2. **Progressive disclosure:** Summary → Detail → Drill-down
3. **Actionable insights:** Data should lead to decisions
4. **No vanity metrics:** Everything shown must be useful
5. **Performance:** Charts load in <1 second

## 5.2 Analytics Modules

### 5.2.1 Monthly Overview (Dashboard)

**Purpose:** Instant snapshot of financial health

**Components:**
```
┌─────────────────────────────────────┐
│ February 2026                       │
├─────────────────────────────────────┤
│ Income        +$5,250      ████████ │
│ Expenses      -$3,780      ██████   │
│ ─────────────────────────────────── │
│ Net           +$1,470              │
│ Savings Rate: 28%                   │
└─────────────────────────────────────┘
```

**Data Points:**
- Total income this period
- Total expenses this period
- Net (income - expenses)
- Savings rate percentage
- Comparison to previous period (↑12% or ↓5%)

### 5.2.2 Category Breakdown

**Purpose:** Where is money going?

**Visualizations:**
1. **Pie Chart:** Proportional spending by category
2. **Bar Chart:** Absolute amounts ranked
3. **List View:** Detailed breakdown with transaction counts

**Pie Chart Spec:**
- Maximum 6 slices + "Other"
- Tap slice to drill into category
- Center shows total amount
- Legend shows top categories with percentages

**Bar Chart Spec:**
- Horizontal bars, sorted by amount
- Category icon + name on left
- Amount + percentage on right
- Tap bar to see transactions

### 5.2.3 Trend Analysis

**Purpose:** How is spending changing over time?

**Time Ranges:**
| Range | Granularity | Data Points |
|-------|-------------|-------------|
| Last 7 days | Daily | 7 |
| Last 30 days | Daily | 30 |
| Last 3 months | Weekly | 12 |
| Last 6 months | Weekly | 24 |
| Last 12 months | Monthly | 12 |
| Year-to-Date | Monthly | Variable |
| Custom | Auto-selected | Variable |

**Chart Type:** Line chart with area fill

**Features:**
- Toggle income/expenses/net
- Compare to previous period (overlay)
- Tap point to see daily/weekly breakdown
- Pinch to zoom on mobile

### 5.2.4 Spending Velocity

**Purpose:** Am I spending faster than I should?

**Calculation:**
```
Daily average = Total spent / Days elapsed
Projected month-end = Daily average × Days in month
Sustainable daily = Budget / Days in month
```

**Visualization:**
```
Spending Velocity
━━━━━━━━━━━━━━━●━━━━━━━━━━━
$0            $75/day        $150/day
              ↑ Current      ↑ Budget pace

Status: On Track ✓
You're spending $75/day. Budget allows $83/day.
```

### 5.2.5 Cash Flow Timeline

**Purpose:** When does money come in and go out?

**Visualization:** Stacked bar chart showing daily/weekly flow

```
Week 1    ████████ +$2500 (Salary)
          ████ -$1200 (Rent, Bills)
          
Week 2    █ +$150 (Side gig)
          ██ -$400 (General)
          
Week 3    █ +$100 (Refund)
          ██ -$450 (General)
          
Week 4    
          ███ -$600 (General, Insurance)
```

**Insights:**
- "Your expenses peak in Week 1 due to rent"
- "Income is concentrated early in month"

### 5.2.6 Net Worth Tracking (Premium)

**Purpose:** Big picture financial health

**Formula:**
```
Net Worth = Total Assets - Total Liabilities

Assets: Cash + Debit + Savings + Investments
Liabilities: Credit card balance + Loans (future)
```

**Visualization:** Area chart over time

**Features:**
- Monthly snapshots
- Breakdown by account type
- Growth rate percentage
- Milestone markers ("First $10K!")

### 5.2.7 Category Heatmap (Premium)

**Purpose:** Identify spending patterns across time

**Visualization:** Matrix grid

```
         Jan  Feb  Mar  Apr  May  Jun
Food     ███  ██   ███  ██   ██   █
Transport █   █    █    █    █    ██
Shopping ██  ███  █    ████ █    █
Entertain█   █    ██   █    ███  ██
```

**Color Scale:** Light (low) → Dark (high)

**Insights Generated:**
- "Shopping spikes in April (holiday season?)"
- "Entertainment peaks in May"

### 5.2.8 Merchant Insights (Premium)

**Purpose:** Track spending at specific places

**Top Merchants View:**
```
1. Amazon          $450  (12 transactions)
2. Costco          $380  (4 transactions)
3. Shell           $220  (8 transactions)
4. Netflix         $15   (1 transaction)
5. Starbucks       $85   (17 transactions)
```

**Merchant Detail:**
- Spending trend for this merchant
- Average transaction amount
- Frequency
- Category distribution

## 5.3 Chart Specifications

### 5.3.1 Chart Types

| Chart | Use Case | Library |
|-------|----------|---------|
| Line | Trends over time | fl_chart |
| Area | Cumulative values | fl_chart |
| Bar (Vertical) | Comparing periods | fl_chart |
| Bar (Horizontal) | Ranking categories | fl_chart |
| Pie/Donut | Proportions | fl_chart |
| Heatmap | Two-dimension patterns | Custom |

### 5.3.2 Interaction Patterns

| Gesture | Action |
|---------|--------|
| Tap | Show tooltip with details |
| Long press | Highlight and show more info |
| Pinch | Zoom in/out (trends) |
| Swipe | Navigate time periods |
| Double tap | Reset view |

### 5.3.3 Empty States

**No Data Yet:**
```
📊 
Track for 7 days to see trends

Your first insights will appear here once you have
enough data. Start by adding a few transactions!

[Add Transaction]
```

**Filtered to Empty:**
```
No transactions match your filters

Try adjusting the date range or categories.

[Clear Filters]
```

### 5.3.4 Performance Requirements

| Metric | Target |
|--------|--------|
| Chart render | <500ms |
| Filter apply | <200ms |
| Data load (10k transactions) | <1s |
| Scroll through charts | 60 FPS |
| Export generation | <3s |

## 5.4 Filters & Controls

### 5.4.1 Date Range Picker

**Presets:**
- Today
- This week
- This month
- Last month
- Last 3 months
- Last 6 months
- This year
- Last year
- All time
- Custom range

### 5.4.2 Category Filter

- All categories (default)
- Specific category
- Multiple categories (checkbox)
- Exclude categories

### 5.4.3 Wallet Filter

- All wallets (default)
- Specific wallet
- Multiple wallets
- Exclude hidden wallets

### 5.4.4 Amount Filter

- All amounts (default)
- Greater than $X
- Less than $X
- Range $X to $Y

## 5.5 Data Export

### 5.5.1 Export Formats

| Format | Contents | Use Case |
|--------|----------|----------|
| CSV | Raw transaction data | Spreadsheet analysis |
| JSON | Structured data | Developers, backups |
| PDF | Formatted report | Sharing, records |

### 5.5.2 Export Options

- Date range selection
- Category filter
- Wallet filter
- Include/exclude transfers
- Include budget data
- Include analytics summary

### 5.5.3 PDF Report Structure

```
FINSOR FINANCIAL REPORT
Period: February 2026
Generated: Feb 28, 2026

SUMMARY
- Total Income: $5,250
- Total Expenses: $3,780
- Net: $1,470
- Savings Rate: 28%

CATEGORY BREAKDOWN
[Pie chart image]
[Category table]

TRANSACTIONS
[Paginated transaction list]

BUDGET PERFORMANCE
[Budget status table]
```

---

# 6. AI ASSISTANT

## 6.1 Overview

The AI Assistant is Finsor's core differentiator—a genuinely useful financial companion that provides insights, answers questions, and helps users make better financial decisions. It is not a chatbot for the sake of having AI; every feature must provide concrete value.

## 6.2 Capabilities

### 6.2.1 Natural Language Queries

Users can ask questions in plain language:

| Query Type | Example | Response Type |
|------------|---------|---------------|
| **Spending inquiry** | "How much did I spend on food this month?" | Data + comparison |
| **Pattern question** | "Why did I spend more this week?" | Analysis + breakdown |
| **Recommendation** | "How can I save more money?" | Actionable suggestions |
| **Comparison** | "Compare my spending to last month" | Side-by-side analysis |
| **Budget check** | "Am I on track with my budgets?" | Status + projection |
| **Explanation** | "What's my biggest expense category?" | Ranked data |

### 6.2.2 Smart Categorization

**Accuracy Target:** >90% on common merchants

**Categorization Pipeline:**
```
Input: "STARBUCKS #12345 SAN FRANCISCO"
    ↓
Step 1: Merchant extraction → "Starbucks"
    ↓
Step 2: User history check → Previous: Food & Dining (95%)
    ↓
Step 3: Global database → Starbucks = Coffee/Food (98%)
    ↓
Step 4: Confidence calculation → 96%
    ↓
Output: Suggest "Food & Dining" with 96% confidence
```

**Learning from Corrections:**
```
User changes "Uber" from Transportation → Entertainment
    ↓
Store: User preference for "Uber" = Entertainment
    ↓
Future: Prioritize Entertainment for Uber transactions
    ↓
Confidence adjustment based on correction frequency
```

### 6.2.3 Pattern Detection

**Detected Patterns:**

| Pattern | Detection Method | Alert Trigger |
|---------|-----------------|---------------|
| **Spending spike** | Current > 1.5× rolling average | Yes |
| **New recurring** | Same amount, same merchant, regular interval | Notification |
| **Unusual merchant** | First-time high-value transaction | Optional alert |
| **Category drift** | Gradual increase over 3+ months | Monthly insight |
| **Budget at risk** | Pace indicates likely overspend | Yes |
| **Savings opportunity** | Identified redundant subscriptions | Monthly insight |

### 6.2.4 Budget Recommendations

**AI-Generated Suggestions:**

```
Based on your spending patterns, here are budget suggestions:

Food & Dining
├── Current average: $580/month
├── Suggested budget: $550/month
└── Potential savings: $30/month

Entertainment
├── Current average: $120/month
├── Suggested budget: $100/month
└── Potential savings: $20/month

Reasoning: Your Food spending has been consistent.
A slightly lower target could help without major lifestyle changes.
```

### 6.2.5 Behavioral Insights

**"Why did I spend more?" Analysis:**

```
Your spending increased by $450 this month. Here's why:

1. 📱 New subscription: Apple One (+$30)
   Started Feb 5

2. 🛍️ Shopping spike: +$280
   3 purchases at Amazon (electronics category)

3. 🍽️ Dining out: +$140
   8 restaurant visits vs. 4 last month

Recommendation: The shopping spike appears one-time.
Monitor dining out if you want to reduce next month.
```

### 6.2.6 Predictive Cash Flow

**End-of-Month Projection:**

```
Cash Flow Forecast (Feb 2026)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current balance: $3,450

Expected Income:
+ Salary (Feb 28): $4,200

Expected Expenses:
- Rent (Feb 1): $1,500 ✓ Paid
- Utilities (Feb 15): ~$150
- Subscriptions: ~$85
- Projected general: ~$1,200

Projected end-of-month: $4,715

You're on track for a good month! 📈
```

## 6.3 Architecture

### 6.3.1 Hybrid Approach

```
┌─────────────────────────────────────────────────────────┐
│                    USER DEVICE                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────┐     ┌─────────────────────────┐   │
│  │ On-Device ML    │     │ Local Data Processing   │   │
│  │                 │     │                         │   │
│  │ • Categorization│     │ • Data aggregation      │   │
│  │ • Merchant ID   │     │ • Pattern pre-compute   │   │
│  │ • Quick matches │     │ • Privacy filtering     │   │
│  └────────┬────────┘     └────────────┬────────────┘   │
│           │                           │                 │
│           └───────────┬───────────────┘                 │
│                       │                                 │
│              ┌────────▼────────┐                        │
│              │ Context Builder │                        │
│              │ (Summarizes,    │                        │
│              │  anonymizes)    │                        │
│              └────────┬────────┘                        │
│                       │                                 │
└───────────────────────┼─────────────────────────────────┘
                        │ HTTPS/TLS 1.3
                        │ (No raw transactions)
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    CLOUD (Supabase Edge)                │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐     ┌─────────────────────────┐   │
│  │ AI Processing   │     │ OpenAI API              │   │
│  │                 │     │                         │   │
│  │ • Context parse │────▶│ • GPT-4 / GPT-3.5      │   │
│  │ • Response fmt  │◀────│ • Natural language     │   │
│  │ • Caching       │     │ • Insights generation  │   │
│  └─────────────────┘     └─────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 6.3.2 On-Device Processing

**What runs locally:**
- Transaction categorization (lightweight ML model)
- Merchant name extraction and normalization
- Spending calculations and aggregations
- Pattern detection (rule-based)
- Data anonymization before cloud calls

**Benefits:**
- Works offline (basic features)
- Privacy preserved
- Instant responses for common operations

### 6.3.3 Cloud Processing

**What requires cloud:**
- Natural language understanding
- Complex insight generation
- Personalized recommendations
- Conversational AI responses

**Data sent to cloud (anonymized):**
```json
{
  "context": {
    "totalIncome": 5250,
    "totalExpenses": 3780,
    "categoryBreakdown": {
      "Food": 580,
      "Transportation": 220,
      "Shopping": 450
    },
    "transactionCount": 45,
    "period": "2026-02",
    "budgetStatus": {
      "Food": { "budget": 600, "spent": 580, "status": "warning" }
    }
  },
  "query": "Why did I spend more this month?",
  "userId": "anonymous-hash"
}
```

**Data NOT sent:**
- Individual transaction descriptions
- Merchant names
- Exact dates
- Personal notes
- Location data

### 6.3.4 Context Window Strategy

**Context includes (last 90 days):**
```
Financial Summary:
- Income total and sources
- Expense total and top categories
- Net savings
- Account balances (totals only)

Budgets:
- Active budgets with status
- Goal progress

Patterns:
- Identified recurring transactions (anonymized)
- Spending trends (percentages)
- Anomalies detected

User Preferences:
- Preferred categories
- Correction history (for learning)
```

**Context size:** ~2000 tokens maximum

### 6.3.5 Prompt Structure

**System Prompt:**
```
You are Finsor AI, a helpful personal finance assistant. Your role is to:
1. Answer questions about the user's spending patterns
2. Provide actionable financial insights
3. Help users understand their financial behavior
4. Suggest ways to save money and meet goals

Rules:
- Only use data provided in the context
- Never invent numbers or transactions
- Be encouraging but honest
- Keep responses concise (max 200 words)
- Use bullet points for clarity
- Include specific numbers when relevant
- Never provide investment or tax advice
- If asked about something outside your data, say so clearly

Format responses in a friendly, conversational tone.
```

**User Prompt Template:**
```
FINANCIAL CONTEXT:
{context_json}

USER QUESTION:
{user_query}

Provide a helpful, specific response based only on the data above.
```

## 6.4 Privacy Safeguards

### 6.4.1 Data Minimization

| Data Type | Sent to Cloud | Reason |
|-----------|---------------|--------|
| Transaction amounts | Aggregated only | Privacy |
| Merchant names | Never | Privacy |
| Descriptions | Never | Privacy |
| Category totals | Yes (anonymized) | Required for insights |
| Dates | Period only (month) | Privacy |
| User ID | Hashed | Cannot identify user |

### 6.4.2 Local-First Processing

```
User asks: "How much did I spend at Starbucks?"

Processing:
1. Query runs entirely on device
2. Local DB queried for merchant "Starbucks"
3. Sum calculated locally
4. Response generated locally
5. No cloud call needed

Response: "You spent $127.50 at Starbucks this month across 15 visits."
```

### 6.4.3 Consent & Control

**AI Settings:**
- **Enable AI Assistant:** Toggle on/off
- **Cloud AI:** Allow cloud processing for advanced insights
- **Local Only Mode:** All processing on-device (limited features)
- **Data Retention:** Cloud context deleted after 24 hours

## 6.5 Constraints & Guardrails

### 6.5.1 Legal Disclaimers

**Displayed in AI chat:**
```
ℹ️ Finsor AI provides informational insights only.
This is not financial, investment, or tax advice.
Consult a qualified professional for personalized guidance.
```

### 6.5.2 Response Constraints

| Constraint | Implementation |
|------------|----------------|
| **No investment advice** | Blocked phrases + instruction in system prompt |
| **No tax advice** | Blocked phrases + instruction in system prompt |
| **No hallucinated numbers** | All numbers must come from provided context |
| **Admit uncertainty** | "I don't have enough data" when appropriate |
| **No external data** | Cannot reference news, markets, etc. |

### 6.5.3 Graceful Degradation

**Offline Mode:**
```
AI features available offline:
✓ Smart categorization
✓ Basic spending summaries
✓ Budget status checks
✓ Pattern alerts (pre-computed)

Features requiring connection:
✗ Natural language questions
✗ Detailed insights
✗ Recommendations
```

**Error Handling:**
```
If AI request fails:
1. Show cached response if similar query exists
2. Offer basic data summary
3. "I'm having trouble connecting. Here's what I can show you locally..."
4. Retry button available
```

## 6.6 UX Design

### 6.6.1 Chat Interface

```
┌─────────────────────────────────────┐
│ ← Finsor AI              🔄 Clear   │
│    Your Financial Assistant         │
├─────────────────────────────────────┤
│                                     │
│ 🤖 Hi! I've analyzed your finances. │
│    Here are some insights:          │
│                                     │
│    • You're saving 28% this month   │
│    • Food spending is on track      │
│    • Shopping increased by $150     │
│                                     │
│    What would you like to know?     │
│                                     │
├─────────────────────────────────────┤
│ 💡 Suggested questions:             │
│ ┌─────────────────────────────────┐ │
│ │ How can I save more money?      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ What's my biggest expense?      │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ [Ask me anything...          ] [➤] │
└─────────────────────────────────────┘
```

### 6.6.2 Insight Cards (Dashboard)

```
┌─────────────────────────────────────┐
│ 💡 AI Insight                       │
│                                     │
│ Your dining spending is 40% higher  │
│ than your 3-month average.          │
│                                     │
│ [View Details]  [Adjust Budget]     │
└─────────────────────────────────────┘
```

### 6.6.3 Suggested Questions

Dynamically generated based on user data:

```
Suggested questions update based on context:

If budget is at risk:
→ "Why is my Food budget running low?"

If spending increased:
→ "Why did I spend more this week?"

If goal exists:
→ "Am I on track for my savings goal?"

If new month:
→ "How did I do last month?"
```

### 6.6.4 Response Formatting

**Good Response:**
```
📊 Your biggest expense this month is Food & Dining at $580.

Breakdown:
• Groceries: $320 (55%)
• Restaurants: $180 (31%)
• Coffee: $80 (14%)

💡 Tip: Your restaurant spending is higher than usual.
Consider meal prepping to save ~$50/month.
```

**Avoid:**
- Walls of text
- Vague statements
- Numbers without context
- Jargon

### 6.6.5 Explainability

Every AI insight includes reasoning:

```
"Based on your last 30 days of transactions..."
"Comparing to your 3-month average..."
"Looking at your budget settings..."
"I noticed a pattern in your spending..."
```

## 6.7 AI-Specific Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Categorization accuracy | >90% | Accepted suggestions / Total |
| User acceptance rate | >70% | Unchanged suggestions / Total |
| Query response time | <3s | API latency + processing |
| Insight engagement | >30% | Clicked / Shown |
| Correction rate | <10% | User corrections / Total categorizations |
| Useful rating | >4.0/5 | In-app feedback |

---

# 7. UX/UI SYSTEM

## 7.1 Design Principles

### 7.1.1 Core Philosophy

**"Clarity through simplicity"**

Finsor's design follows these non-negotiable principles:

| Principle | Description | Implementation |
|-----------|-------------|----------------|
| **Minimal** | Every element must earn its place | Ruthless elimination of clutter |
| **Fast** | UI should feel instant | Animations <300ms, feedback <100ms |
| **Calm** | Finance is stressful; UI shouldn't be | Neutral colors, no aggressive alerts |
| **One-handed** | Primary actions reachable by thumb | Bottom navigation, FAB placement |
| **ADHD-friendly** | Low cognitive load | Clear hierarchy, chunked information |

### 7.1.2 Visual Hierarchy

```
Level 1: Primary numbers (balances, totals)
         → Largest, boldest, most prominent
         
Level 2: Section headers, key actions
         → Medium weight, clear separation
         
Level 3: Supporting data (dates, descriptions)
         → Smaller, lighter weight
         
Level 4: Metadata (timestamps, counts)
         → Smallest, lowest contrast
```

### 7.1.3 Color System

**Primary Palette:**

| Name | Light Mode | Dark Mode | Usage |
|------|------------|-----------|-------|
| Background Primary | #FFFFFF | #121212 | Main background |
| Background Secondary | #F5F5F5 | #1E1E1E | Cards, elevated surfaces |
| Text Primary | #1A1A1A | #FFFFFF | Headlines, primary content |
| Text Secondary | #6B7280 | #9CA3AF | Supporting text, labels |

**Semantic Colors:**

| Name | Color | Usage |
|------|-------|-------|
| Income/Positive | #34C759 | Income amounts, savings, on-track |
| Expense/Negative | #FF3B30 | Expense amounts, over-budget, warnings |
| Warning | #FF9500 | Approaching limits, pending items |
| Primary Action | #007AFF | CTAs, links, selected states |
| Neutral | #8E8E93 | Disabled, inactive, transfers |

### 7.1.4 Typography

**Font Stack:** System fonts (SF Pro for iOS, Roboto for Android)

| Element | Size | Weight | Line Height |
|---------|------|--------|-------------|
| Display (Balance) | 48-64sp | Bold | 1.1 |
| H1 (Screen Title) | 34sp | Bold | 1.2 |
| H2 (Section Header) | 28sp | Semibold | 1.3 |
| H3 (Card Title) | 20sp | Medium | 1.4 |
| Body | 16sp | Regular | 1.5 |
| Body Small | 14sp | Regular | 1.5 |
| Caption | 12sp | Regular | 1.4 |

### 7.1.5 Spacing System

**8pt Grid:**
- All spacing in multiples of 8
- Minimum touch target: 44×44pt
- Card padding: 16pt
- Section spacing: 24pt
- Screen margins: 16pt

### 7.1.6 Animation Guidelines

| Type | Duration | Curve | Example |
|------|----------|-------|---------|
| Micro-feedback | 100ms | ease-out | Button press |
| Transition | 200ms | ease-in-out | Screen change |
| Modal | 300ms | spring | Bottom sheet |
| Data update | 150ms | ease-out | Balance change |

**Rules:**
- Never block interaction during animation
- Animations should be skippable
- Reduce motion option respected

## 7.2 Screen Specifications

### 7.2.1 Onboarding Flow

**Purpose:** Get users set up quickly with minimal friction

**Screen 1: Welcome**
```
┌─────────────────────────────────────┐
│                                     │
│           [Finsor Logo]             │
│                                     │
│        "Clarity for your            │
│           finances"                 │
│                                     │
│    Track spending, understand       │
│    patterns, reach your goals.      │
│                                     │
│                                     │
│        [Get Started]                │
│                                     │
│      Already have an account?       │
│           [Sign In]                 │
│                                     │
└─────────────────────────────────────┘
```

**Screen 2: Account Creation**
```
┌─────────────────────────────────────┐
│ ←                                   │
│                                     │
│      Create your account            │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📧 Email                        │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🔒 Password                     │ │
│ └─────────────────────────────────┘ │
│                                     │
│        [Create Account]             │
│                                     │
│         ─── or ───                  │
│                                     │
│   [🍎 Apple]    [G Google]         │
│                                     │
│                                     │
│    By continuing, you agree to      │
│    our Terms and Privacy Policy     │
│                                     │
└─────────────────────────────────────┘
```

**Screen 3: Currency Selection**
```
┌─────────────────────────────────────┐
│ ←                         Step 1/3  │
│                                     │
│     What's your main currency?      │
│                                     │
│   This will be used for reports     │
│   and analytics.                    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🔍 Search currencies...         │ │
│ └─────────────────────────────────┘ │
│                                     │
│   Popular:                          │
│   ┌───────┐ ┌───────┐ ┌───────┐    │
│   │ $ USD │ │ € EUR │ │ £ GBP │    │
│   └───────┘ └───────┘ └───────┘    │
│                                     │
│   All currencies:                   │
│   ┌─────────────────────────────┐   │
│   │ 🇦🇺 AUD - Australian Dollar │   │
│   │ 🇧🇷 BRL - Brazilian Real    │   │
│   │ 🇨🇦 CAD - Canadian Dollar   │   │
│   │ ...                         │   │
│   └─────────────────────────────┘   │
│                                     │
│           [Continue]                │
│                                     │
└─────────────────────────────────────┘
```

**Screen 4: First Wallet**
```
┌─────────────────────────────────────┐
│ ←                         Step 2/3  │
│                                     │
│     Set up your first wallet        │
│                                     │
│   A wallet represents a real        │
│   account, like checking or cash.   │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💳 Wallet name                  │ │
│ │    Main Checking                │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💰 Current balance              │ │
│ │    $ 0.00                       │ │
│ └─────────────────────────────────┘ │
│                                     │
│   Wallet type:                      │
│   ○ Cash    ● Debit    ○ Credit    │
│   ○ Savings                         │
│                                     │
│           [Continue]                │
│                                     │
│      [Skip - I'll add later]        │
│                                     │
└─────────────────────────────────────┘
```

**Screen 5: Ready**
```
┌─────────────────────────────────────┐
│                          Step 3/3   │
│                                     │
│              ✅                      │
│                                     │
│        You're all set!              │
│                                     │
│    Start tracking your finances     │
│    by adding your first             │
│    transaction.                     │
│                                     │
│        [Add Transaction]            │
│                                     │
│      [Go to Dashboard]              │
│                                     │
│                                     │
│   💡 Tip: Add the Finsor widget     │
│      to your home screen for        │
│      quick access.                  │
│                                     │
└─────────────────────────────────────┘
```

**Error States:**
- Invalid email: Inline error below field
- Weak password: Requirements shown
- Network error: Toast with retry

---

### 7.2.2 Home / Dashboard

**Purpose:** Instant snapshot of financial health

```
┌─────────────────────────────────────┐
│ Good morning, Alex           [👤]   │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │  Total Balance                  │ │
│ │                                 │ │
│ │     $12,450.00                  │ │
│ │     ↑ $1,230 this month         │ │
│ │                                 │ │
│ │  [Main ▼]    [See all wallets]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ This Month          [Details >] │ │
│ │                                 │ │
│ │ Income    $5,250    ████████    │ │
│ │ Expenses  $3,780    ██████      │ │
│ │ ────────────────────────────    │ │
│ │ Net       +$1,470               │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💡 AI Insight                   │ │
│ │                                 │ │
│ │ Your Food budget is 85% used    │ │
│ │ with 8 days remaining.          │ │
│ │                                 │ │
│ │ [View Budget]                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Recent Transactions      [See all] │
│ ┌─────────────────────────────────┐ │
│ │ 🍽️ Starbucks        -$5.50     │ │
│ │    Food · Today                 │ │
│ ├─────────────────────────────────┤ │
│ │ 🚗 Shell Gas          -$45.00   │ │
│ │    Transportation · Yesterday   │ │
│ ├─────────────────────────────────┤ │
│ │ 💼 Salary           +$4,200     │ │
│ │    Income · Feb 1               │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  [🏠]   [📊]   [➕]   [🤖]   [⚙️]  │
└─────────────────────────────────────┘
```

**Key Components:**
- **Balance Card:** Total across wallets, wallet selector
- **Monthly Summary:** Income/Expense/Net at a glance
- **AI Insight Card:** Contextual, actionable insight
- **Recent Transactions:** Last 3-5 transactions
- **Bottom Navigation:** 5 tabs with FAB in center

**Empty State:**
```
┌─────────────────────────────────────┐
│                                     │
│           📊                        │
│                                     │
│    Add your first transaction       │
│                                     │
│    Start tracking your spending     │
│    to see insights here.            │
│                                     │
│       [+ Add Transaction]           │
│                                     │
└─────────────────────────────────────┘
```

**Error State:**
```
┌─────────────────────────────────────┐
│ ⚠️ Sync issue                       │
│ Some data may be outdated.  [Retry] │
└─────────────────────────────────────┘
```

---

### 7.2.3 Wallets Screen

**Purpose:** Manage all financial accounts

```
┌─────────────────────────────────────┐
│ Wallets                    [+ Add]  │
├─────────────────────────────────────┤
│                                     │
│ Total: $12,450.00                   │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💳 Main Checking                │ │
│ │                                 │ │
│ │    $8,200.00                    │ │
│ │    12 transactions this month   │ │
│ │                            [>]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💵 Cash                         │ │
│ │                                 │ │
│ │    $450.00                      │ │
│ │    5 transactions this month    │ │
│ │                            [>]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🏦 Savings                      │ │
│ │                                 │ │
│ │    $3,800.00                    │ │
│ │    2 transactions this month    │ │
│ │                            [>]  │ │
│ └─────────────────────────────────┘ │
│                                     │
│           [↔️ Transfer]             │
│                                     │
├─────────────────────────────────────┤
│  [🏠]   [📊]   [➕]   [🤖]   [⚙️]  │
└─────────────────────────────────────┘
```

**Wallet Detail Screen:**
```
┌─────────────────────────────────────┐
│ ← Main Checking            [•••]   │
├─────────────────────────────────────┤
│                                     │
│           $8,200.00                 │
│         Current Balance             │
│                                     │
│   Income     Expenses     Net       │
│   +$4,200    -$1,850    +$2,350    │
│                                     │
├─────────────────────────────────────┤
│ Transactions                        │
│ ┌─────────────────────────────────┐ │
│ │ Today                           │ │
│ │ 🍽️ Starbucks        -$5.50     │ │
│ │ 🛍️ Amazon           -$45.00    │ │
│ ├─────────────────────────────────┤ │
│ │ Yesterday                       │ │
│ │ 🚗 Shell Gas         -$45.00    │ │
│ │ ...                             │ │
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

**Actions Menu (•••):**
- Edit wallet
- Archive wallet
- Transfer from/to
- View analytics

**Empty State:**
```
No wallets yet

Add your first wallet to start 
tracking your finances.

[+ Add Wallet]
```

---

### 7.2.4 Add Transaction

**Purpose:** Fast, frictionless transaction entry

```
┌─────────────────────────────────────┐
│ ✕ Add Transaction                   │
├─────────────────────────────────────┤
│                                     │
│  [Expense]  [Income]  [Transfer]    │
│                                     │
│         $ 0.00                      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 7    8    9                     │ │
│ │ 4    5    6                     │ │
│ │ 1    2    3                     │ │
│ │ .    0    ⌫                     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📁 Category                     │ │
│ │    Select category...       [>] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 💳 Wallet                       │ │
│ │    Main Checking            [>] │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📝 Description (optional)       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📅 Today                    [>] │ │
│ └─────────────────────────────────┘ │
│                                     │
│           [Save]                    │
│                                     │
└─────────────────────────────────────┘
```

**Category Picker:**
```
┌─────────────────────────────────────┐
│ ← Select Category                   │
├─────────────────────────────────────┤
│ 🔍 Search categories...             │
├─────────────────────────────────────┤
│ Recent                              │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │
│ │ 🍽️ │ │ 🚗 │ │ 🛍️ │ │ ☕ │    │
│ │Food │ │Trans│ │Shop │ │Coff │    │
│ └─────┘ └─────┘ └─────┘ └─────┘    │
├─────────────────────────────────────┤
│ 💡 AI Suggestion: Food & Dining     │
├─────────────────────────────────────┤
│ All Categories                      │
│                                     │
│ 🍽️ Food & Dining               [>] │
│    ├ Groceries                      │
│    ├ Restaurants                    │
│    └ Coffee                         │
│                                     │
│ 🚗 Transportation               [>] │
│ 🛍️ Shopping                     [>] │
│ ...                                 │
│                                     │
└─────────────────────────────────────┘
```

**Validation Errors:**
- Amount = 0: "Enter an amount"
- No category: "Select a category"
- Future date warning: "This date is in the future"

---

### 7.2.5 Transactions List

**Purpose:** View and manage all transactions

```
┌─────────────────────────────────────┐
│ Transactions               [🔍] [⫶] │
├─────────────────────────────────────┤
│ February 2026        $3,780 spent   │
│ [< Prev]                   [Next >] │
├─────────────────────────────────────┤
│                                     │
│ TODAY                               │
│ ┌─────────────────────────────────┐ │
│ │ 🍽️ Starbucks        -$5.50     │ │
│ │    Food & Dining · Main Check   │ │
│ │    9:30 AM                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ YESTERDAY                           │
│ ┌─────────────────────────────────┐ │
│ │ 🚗 Shell Gas          -$45.00   │ │
│ │    Transportation · Main Check  │ │
│ ├─────────────────────────────────┤ │
│ │ 🛍️ Amazon             -$89.99   │ │
│ │    Shopping · Credit Card       │ │
│ └─────────────────────────────────┘ │
│                                     │
│ FEBRUARY 1                          │
│ ┌─────────────────────────────────┐ │
│ │ 💼 Salary           +$4,200.00  │ │
│ │    Income · Main Checking       │ │
│ ├─────────────────────────────────┤ │
│ │ 🏠 Rent              -$1,500.00 │ │
│ │    Bills · Main Checking        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Load More]                         │
│                                     │
├─────────────────────────────────────┤
│  [🏠]   [📊]   [➕]   [🤖]   [⚙️]  │
└─────────────────────────────────────┘
```

**Filter Panel (⫶):**
```
┌─────────────────────────────────────┐
│ Filters                    [Clear]  │
├─────────────────────────────────────┤
│ Type                                │
│ [✓ All] [Expense] [Income] [Transf] │
│                                     │
│ Category                            │
│ [All categories ▼]                  │
│                                     │
│ Wallet                              │
│ [All wallets ▼]                     │
│                                     │
│ Amount                              │
│ [$___] to [$___]                    │
│                                     │
│         [Apply Filters]             │
└─────────────────────────────────────┘
```

**Search (🔍):**
- Searches description, merchant, notes
- Results update as you type
- Highlight matching text

**Transaction Detail (tap item):**
```
┌─────────────────────────────────────┐
│ ← Transaction Detail        [Edit]  │
├─────────────────────────────────────┤
│                                     │
│           -$45.00                   │
│                                     │
│ 🚗 Transportation                   │
│                                     │
│ Description                         │
│ Shell Gas Station                   │
│                                     │
│ Wallet                              │
│ 💳 Main Checking                    │
│                                     │
│ Date                                │
│ Feb 5, 2026 at 2:30 PM              │
│                                     │
│ Notes                               │
│ Regular fill-up                     │
│                                     │
│ ─────────────────────────────────   │
│                                     │
│ Created: Feb 5, 2026 2:31 PM        │
│ Last edited: Never                  │
│                                     │
│         [🗑️ Delete]                │
│                                     │
└─────────────────────────────────────┘
```

**Empty State:**
```
No transactions found

Try adjusting your filters or 
add a new transaction.

[+ Add Transaction]
```

---

### 7.2.6 Analytics Screen

**Purpose:** Deep insights into spending patterns

```
┌─────────────────────────────────────┐
│ Analytics                           │
├─────────────────────────────────────┤
│ [This Month ▼]                      │
├─────────────────────────────────────┤
│                                     │
│ Overview                            │
│ ┌─────────────────────────────────┐ │
│ │ Income    Expenses    Net       │ │
│ │ $5,250    $3,780     +$1,470   │ │
│ │                                 │ │
│ │ Savings Rate: 28%               │ │
│ │ vs last month: ↑ 5%             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Spending by Category                │
│ ┌─────────────────────────────────┐ │
│ │      [PIE CHART]                │ │
│ │    Food 32%  Transport 15%      │ │
│ │    Shopping 25%  Other 28%      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [View Details >]                    │
│                                     │
│ Spending Trend                      │
│ ┌─────────────────────────────────┐ │
│ │      [LINE CHART]               │ │
│ │  ___/\___/\___                  │ │
│ │ Jan  Feb  Mar  Apr              │ │
│ └─────────────────────────────────┘ │
│                                     │
│ More Analytics            [Premium] │
│ • Category Heatmap                  │
│ • Net Worth Tracking                │
│ • Merchant Insights                 │
│                                     │
├─────────────────────────────────────┤
│  [🏠]   [📊]   [➕]   [🤖]   [⚙️]  │
└─────────────────────────────────────┘
```

**Category Detail View:**
```
┌─────────────────────────────────────┐
│ ← Food & Dining                     │
├─────────────────────────────────────┤
│                                     │
│         $580.00                     │
│         This month                  │
│                                     │
│ Breakdown                           │
│ ┌─────────────────────────────────┐ │
│ │ Groceries       $320    55%     │ │
│ │ ████████████████████░░░░░       │ │
│ │                                 │ │
│ │ Restaurants     $180    31%     │ │
│ │ █████████████░░░░░░░░░░░        │ │
│ │                                 │ │
│ │ Coffee          $80     14%     │ │
│ │ ██████░░░░░░░░░░░░░░░░░         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Trend (6 months)                    │
│ ┌─────────────────────────────────┐ │
│ │ Sep Oct Nov Dec Jan Feb         │ │
│ │ $520 $490 $550 $620 $545 $580   │ │
│ │      [LINE CHART]               │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Top Transactions                    │
│ • Costco - $120                     │
│ • Whole Foods - $85                 │
│ • Chipotle - $45                    │
│                                     │
└─────────────────────────────────────┘
```

**Empty/Insufficient Data State:**
```
📊 Track for 7 days to see trends

Add more transactions to unlock 
insights about your spending patterns.

Progress: 3/7 days
███░░░░░░░
```

---

### 7.2.7 Budgets Screen

**Purpose:** Create and track spending limits

```
┌─────────────────────────────────────┐
│ Budgets                    [+ Add]  │
├─────────────────────────────────────┤
│ February 2026                       │
│ Overall: $2,850 / $3,500 (81%)      │
│ ████████████████░░░░                │
├─────────────────────────────────────┤
│                                     │
│ Category Budgets                    │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🍽️ Food & Dining               │ │
│ │                                 │ │
│ │ $495 / $600                     │ │
│ │ █████████████████░░░░  83%     │ │
│ │                                 │ │
│ │ $105 left · 8 days remaining    │ │
│ │ Pace: ⚠️ Slightly ahead         │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🎬 Entertainment                │ │
│ │                                 │ │
│ │ $45 / $150                      │ │
│ │ █████░░░░░░░░░░░░░░░░  30%     │ │
│ │                                 │ │
│ │ $105 left · On track ✓          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Savings Goals                       │
│ ┌─────────────────────────────────┐ │
│ │ ✈️ Japan Trip                   │ │
│ │                                 │ │
│ │ $2,300 / $5,000                 │ │
│ │ █████████░░░░░░░░░░░░  46%     │ │
│ │                                 │ │
│ │ On track for Dec 2026           │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  [🏠]   [📊]   [➕]   [🤖]   [⚙️]  │
└─────────────────────────────────────┘
```

**Create Budget:**
```
┌─────────────────────────────────────┐
│ ← New Budget                        │
├─────────────────────────────────────┤
│                                     │
│ Budget Type                         │
│ ○ Category Budget                   │
│ ○ Total Budget                      │
│ ● Savings Goal                      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Goal name                       │ │
│ │ Japan Trip                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Target amount                   │ │
│ │ $ 5,000.00                      │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Target date (optional)          │ │
│ │ December 2026                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Monthly contribution: ~$270         │
│                                     │
│         [Create Budget]             │
│                                     │
└─────────────────────────────────────┘
```

**Empty State:**
```
No budgets yet

Create your first budget to start 
managing your spending.

[+ Create Budget]

💡 Tip: Start with one category budget 
for your biggest spending area.
```

---

### 7.2.8 AI Assistant Screen

**Purpose:** Conversational financial insights

(See Section 6.6 for detailed AI UI specifications)

---

### 7.2.9 Settings Screen

**Purpose:** App configuration and account management

```
┌─────────────────────────────────────┐
│ Settings                            │
├─────────────────────────────────────┤
│                                     │
│ ACCOUNT                             │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Profile                   [>]│ │
│ │    alex@email.com               │ │
│ ├─────────────────────────────────┤ │
│ │ ⭐ Finsor Premium            [>]│ │
│ │    Free plan                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ PREFERENCES                         │
│ ┌─────────────────────────────────┐ │
│ │ 🎨 Appearance                [>]│ │
│ │    System default               │ │
│ ├─────────────────────────────────┤ │
│ │ 💱 Currency                  [>]│ │
│ │    USD ($)                      │ │
│ ├─────────────────────────────────┤ │
│ │ 🌐 Language                  [>]│ │
│ │    English                      │ │
│ ├─────────────────────────────────┤ │
│ │ 🔔 Notifications             [>]│ │
│ └─────────────────────────────────┘ │
│                                     │
│ SECURITY                            │
│ ┌─────────────────────────────────┐ │
│ │ 🔐 App Lock                  [>]│ │
│ │    Face ID enabled              │ │
│ ├─────────────────────────────────┤ │
│ │ 🔑 Change Password           [>]│ │
│ └─────────────────────────────────┘ │
│                                     │
│ DATA                                │
│ ┌─────────────────────────────────┐ │
│ │ 📁 Categories                [>]│ │
│ ├─────────────────────────────────┤ │
│ │ ☁️ Backup & Sync             [>]│ │
│ ├─────────────────────────────────┤ │
│ │ 📤 Export Data               [>]│ │
│ └─────────────────────────────────┘ │
│                                     │
│ ABOUT                               │
│ ┌─────────────────────────────────┐ │
│ │ ❓ Help & Support            [>]│ │
│ ├─────────────────────────────────┤ │
│ │ 📜 Privacy Policy            [>]│ │
│ ├─────────────────────────────────┤ │
│ │ 📋 Terms of Service          [>]│ │
│ ├─────────────────────────────────┤ │
│ │ ℹ️ About Finsor              [>]│ │
│ │    Version 1.0.0                │ │
│ └─────────────────────────────────┘ │
│                                     │
│         [Sign Out]                  │
│                                     │
├─────────────────────────────────────┤
│  [🏠]   [📊]   [➕]   [🤖]   [⚙️]  │
└─────────────────────────────────────┘
```

---

### 7.2.10 Category Manager

**Purpose:** Customize expense/income categories

```
┌─────────────────────────────────────┐
│ ← Categories               [+ Add]  │
├─────────────────────────────────────┤
│ [Expense]  [Income]                 │
├─────────────────────────────────────┤
│                                     │
│ 🍽️ Food & Dining                    │
│ ┌─────────────────────────────────┐ │
│ │   🛒 Groceries                  │ │
│ │   🍕 Restaurants                │ │
│ │   ☕ Coffee                     │ │
│ │   🚚 Delivery                   │ │
│ │   [+ Add subcategory]           │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🚗 Transportation                   │
│ ┌─────────────────────────────────┐ │
│ │   ⛽ Gas                        │ │
│ │   🚌 Public Transit             │ │
│ │   🚕 Rideshare                  │ │
│ │   🅿️ Parking                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ 🛍️ Shopping                         │
│ ...                                 │
│                                     │
│ ARCHIVED                            │
│ ┌─────────────────────────────────┐ │
│ │ 📦 Old Category          [Restore]│
│ └─────────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

**Edit Category:**
```
┌─────────────────────────────────────┐
│ ← Edit Category            [Delete] │
├─────────────────────────────────────┤
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Name                            │ │
│ │ Food & Dining                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Icon                                │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │
│ │ 🍽️ │ │ 🍕 │ │ 🍔 │ │ 🥗 │    │
│ └─────┘ └─────┘ └─────┘ └─────┘    │
│ [See all icons]                     │
│                                     │
│ Color                               │
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐     │
│ │🔴│ │🟠│ │🟡│ │🟢│ │🔵│     │
│ └───┘ └───┘ └───┘ └───┘ └───┘     │
│                                     │
│ Parent Category                     │
│ [None (top-level) ▼]                │
│                                     │
│ Transactions using this: 45         │
│                                     │
│           [Save]                    │
│                                     │
└─────────────────────────────────────┘
```

## 7.3 Navigation Architecture

### 7.3.1 Information Architecture

```
App Root
├── Home (Dashboard)
│   ├── Wallet Selector
│   ├── Monthly Summary → Analytics
│   ├── AI Insight → AI Assistant
│   └── Recent Transactions → Transaction Detail
│
├── Analytics
│   ├── Overview
│   ├── Category Breakdown → Category Detail
│   ├── Trends
│   └── Premium Features (locked)
│
├── [+] Add Transaction (Modal)
│   ├── Expense (default)
│   ├── Income
│   └── Transfer
│
├── AI Assistant
│   └── Chat Interface
│
├── Settings
│   ├── Profile
│   ├── Premium
│   ├── Appearance
│   ├── Currency
│   ├── Language
│   ├── Notifications
│   ├── App Lock
│   ├── Categories → Category Manager
│   ├── Backup & Sync
│   ├── Export
│   └── About
│
└── Secondary (accessible from other screens)
    ├── Wallets
    ├── Budgets
    ├── Transactions List
    └── Transaction Detail → Edit
```

### 7.3.2 Navigation Patterns

| Pattern | Usage |
|---------|-------|
| **Bottom tabs** | Primary navigation (5 items) |
| **Modal** | Add transaction, quick actions |
| **Push** | Drill-down (list → detail) |
| **Back** | Standard navigation stack |
| **Swipe** | Go back, delete (with confirmation) |

### 7.3.3 Deep Linking

| Link | Destination |
|------|-------------|
| `finsor://home` | Dashboard |
| `finsor://add` | Add transaction |
| `finsor://budgets` | Budgets screen |
| `finsor://transaction/{id}` | Transaction detail |
| `finsor://ai` | AI Assistant |

## 7.4 Responsive Behavior

### 7.4.1 Phone (Primary)

- Single column layout
- Bottom navigation
- Full-screen modals
- Swipe gestures enabled

### 7.4.2 Tablet (Secondary)

- Two-column layout where appropriate
- Side navigation option
- Larger touch targets
- More data visible

### 7.4.3 Accessibility

| Requirement | Implementation |
|-------------|----------------|
| **Contrast** | 4.5:1 minimum (AA) |
| **Text scaling** | Support 200% system scale |
| **Touch targets** | 44×44pt minimum |
| **Screen readers** | Full VoiceOver/TalkBack support |
| **Reduce motion** | Respect system setting |
| **Color blindness** | Don't rely on color alone |

---

# 8. TECHNICAL ARCHITECTURE

## 8.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                               │
│                           (Flutter Mobile App)                          │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ Presentation│  │  Business   │  │    Data     │  │   Services  │    │
│  │   (Widgets) │  │   (BLoC/    │  │ (Repository)│  │  (Platform) │    │
│  │             │  │  Riverpod)  │  │             │  │             │    │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘    │
│         │                │                │                │           │
│         └────────────────┴────────────────┴────────────────┘           │
│                                   │                                     │
│                    ┌──────────────┴──────────────┐                     │
│                    │        LOCAL STORAGE        │                     │
│                    │     (Hive + Encryption)     │                     │
│                    └──────────────┬──────────────┘                     │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │
                              HTTPS/TLS 1.3
                                     │
┌────────────────────────────────────┼────────────────────────────────────┐
│                              BACKEND LAYER                              │
│                              (Supabase)                                 │
├────────────────────────────────────┴────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │    Auth     │  │  Database   │  │   Storage   │  │    Edge     │    │
│  │  (GoTrue)   │  │ (PostgreSQL)│  │   (S3)      │  │  Functions  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘  └──────┬──────┘    │
│                                                            │           │
└────────────────────────────────────────────────────────────┼───────────┘
                                                             │
                                                    ┌────────┴────────┐
                                                    │   EXTERNAL      │
                                                    │   SERVICES      │
                                                    │  • OpenAI API   │
                                                    │  • Exchange API │
                                                    └─────────────────┘
```

## 8.2 Frontend Architecture (Flutter)

### 8.2.1 State Management: Riverpod

**Why Riverpod:**
- Compile-time safety
- Better testability than Provider
- No context dependency
- Supports async operations natively

**Provider Structure:**

```dart
// Data providers
final transactionsProvider = AsyncNotifierProvider<TransactionsNotifier, List<Transaction>>(...);
final walletsProvider = AsyncNotifierProvider<WalletsNotifier, List<Wallet>>(...);
final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(...);
final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(...);

// Computed providers
final monthlyStatsProvider = Provider<MonthlyStats>((ref) {
  final transactions = ref.watch(transactionsProvider);
  return calculateMonthlyStats(transactions);
});

// Settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(...);

// Auth
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(...);
```

### 8.2.2 Navigation: GoRouter

**Route Configuration:**

```dart
final appRouter = GoRouter(
  initialLocation: '/home',
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    final isOnboarding = state.matchedLocation.startsWith('/onboarding');
    
    if (!isLoggedIn && !isOnboarding) return '/onboarding';
    if (isLoggedIn && isOnboarding) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
    ShellRoute(
      builder: (_, __, child) => MainNavigation(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => AnalyticsScreen()),
        GoRoute(path: '/ai', builder: (_, __) => AIScreen()),
        GoRoute(path: '/settings', builder: (_, __) => SettingsScreen()),
      ],
    ),
    GoRoute(
      path: '/transactions/:id',
      builder: (_, state) => TransactionDetailScreen(
        id: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

### 8.2.3 Local Database: Hive

**Why Hive:**
- Extremely fast (NoSQL)
- Built-in encryption support
- Flutter-optimized
- No native dependencies

**Schema:**

```dart
@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late double amount;
  
  @HiveField(2)
  late int type; // 0=expense, 1=income, 2=transfer
  
  @HiveField(3)
  late String categoryId;
  
  @HiveField(4)
  late String walletId;
  
  @HiveField(5)
  String? toWalletId;
  
  @HiveField(6)
  String? description;
  
  @HiveField(7)
  late DateTime createdAt;
  
  @HiveField(8)
  DateTime? updatedAt;
  
  @HiveField(9)
  late bool isRecurring;
  
  @HiveField(10)
  String? recurringPattern;
  
  @HiveField(11)
  late int state; // 0=pending, 1=cleared, 2=reconciled
  
  @HiveField(12)
  late bool syncedToCloud;
  
  @HiveField(13)
  DateTime? lastSyncAt;
}
```

**Encryption Setup:**

```dart
Future<void> initHive() async {
  await Hive.initFlutter();
  
  // Get or generate encryption key
  final secureStorage = FlutterSecureStorage();
  var key = await secureStorage.read(key: 'hive_encryption_key');
  
  if (key == null) {
    final newKey = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64Encode(newKey),
    );
    key = base64Encode(newKey);
  }
  
  final encryptionKey = base64Decode(key);
  
  // Open encrypted boxes
  await Hive.openBox<TransactionModel>(
    'transactions',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
}
```

### 8.2.4 Performance Optimizations

**Virtualized Lists:**

```dart
class TransactionListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      cacheExtent: 200, // Pre-render 200px ahead
      itemBuilder: (context, index) {
        return TransactionTile(
          key: ValueKey(transactions[index].id),
          transaction: transactions[index],
        );
      },
    );
  }
}
```

**Image Caching:**

```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (_, __) => CircularProgressIndicator(),
  errorWidget: (_, __, ___) => Icon(Icons.error),
  memCacheWidth: 100,
  memCacheHeight: 100,
);
```

**Lazy Loading:**

```dart
class AnalyticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(analyticsProvider).when(
      loading: () => AnalyticsSkeleton(),
      error: (e, _) => ErrorWidget(e),
      data: (data) => AnalyticsContent(data),
    );
  }
}
```

## 8.3 Backend Architecture (Supabase)

### 8.3.1 Authentication

**Supported Methods:**
- Email/Password
- Google OAuth
- Apple Sign-In

**Implementation:**

```dart
class AuthService {
  final supabase = Supabase.instance.client;
  
  Future<AuthResponse> signUp(String email, String password) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  Future<AuthResponse> signInWithGoogle() async {
    return await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'finsor://auth-callback',
    );
  }
  
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
  
  User? get currentUser => supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
```

### 8.3.2 Database Schema (PostgreSQL)

**Row Level Security (RLS):**

```sql
-- Enable RLS on all tables
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON transactions FOR DELETE
  USING (auth.uid() = user_id);
```

**Indexes:**

```sql
-- Performance-critical indexes
CREATE INDEX idx_transactions_user_date 
  ON transactions(user_id, created_at DESC);

CREATE INDEX idx_transactions_user_category 
  ON transactions(user_id, category_id, created_at);

CREATE INDEX idx_transactions_user_wallet 
  ON transactions(user_id, wallet_id, created_at);

CREATE INDEX idx_wallets_user 
  ON wallets(user_id);

CREATE INDEX idx_budgets_user_active 
  ON budgets(user_id, status) WHERE status = 'active';
```

### 8.3.3 Real-Time Sync

**Subscription Setup:**

```dart
class SyncService {
  late final RealtimeChannel _transactionChannel;
  
  void startSync() {
    _transactionChannel = supabase
      .channel('transactions')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: currentUser.id,
        ),
        callback: (payload) {
          switch (payload.eventType) {
            case PostgresChangeEvent.insert:
              _handleInsert(payload.newRecord);
              break;
            case PostgresChangeEvent.update:
              _handleUpdate(payload.newRecord);
              break;
            case PostgresChangeEvent.delete:
              _handleDelete(payload.oldRecord);
              break;
          }
        },
      )
      .subscribe();
  }
  
  void stopSync() {
    _transactionChannel.unsubscribe();
  }
}
```

### 8.3.4 Edge Functions (AI Processing)

**AI Insight Function:**

```typescript
// supabase/functions/ai-insight/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

serve(async (req) => {
  const { context, query, userId } = await req.json();
  
  // Validate request
  if (!context || !query) {
    return new Response(
      JSON.stringify({ error: "Missing required fields" }),
      { status: 400 }
    );
  }
  
  // Call OpenAI
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: SYSTEM_PROMPT,
        },
        {
          role: "user",
          content: `CONTEXT:\n${JSON.stringify(context)}\n\nQUERY: ${query}`,
        },
      ],
      max_tokens: 500,
      temperature: 0.7,
    }),
  });
  
  const data = await response.json();
  
  return new Response(
    JSON.stringify({
      response: data.choices[0].message.content,
    }),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

## 8.4 Offline-First Strategy

### 8.4.1 Architecture

```
┌─────────────────────────────────────────────────────┐
│                    USER ACTION                      │
│                (e.g., Add Transaction)              │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              WRITE TO LOCAL DB (Hive)               │
│                   (Immediate)                       │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              UPDATE UI STATE                        │
│            (Optimistic Update)                      │
└─────────────────────────┬───────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────┐
│              ADD TO SYNC QUEUE                      │
│           (Background Processing)                   │
└─────────────────────────┬───────────────────────────┘
                          │
           ┌──────────────┴──────────────┐
           │                             │
           ▼                             ▼
┌─────────────────────┐    ┌─────────────────────────┐
│   ONLINE: Sync      │    │   OFFLINE: Queue        │
│   immediately       │    │   for later             │
└─────────────────────┘    └─────────────────────────┘
```

### 8.4.2 Sync Queue Management

```dart
class SyncQueue {
  final Box<SyncOperation> _queue;
  
  Future<void> addOperation(SyncOperation op) async {
    await _queue.add(op);
    _attemptSync();
  }
  
  Future<void> _attemptSync() async {
    if (!await hasConnectivity()) return;
    
    final pending = _queue.values.where((op) => op.status == 'pending');
    
    for (final op in pending) {
      try {
        await _executeOperation(op);
        op.status = 'completed';
        await op.save();
      } catch (e) {
        op.retryCount++;
        op.lastError = e.toString();
        
        if (op.retryCount >= 3) {
          op.status = 'failed';
          _notifyUser(op);
        }
        
        await op.save();
      }
    }
    
    // Clean up completed operations
    await _queue.deleteAll(
      _queue.values
        .where((op) => op.status == 'completed')
        .map((op) => op.key),
    );
  }
}
```

### 8.4.3 Conflict Resolution

**Strategy: Last-Write-Wins with User Notification**

```dart
class ConflictResolver {
  Future<Transaction> resolve(
    Transaction local,
    Transaction remote,
  ) async {
    // If same version, no conflict
    if (local.updatedAt == remote.updatedAt) {
      return local;
    }
    
    // Simple case: Remote is newer
    if (remote.updatedAt.isAfter(local.updatedAt)) {
      // Check if local has unsaved changes
      if (local.hasUnsyncedChanges) {
        // Notify user of overwritten changes
        await _notifyConflict(local, remote);
      }
      return remote;
    }
    
    // Local is newer: Keep local, queue for sync
    return local;
  }
  
  Future<void> _notifyConflict(
    Transaction local,
    Transaction remote,
  ) async {
    // Show non-intrusive notification
    // User can tap to see details
    notificationService.show(
      title: 'Sync Conflict Resolved',
      body: 'A transaction was updated on another device',
      action: () => showConflictDetails(local, remote),
    );
  }
}
```

## 8.5 Database Migration Strategy

### 8.5.1 Version Management

```dart
class DatabaseMigrator {
  static const currentVersion = 3;
  
  Future<void> migrate() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt('db_version') ?? 0;
    
    if (storedVersion < currentVersion) {
      await _runMigrations(storedVersion, currentVersion);
      await prefs.setInt('db_version', currentVersion);
    }
  }
  
  Future<void> _runMigrations(int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      switch (v) {
        case 1:
          await _migrationV1();
          break;
        case 2:
          await _migrationV2();
          break;
        case 3:
          await _migrationV3();
          break;
      }
    }
  }
  
  Future<void> _migrationV2() async {
    // Example: Add new field to transactions
    final box = await Hive.openBox<TransactionModel>('transactions');
    
    for (final tx in box.values) {
      if (tx.state == null) {
        tx.state = 1; // Set default to 'cleared'
        await tx.save();
      }
    }
  }
}
```

### 8.5.2 Backward Compatibility

**Rules:**
1. Support reading data from N-2 versions
2. New fields must have defaults
3. Never delete fields, mark as deprecated
4. Export data before major migrations

---

# 9. SECURITY & PRIVACY

## 9.1 Security Architecture

### 9.1.1 Defense in Depth

```
┌─────────────────────────────────────────────────────────────┐
│                      LAYER 1: DEVICE                        │
│  • Biometric authentication                                 │
│  • Encrypted local storage (AES-256)                        │
│  • Secure key storage (Keychain/Keystore)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      LAYER 2: TRANSPORT                     │
│  • TLS 1.3 for all connections                             │
│  • Certificate pinning                                      │
│  • No sensitive data in URLs                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      LAYER 3: APPLICATION                   │
│  • JWT authentication                                       │
│  • Row-level security (RLS)                                │
│  • Input validation                                         │
│  • Rate limiting                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      LAYER 4: DATA                          │
│  • Database encryption at rest                             │
│  • Column-level encryption for sensitive fields            │
│  • Audit logging                                           │
└─────────────────────────────────────────────────────────────┘
```

## 9.2 Encryption

### 9.2.1 Local Encryption

**Implementation:**

```dart
class EncryptionService {
  late final Uint8List _key;
  
  Future<void> initialize() async {
    final storage = FlutterSecureStorage();
    
    // Try to get existing key
    var keyString = await storage.read(key: 'master_key');
    
    if (keyString == null) {
      // Generate new key
      final random = Random.secure();
      final key = List<int>.generate(32, (_) => random.nextInt(256));
      keyString = base64Encode(key);
      
      // Store in secure storage (Keychain/Keystore)
      await storage.write(key: 'master_key', value: keyString);
    }
    
    _key = base64Decode(keyString);
  }
  
  Uint8List encrypt(Uint8List data) {
    final iv = _generateIV();
    final cipher = AES(Key(_key), mode: AESMode.gcm);
    final encrypted = cipher.encrypt(data, iv: IV(iv));
    
    // Prepend IV to encrypted data
    return Uint8List.fromList([...iv, ...encrypted.bytes]);
  }
  
  Uint8List decrypt(Uint8List data) {
    final iv = data.sublist(0, 12);
    final encrypted = data.sublist(12);
    
    final cipher = AES(Key(_key), mode: AESMode.gcm);
    return cipher.decrypt(Encrypted(encrypted), iv: IV(iv));
  }
}
```

### 9.2.2 Transit Encryption

**Certificate Pinning:**

```dart
class SecureHttpClient {
  final dio = Dio();
  
  SecureHttpClient() {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      
      client.badCertificateCallback = (cert, host, port) {
        // Verify certificate fingerprint
        final fingerprint = sha256.convert(cert.der).toString();
        return _trustedFingerprints.contains(fingerprint);
      };
      
      return client;
    };
  }
  
  static const _trustedFingerprints = [
    'abc123...', // Production cert
    'def456...', // Backup cert
  ];
}
```

### 9.2.3 At-Rest Encryption (Cloud)

**Supabase Configuration:**

```sql
-- Enable encryption for sensitive columns
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypt transaction descriptions
ALTER TABLE transactions
  ADD COLUMN description_encrypted BYTEA;

-- Encryption function
CREATE OR REPLACE FUNCTION encrypt_description(text_value TEXT)
RETURNS BYTEA AS $$
BEGIN
  RETURN pgp_sym_encrypt(
    text_value,
    current_setting('app.encryption_key'),
    'cipher-algo=aes256'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 9.3 Authentication

### 9.3.1 Biometric Authentication

```dart
class BiometricAuth {
  final _localAuth = LocalAuthentication();
  
  Future<bool> authenticate() async {
    // Check if biometrics available
    final canAuth = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    
    if (!canAuth || !isSupported) {
      return false;
    }
    
    // Authenticate
    return await _localAuth.authenticate(
      localizedReason: 'Unlock Finsor',
      options: AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
  
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }
}
```

### 9.3.2 Session Management

**Rules:**
- JWT expiration: 1 hour
- Refresh token expiration: 30 days
- Auto-lock after 15 minutes of inactivity
- Force re-auth for sensitive operations

```dart
class SessionManager {
  Timer? _inactivityTimer;
  
  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(minutes: 15),
      () => _lockApp(),
    );
  }
  
  void _lockApp() {
    // Clear sensitive data from memory
    // Show lock screen
    navigatorKey.currentState?.pushReplacementNamed('/lock');
  }
  
  void onUserActivity() {
    resetInactivityTimer();
  }
}
```

### 9.3.3 Secure Token Storage

**Platform-Specific:**

| Platform | Storage | Security |
|----------|---------|----------|
| iOS | Keychain | Hardware-backed, encrypted |
| Android | Keystore | Hardware-backed (if available) |

```dart
class TokenStorage {
  final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

## 9.4 Privacy

### 9.4.1 Local-First Architecture

**Default Behavior:**
- All data stored locally first
- Cloud sync is opt-in
- App works 100% offline
- No data collection without consent

### 9.4.2 Data Minimization

**What We Collect:**

| Data | Collected | Purpose | Retention |
|------|-----------|---------|-----------|
| Email | Yes (if account) | Authentication | Account lifetime |
| Transactions | No (local only) | Core functionality | User-controlled |
| Analytics | Anonymized only | App improvement | 90 days |
| Crash reports | Yes (opt-in) | Bug fixes | 30 days |

**What We DON'T Collect:**
- Transaction descriptions (cloud)
- Merchant names (cloud)
- Location data
- Contact information
- Device identifiers (for ads)

### 9.4.3 GDPR Compliance

**User Rights Implementation:**

| Right | Implementation |
|-------|----------------|
| **Access** | Export all data (JSON/CSV) |
| **Rectification** | Edit any data in app |
| **Erasure** | Delete account + all data |
| **Portability** | Export in machine-readable format |
| **Restriction** | Pause cloud sync |
| **Object** | Opt-out of analytics |

**Data Export:**

```dart
class DataExporter {
  Future<File> exportAllData() async {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'user': await _exportUser(),
      'wallets': await _exportWallets(),
      'transactions': await _exportTransactions(),
      'categories': await _exportCategories(),
      'budgets': await _exportBudgets(),
    };
    
    final json = jsonEncode(data);
    final file = await _getExportFile();
    await file.writeAsString(json);
    
    return file;
  }
}
```

**Account Deletion:**

```dart
class AccountDeleter {
  Future<void> deleteAccount() async {
    // 1. Delete cloud data
    await supabase.rpc('delete_user_data', params: {
      'user_id': currentUser.id,
    });
    
    // 2. Delete local data
    await Hive.deleteFromDisk();
    
    // 3. Clear secure storage
    await FlutterSecureStorage().deleteAll();
    
    // 4. Delete auth account
    await supabase.auth.admin.deleteUser(currentUser.id);
    
    // 5. Sign out
    await supabase.auth.signOut();
  }
}
```

### 9.4.4 Privacy Policy Requirements

**Must Include:**
- What data is collected
- How data is used
- Data retention periods
- Third-party sharing (none)
- User rights
- Contact information
- Update notification process

### 9.4.5 Analytics (Privacy-Safe)

**If analytics are used:**

```dart
class PrivacyAnalytics {
  // Only track anonymized, aggregate events
  void trackEvent(String name, {Map<String, dynamic>? params}) {
    // Remove any PII
    final safeParams = _sanitizeParams(params);
    
    // Use privacy-focused service (e.g., Plausible, Umami)
    analytics.track(name, safeParams);
  }
  
  Map<String, dynamic>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;
    
    final safe = Map<String, dynamic>.from(params);
    
    // Remove any potentially identifying info
    safe.remove('email');
    safe.remove('name');
    safe.remove('user_id');
    
    // Round amounts to prevent fingerprinting
    if (safe.containsKey('amount')) {
      safe['amount'] = (safe['amount'] / 10).round() * 10;
    }
    
    return safe;
  }
}
```

## 9.5 Security Checklist

### 9.5.1 Before Launch

- [ ] All data encrypted at rest
- [ ] TLS 1.3 enforced
- [ ] Certificate pinning enabled
- [ ] Biometric auth tested on all devices
- [ ] Session timeout working
- [ ] RLS policies tested
- [ ] Penetration testing completed
- [ ] OWASP Mobile Top 10 addressed
- [ ] Privacy policy reviewed by legal
- [ ] GDPR compliance verified

### 9.5.2 Ongoing

- [ ] Security updates within 72 hours
- [ ] Quarterly security review
- [ ] Dependency vulnerability scanning
- [ ] Access logs monitored
- [ ] Incident response plan tested

---

# 10. SETTINGS & CUSTOMIZATION

## 10.1 Settings Overview

All user-configurable options organized by category.

## 10.2 Display Settings

### 10.2.1 Theme

| Option | Value | Default |
|--------|-------|---------|
| **Mode** | Light / Dark / System | System |
| **Accent Color** | Blue / Green / Purple / Orange | Blue |
| **Pure Black Dark** | On / Off | Off (OLED optimization) |

### 10.2.2 Language

**Supported Languages (Phase 1):**
- English (en)
- Russian (ru)
- Spanish (es)
- German (de)
- French (fr)

**Implementation:**
- Uses system locale as default
- User can override
- Restart not required

### 10.2.3 Number Formatting

| Option | Description | Default |
|--------|-------------|---------|
| **Decimal separator** | . or , | Locale-based |
| **Thousands separator** | , or . or space | Locale-based |
| **Negative format** | -$100 or ($100) | -$100 |

## 10.3 Currency Settings

### 10.3.1 Base Currency

**Purpose:** Currency used for reports and totals

**Options:**
- All ISO 4217 currencies
- Popular currencies shown first
- Search available

### 10.3.2 Currency Display

| Option | Values | Default |
|--------|--------|---------|
| **Symbol position** | Before ($100) / After (100$) | Locale-based |
| **Decimal places** | 0 / 2 / Auto | 2 |
| **Show currency code** | Always / Never / Multi-currency only | Multi-currency only |

### 10.3.3 Exchange Rates

| Option | Values | Default |
|--------|--------|---------|
| **Rate source** | Auto (daily) / Manual | Auto |
| **Update frequency** | Daily / Weekly | Daily |
| **Show rate changes** | On / Off | On |

## 10.4 Security Settings

### 10.4.1 App Lock

| Option | Values | Default |
|--------|--------|---------|
| **Enable app lock** | On / Off | Off |
| **Lock method** | Biometric / PIN / Both | Biometric |
| **Lock timeout** | Immediately / 1 min / 5 min / 15 min | Immediately |
| **Lock on background** | On / Off | On |

### 10.4.2 PIN Setup

```
Requirements:
- 4-6 digits
- Cannot be sequential (1234)
- Cannot be repeated (1111)
- Stored securely (hashed)
```

### 10.4.3 Sensitive Data

| Option | Values | Default |
|--------|--------|---------|
| **Hide balances** | On / Off | Off |
| **Blur on screenshot** | On / Off | Off |
| **Hide from recent apps** | On / Off | Off |

## 10.5 Data Settings

### 10.5.1 Backup & Sync

| Option | Values | Default |
|--------|--------|---------|
| **Enable cloud sync** | On / Off | Off |
| **Sync frequency** | Real-time / Hourly / Daily | Real-time |
| **Sync on Wi-Fi only** | On / Off | Off |
| **Auto backup** | On / Off | Off |
| **Backup frequency** | Daily / Weekly | Weekly |

### 10.5.2 Export Options

| Format | Contents | Availability |
|--------|----------|--------------|
| **CSV** | Transactions only | Free |
| **JSON** | All data | Free |
| **PDF Report** | Summary + charts | Premium |
| **Excel (XLSX)** | Full workbook | Premium |

**Export Filters:**
- Date range
- Wallets
- Categories
- Transaction types

### 10.5.3 Data Management

| Action | Description | Confirmation |
|--------|-------------|--------------|
| **Clear cache** | Remove temporary files | Single tap |
| **Reset categories** | Restore default categories | Double confirm |
| **Delete all data** | Remove all local data | Type "DELETE" |
| **Delete account** | Remove account + cloud data | Email verification |

## 10.6 AI Settings

### 10.6.1 AI Assistant

| Option | Values | Default |
|--------|--------|---------|
| **Enable AI** | On / Off | On |
| **Cloud processing** | Allow / Local only | Allow |
| **Auto-categorization** | On / Off | On |
| **Confidence threshold** | Low / Medium / High | Medium |

### 10.6.2 Insight Preferences

| Option | Values | Default |
|--------|--------|---------|
| **Show insights** | On / Off | On |
| **Insight frequency** | Daily / Weekly / When significant | When significant |
| **Verbosity** | Brief / Detailed | Brief |
| **Proactive alerts** | On / Off | On |

## 10.7 Notification Settings

### 10.7.1 Budget Alerts

| Option | Values | Default |
|--------|--------|---------|
| **Enable alerts** | On / Off | On |
| **50% threshold** | On / Off | Off |
| **80% threshold** | On / Off | On |
| **100% threshold** | On / Off | On |
| **Daily summary** | On / Off | Off |

### 10.7.2 Recurring Reminders

| Option | Values | Default |
|--------|--------|---------|
| **Upcoming bills** | On / Off | On |
| **Reminder timing** | 1 day / 3 days / 1 week before | 1 day |
| **Missed recurring** | On / Off | On |

### 10.7.3 AI Notifications

| Option | Values | Default |
|--------|--------|---------|
| **Spending alerts** | On / Off | On |
| **Weekly summary** | On / Off | Off |
| **Tips & suggestions** | On / Off | On |

### 10.7.4 Notification Delivery

| Option | Values | Default |
|--------|--------|---------|
| **Sound** | On / Off | On |
| **Vibration** | On / Off | On |
| **Quiet hours** | Set time range | Off |

## 10.8 Default Values

### 10.8.1 Transaction Defaults

| Setting | Options | Default |
|---------|---------|---------|
| **Default wallet** | Any wallet / Last used | Last used |
| **Default type** | Expense / Income | Expense |
| **Remember category** | On / Off | On |
| **Auto date** | Today / Ask each time | Today |

### 10.8.2 Budget Defaults

| Setting | Options | Default |
|---------|---------|---------|
| **Period start** | 1st / Last paycheck / Custom | 1st |
| **Week starts** | Sunday / Monday | Monday |
| **Default budget type** | Category / Total | Category |

## 10.9 About & Legal

### 10.9.1 App Information

- Version number
- Build number
- Device info
- Support contact
- Rate the app link
- Share app link

### 10.9.2 Legal Documents

- Privacy Policy
- Terms of Service
- Open Source Licenses
- Cookie Policy (web)

---

# 11. EDGE CASES & FAILURE MODES

## 11.1 App Lifecycle

### 11.1.1 App Reinstall

**Scenario:** User uninstalls and reinstalls app

**Behavior:**
1. Check for existing local data (may persist on some devices)
2. If found, prompt: "We found existing data. Restore?"
3. If cloud sync enabled, prompt to sign in for restore
4. If declined/no data, start fresh onboarding

**Edge Cases:**
- Partial data found: Validate integrity, restore what's valid
- Cloud data exists but different user: Warn before overwrite

### 11.1.2 Data Corruption

**Detection:**
- Checksum validation on app start
- Schema version check
- Foreign key integrity check

**Recovery Steps:**
1. Attempt automatic repair (orphaned records)
2. If repair fails, check for local backup
3. If backup exists, prompt restore
4. If no backup, offer cloud restore (if enabled)
5. Last resort: Start fresh with empty data

**User Communication:**
```
⚠️ We detected an issue with your data

Some transactions couldn't be loaded. We found a backup 
from yesterday that can restore your data.

[Restore Backup]  [Continue Anyway]  [Contact Support]
```

### 11.1.3 Version Upgrade

**Scenario:** User updates to new app version with breaking changes

**Migration Flow:**
1. Show migration screen (prevent interaction)
2. Backup current data
3. Run migrations sequentially
4. Validate migrated data
5. If success, continue to app
6. If failure, rollback and show error

**Breaking Changes:**
- New required fields: Provide sensible defaults
- Schema changes: Transform existing data
- Removed features: Archive affected data

### 11.1.4 App Backgrounded/Killed

**During Transaction Entry:**
- Draft auto-saved every 2 seconds
- On return, prompt to resume or discard

**During Sync:**
- Mark sync as interrupted
- Resume on next app open
- Track last successful sync point

## 11.2 Sync Issues

### 11.2.1 Partial Sync Failure

**Scenario:** Some records sync, others fail

**Handling:**
1. Mark failed records with `sync_failed` flag
2. Continue syncing other records
3. Show count of failed items
4. Retry failed items on next sync
5. After 3 failures, alert user

**UI:**
```
┌─────────────────────────────────────┐
│ ⚠️ Sync issue                       │
│                                     │
│ 3 transactions couldn't sync.       │
│ They're saved locally and will      │
│ retry automatically.                │
│                                     │
│ [View Details]  [Retry Now]         │
└─────────────────────────────────────┘
```

### 11.2.2 Conflict Resolution

**Types of Conflicts:**

| Conflict | Resolution | User Action |
|----------|------------|-------------|
| **Same field edited** | Last-write-wins | Notification |
| **Deleted locally, edited remotely** | Keep remote | Notification |
| **Deleted remotely, edited locally** | Keep local | Notification |
| **Different fields edited** | Merge both | Auto-merge |

**Complex Conflict (rare):**
```
┌─────────────────────────────────────┐
│ Sync Conflict                       │
│                                     │
│ This transaction was edited on      │
│ two devices at the same time.       │
│                                     │
│ Your version:                       │
│ $45.00 · Food · Feb 5               │
│                                     │
│ Other version:                      │
│ $42.00 · Groceries · Feb 5          │
│                                     │
│ [Keep Mine]  [Keep Other]  [Merge]  │
└─────────────────────────────────────┘
```

### 11.2.3 Offline Duration

**Short Offline (< 1 day):**
- Queue operations normally
- Sync when back online
- No special handling

**Medium Offline (1-7 days):**
- Warn about pending sync
- Prioritize critical data
- Batch sync for efficiency

**Long Offline (> 7 days):**
- Alert user before sync
- Offer selective sync
- Show potential conflicts
- Suggest backup first

### 11.2.4 Network Timeout

**Handling:**
- Timeout after 30 seconds
- Retry with exponential backoff
- Max 3 automatic retries
- Show retry button after failure

## 11.3 User Errors

### 11.3.1 Duplicate Transactions

**Detection Algorithm:**
```
potential_duplicate = (
  same_amount AND
  same_date AND
  same_wallet AND
  similar_description (fuzzy match > 80%)
)
```

**User Flow:**
1. On save, check for potential duplicates
2. If found, show warning:
   ```
   ⚠️ Possible duplicate
   
   You already have a similar transaction:
   $45.00 · Starbucks · Today
   
   [Save Anyway]  [View Existing]  [Cancel]
   ```

**Bulk Detection:**
- Weekly scan for duplicates
- AI-assisted grouping
- Merge suggestion in Insights

### 11.3.2 Category Deletion with Transactions

**Scenario:** User deletes category that has transactions

**Options:**
1. **Reassign:** Move to another category
2. **Archive:** Hide but preserve
3. **Block:** Prevent deletion until empty

**Implementation (Reassign):**
```
┌─────────────────────────────────────┐
│ Delete "Subscriptions"?             │
│                                     │
│ 15 transactions use this category.  │
│                                     │
│ Move them to:                       │
│ [Select category         ▼]        │
│                                     │
│ [Cancel]  [Delete & Move]           │
└─────────────────────────────────────┘
```

### 11.3.3 Wallet Deletion

**Rule:** Never truly delete wallets with history

**Behavior:**
1. Archive wallet (hide from active list)
2. Preserve all historical transactions
3. Remove from balance totals (optional)
4. Allow restore anytime

**UI:**
```
┌─────────────────────────────────────┐
│ Archive "Old Savings"?              │
│                                     │
│ This wallet has 45 transactions.    │
│ It will be hidden but not deleted.  │
│                                     │
│ You can restore it anytime from     │
│ Settings > Wallets > Archived.      │
│                                     │
│ [Cancel]  [Archive Wallet]          │
└─────────────────────────────────────┘
```

### 11.3.4 Accidental Deletion

**Transaction Deletion:**
- Show undo toast for 5 seconds
- Soft delete (recoverable for 30 days)
- Bulk delete requires confirmation

**Undo Toast:**
```
┌─────────────────────────────────────┐
│ Transaction deleted         [Undo]  │
└─────────────────────────────────────┘
```

## 11.4 AI Errors

### 11.4.1 Wrong Categorization

**User Correction Flow:**
1. User taps category on transaction
2. Changes to correct category
3. Prompt: "Should Finsor learn from this?"
4. If yes, update learning model
5. Apply to similar pending suggestions

**Learning Feedback:**
```dart
class AILearning {
  Future<void> recordCorrection(
    String merchantPattern,
    String wrongCategory,
    String correctCategory,
  ) async {
    // Store correction
    await db.corrections.add({
      'pattern': merchantPattern,
      'wrong': wrongCategory,
      'correct': correctCategory,
      'timestamp': DateTime.now(),
    });
    
    // Update local model
    await _updateLocalPredictions(merchantPattern, correctCategory);
    
    // Queue for cloud learning (anonymized)
    if (settings.cloudLearning) {
      await syncQueue.add(SyncOperation.aiCorrection(
        merchantPattern,
        correctCategory,
      ));
    }
  }
}
```

### 11.4.2 AI Response Errors

**Nonsensical Response:**
- Detect via response validation
- Fallback to template response
- Log for investigation

**Validation:**
```dart
bool isValidResponse(String response) {
  // Check for empty/too short
  if (response.length < 20) return false;
  
  // Check for error indicators
  if (response.contains('I cannot') && response.contains('error')) {
    return false;
  }
  
  // Check for hallucinated numbers not in context
  final numbers = extractNumbers(response);
  for (final num in numbers) {
    if (!contextContains(num)) {
      return false; // Likely hallucination
    }
  }
  
  return true;
}
```

**Fallback Response:**
```
I'm having trouble generating a response right now. 
Here's what I can tell you:

• Your total spending this month: $3,780
• Top category: Food & Dining ($580)
• Budget status: 81% used

Try asking a specific question, or check back later.
```

### 11.4.3 API Timeout

**Timeout Handling:**
1. Show loading for max 10 seconds
2. If timeout, show fallback
3. Cache successful responses
4. Retry in background

**Fallback:**
```
┌─────────────────────────────────────┐
│ 🤖 AI is taking longer than usual   │
│                                     │
│ Here's a quick summary instead:     │
│                                     │
│ • Income: $5,250                    │
│ • Expenses: $3,780                  │
│ • Net: +$1,470                      │
│                                     │
│ [Try Again]                         │
└─────────────────────────────────────┘
```

## 11.5 Analytics Inconsistencies

### 11.5.1 Balance Mismatch

**Scenario:** Calculated balance doesn't match expected

**Detection:**
```dart
void validateBalance(Wallet wallet) {
  final calculated = calculateBalance(wallet);
  final stored = wallet.currentBalance;
  
  if ((calculated - stored).abs() > 0.01) {
    // Mismatch detected
    logWarning('Balance mismatch: $calculated vs $stored');
    
    // Auto-fix
    wallet.currentBalance = calculated;
    wallet.save();
    
    // Notify if significant
    if ((calculated - stored).abs() > 10) {
      showBalanceCorrectionNotice(stored, calculated);
    }
  }
}
```

### 11.5.2 Missing Transactions in Reports

**Possible Causes:**
- Filter accidentally applied
- Date range mismatch
- Wallet excluded
- Category archived

**Debug Helper:**
```
┌─────────────────────────────────────┐
│ Missing transactions?               │
│                                     │
│ Check your filters:                 │
│ • Date range: Feb 1-28              │
│ • Wallets: All (3 active)           │
│ • Categories: All (no exclusions)   │
│ • Types: Expense + Income           │
│                                     │
│ [Clear All Filters]                 │
└─────────────────────────────────────┘
```

---

# 12. QA & TESTING REQUIREMENTS

## 12.1 Testing Strategy

### 12.1.1 Test Pyramid

```
            /\
           /  \        E2E Tests (10%)
          /    \       - Critical user journeys
         /──────\      - Store submission checks
        /        \     
       /          \    Integration Tests (30%)
      /            \   - API contracts
     /──────────────\  - Database operations
    /                \ - Sync flows
   /                  \
  /                    \ Unit Tests (60%)
 /                      \ - Business logic
/________________________\ - Calculations
                          - Validators
```

### 12.1.2 Test Coverage Targets

| Layer | Target | Minimum |
|-------|--------|---------|
| Unit Tests | 80% | 70% |
| Widget Tests | 60% | 50% |
| Integration Tests | 40% | 30% |
| E2E Tests | Critical paths only | - |

## 12.2 Unit Testing

### 12.2.1 Business Logic Tests

**Budget Calculations:**
```dart
group('Budget Calculations', () {
  test('calculates remaining amount correctly', () {
    final budget = Budget(amount: 500, spent: 320);
    expect(budget.remaining, equals(180));
  });
  
  test('calculates pace indicator correctly', () {
    final budget = Budget(
      amount: 600,
      spent: 300,
      startDate: DateTime(2026, 2, 1),
      endDate: DateTime(2026, 2, 28),
    );
    
    // Day 14 of 28 (50% elapsed), spent 50%
    final pace = budget.calculatePace(DateTime(2026, 2, 14));
    expect(pace, equals(BudgetPace.onTrack));
  });
  
  test('rollover adds to next period', () {
    final current = Budget(amount: 500, spent: 400); // $100 surplus
    final next = Budget.createNext(current, rollover: true);
    
    expect(next.amount, equals(600)); // 500 + 100 rollover
  });
  
  test('handles overspending in rollover', () {
    final current = Budget(amount: 500, spent: 550); // $50 deficit
    final next = Budget.createNext(current, rollover: true);
    
    expect(next.amount, equals(450)); // 500 - 50 rollover debt
  });
});
```

**Balance Calculations:**
```dart
group('Wallet Balance', () {
  test('calculates from transactions correctly', () {
    final wallet = Wallet(initialBalance: 1000);
    final transactions = [
      Transaction(type: income, amount: 500),
      Transaction(type: expense, amount: 200),
      Transaction(type: expense, amount: 150),
    ];
    
    final balance = calculateBalance(wallet, transactions);
    expect(balance, equals(1150)); // 1000 + 500 - 200 - 150
  });
  
  test('handles transfers correctly', () {
    final walletA = Wallet(id: 'a', initialBalance: 1000);
    final transfer = Transaction(
      type: transfer,
      amount: 300,
      walletId: 'a',
      toWalletId: 'b',
    );
    
    final balanceA = calculateBalance(walletA, [transfer]);
    expect(balanceA, equals(700)); // 1000 - 300
  });
});
```

### 12.2.2 Data Transformation Tests

**Currency Formatting:**
```dart
group('Currency Formatter', () {
  test('formats USD correctly', () {
    expect(formatCurrency(1234.56, 'USD'), equals('\$1,234.56'));
  });
  
  test('formats EUR correctly', () {
    expect(formatCurrency(1234.56, 'EUR'), equals('€1.234,56'));
  });
  
  test('handles negative amounts', () {
    expect(formatCurrency(-50.00, 'USD'), equals('-\$50.00'));
  });
  
  test('respects decimal settings', () {
    expect(
      formatCurrency(100, 'USD', decimals: 0),
      equals('\$100'),
    );
  });
});
```

### 12.2.3 AI Prompt Generation Tests

```dart
group('AI Context Builder', () {
  test('anonymizes transaction data', () {
    final transactions = [
      Transaction(description: 'STARBUCKS #1234', amount: 5.50),
    ];
    
    final context = buildAIContext(transactions);
    
    expect(context, isNot(contains('STARBUCKS')));
    expect(context, isNot(contains('1234')));
    expect(context, contains('Coffee')); // Normalized category
  });
  
  test('aggregates by category', () {
    final transactions = [
      Transaction(category: 'food', amount: 100),
      Transaction(category: 'food', amount: 50),
    ];
    
    final context = buildAIContext(transactions);
    
    expect(context['categoryBreakdown']['food'], equals(150));
  });
  
  test('limits context size', () {
    final manyTransactions = List.generate(
      1000,
      (i) => Transaction(amount: 10),
    );
    
    final context = buildAIContext(manyTransactions);
    final tokenCount = estimateTokens(jsonEncode(context));
    
    expect(tokenCount, lessThan(2000));
  });
});
```

## 12.3 Widget Testing

### 12.3.1 Form Validation Tests

```dart
group('Add Transaction Form', () {
  testWidgets('shows error for zero amount', (tester) async {
    await tester.pumpWidget(AddTransactionScreen());
    
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    
    expect(find.text('Enter an amount'), findsOneWidget);
  });
  
  testWidgets('shows error for missing category', (tester) async {
    await tester.pumpWidget(AddTransactionScreen());
    
    await tester.enterText(find.byKey(Key('amount')), '50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    
    expect(find.text('Select a category'), findsOneWidget);
  });
  
  testWidgets('saves valid transaction', (tester) async {
    await tester.pumpWidget(
      ProviderScope(child: AddTransactionScreen()),
    );
    
    await tester.enterText(find.byKey(Key('amount')), '50');
    await tester.tap(find.byKey(Key('category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    
    expect(find.byType(AddTransactionScreen), findsNothing);
  });
});
```

### 12.3.2 Chart Rendering Tests

```dart
group('Analytics Charts', () {
  testWidgets('renders pie chart with data', (tester) async {
    final data = [
      CategorySpend('Food', 300),
      CategorySpend('Transport', 150),
    ];
    
    await tester.pumpWidget(SpendingPieChart(data: data));
    await tester.pumpAndSettle();
    
    expect(find.byType(PieChart), findsOneWidget);
  });
  
  testWidgets('shows empty state with no data', (tester) async {
    await tester.pumpWidget(SpendingPieChart(data: []));
    await tester.pumpAndSettle();
    
    expect(find.text('No spending data'), findsOneWidget);
  });
});
```

### 12.3.3 State Transition Tests

```dart
group('Budget Card States', () {
  testWidgets('shows on-track state', (tester) async {
    final budget = Budget(amount: 600, spent: 200); // 33%
    
    await tester.pumpWidget(BudgetCard(budget: budget));
    
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('On Track'), findsOneWidget);
  });
  
  testWidgets('shows warning state', (tester) async {
    final budget = Budget(amount: 600, spent: 500); // 83%
    
    await tester.pumpWidget(BudgetCard(budget: budget));
    
    expect(find.byIcon(Icons.warning), findsOneWidget);
    expect(find.text('Approaching Limit'), findsOneWidget);
  });
  
  testWidgets('shows over-budget state', (tester) async {
    final budget = Budget(amount: 600, spent: 650); // 108%
    
    await tester.pumpWidget(BudgetCard(budget: budget));
    
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.text('Over Budget'), findsOneWidget);
  });
});
```

## 12.4 Integration Testing

### 12.4.1 Transaction CRUD Flow

```dart
group('Transaction Integration', () {
  late FinsorTestApp app;
  
  setUp(() async {
    app = await FinsorTestApp.create();
  });
  
  tearDown(() async {
    await app.cleanup();
  });
  
  test('complete transaction lifecycle', () async {
    // Create
    final transaction = await app.createTransaction(
      amount: 50,
      category: 'Food',
      wallet: 'Main',
    );
    
    expect(transaction.id, isNotEmpty);
    expect(await app.getTransaction(transaction.id), isNotNull);
    
    // Read
    final fetched = await app.getTransaction(transaction.id);
    expect(fetched!.amount, equals(50));
    
    // Update
    await app.updateTransaction(transaction.id, amount: 55);
    final updated = await app.getTransaction(transaction.id);
    expect(updated!.amount, equals(55));
    
    // Delete
    await app.deleteTransaction(transaction.id);
    expect(await app.getTransaction(transaction.id), isNull);
  });
});
```

### 12.4.2 Sync Cycle Tests

```dart
group('Sync Integration', () {
  test('syncs new transaction to cloud', () async {
    // Create locally
    final local = await localDb.createTransaction(testTransaction);
    
    // Trigger sync
    await syncService.sync();
    
    // Verify in cloud
    final remote = await cloudDb.getTransaction(local.id);
    expect(remote, isNotNull);
    expect(remote!.amount, equals(local.amount));
  });
  
  test('handles offline queue', () async {
    // Go offline
    await networkService.setOffline();
    
    // Create transactions
    await localDb.createTransaction(tx1);
    await localDb.createTransaction(tx2);
    
    // Verify queue
    expect(syncQueue.pendingCount, equals(2));
    
    // Go online
    await networkService.setOnline();
    await syncService.sync();
    
    // Verify synced
    expect(syncQueue.pendingCount, equals(0));
  });
  
  test('resolves conflict correctly', () async {
    // Create same transaction on both devices
    final tx = Transaction(id: 'test-123', amount: 50);
    await device1.createTransaction(tx);
    await device2.createTransaction(tx);
    
    // Modify on device 1
    await device1.updateTransaction('test-123', amount: 55);
    
    // Modify on device 2 (later)
    await Future.delayed(Duration(seconds: 1));
    await device2.updateTransaction('test-123', amount: 60);
    
    // Sync both
    await device1.sync();
    await device2.sync();
    await device1.sync(); // Pull latest
    
    // Last write wins
    final final1 = await device1.getTransaction('test-123');
    final final2 = await device2.getTransaction('test-123');
    
    expect(final1!.amount, equals(60));
    expect(final2!.amount, equals(60));
  });
});
```

### 12.4.3 AI Conversation Tests

```dart
group('AI Integration', () {
  test('responds to spending query', () async {
    // Seed data
    await seedTransactions([
      Transaction(category: 'Food', amount: 500),
      Transaction(category: 'Transport', amount: 200),
    ]);
    
    // Ask question
    final response = await aiService.query(
      'What is my biggest expense?',
    );
    
    // Verify response mentions Food
    expect(response.toLowerCase(), contains('food'));
    expect(response, contains('500'));
  });
  
  test('handles empty data gracefully', () async {
    // No transactions
    final response = await aiService.query(
      'How much did I spend?',
    );
    
    expect(response, contains('no transaction'));
    expect(response, isNot(contains('error')));
  });
});
```

## 12.5 Performance Testing

### 12.5.1 Benchmarks

| Operation | Target | Maximum |
|-----------|--------|---------|
| Cold start | <2s | 3s |
| Transaction save | <500ms | 1s |
| Dashboard load (1k tx) | <1s | 2s |
| Dashboard load (10k tx) | <2s | 3s |
| Search (10k tx) | <300ms | 500ms |
| Analytics render | <1s | 2s |
| Export (1k tx) | <2s | 5s |

### 12.5.2 Performance Test Suite

```dart
group('Performance', () {
  test('dashboard loads under 2s with 10k transactions', () async {
    // Seed 10k transactions
    await seedTransactions(count: 10000);
    
    final stopwatch = Stopwatch()..start();
    await dashboardProvider.refresh();
    stopwatch.stop();
    
    expect(stopwatch.elapsedMilliseconds, lessThan(2000));
  });
  
  test('list scrolls at 60fps', () async {
    await seedTransactions(count: 1000);
    
    await tester.pumpWidget(TransactionListScreen());
    
    final fps = await tester.fling(
      find.byType(ListView),
      Offset(0, -500),
      1000,
    );
    
    expect(fps, greaterThan(55));
  });
  
  test('memory stays under 200MB', () async {
    await seedTransactions(count: 10000);
    await dashboardProvider.refresh();
    await analyticsProvider.loadAll();
    
    final memoryUsage = await getMemoryUsage();
    expect(memoryUsage, lessThan(200 * 1024 * 1024));
  });
});
```

## 12.6 Device Testing Matrix

### 12.6.1 iOS Devices

| Device | iOS Version | Priority |
|--------|-------------|----------|
| iPhone 15 Pro | 17.x | P0 |
| iPhone 14 | 17.x, 16.x | P0 |
| iPhone 12 | 16.x, 15.x | P1 |
| iPhone SE (3rd) | 16.x | P1 |
| iPad Pro 12.9" | 17.x | P2 |
| iPad (9th gen) | 16.x | P2 |

### 12.6.2 Android Devices

| Device | Android Version | Priority |
|--------|-----------------|----------|
| Pixel 8 | 14 | P0 |
| Pixel 6 | 14, 13 | P0 |
| Samsung S23 | 14 | P0 |
| Samsung A54 | 13 | P1 |
| Redmi Note 12 | 13 | P1 |
| OnePlus Nord | 13 | P2 |

### 12.6.3 Screen Sizes

| Size | Resolution | Priority |
|------|------------|----------|
| Compact phone | 360×640 | P0 |
| Standard phone | 390×844 | P0 |
| Large phone | 430×932 | P1 |
| Small tablet | 744×1133 | P2 |
| Large tablet | 1024×1366 | P2 |

## 12.7 Regression Testing

### 12.7.1 Critical Path Tests

**Must pass before every release:**

1. ✓ New user can complete onboarding
2. ✓ User can add expense transaction
3. ✓ User can add income transaction
4. ✓ Transaction appears in list
5. ✓ Balance updates correctly
6. ✓ Budget tracks spending
7. ✓ Analytics charts render
8. ✓ AI responds to query
9. ✓ Settings changes persist
10. ✓ App survives backgrounding
11. ✓ Offline mode works
12. ✓ Sync completes successfully

### 12.7.2 Automated CI Pipeline

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Analyze
        run: flutter analyze
        
      - name: Unit tests
        run: flutter test --coverage
        
      - name: Coverage check
        run: |
          coverage=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          if (( $(echo "$coverage < 70" | bc -l) )); then
            echo "Coverage $coverage% is below 70%"
            exit 1
          fi
          
      - name: Integration tests
        run: flutter test integration_test/

---

# 13. RELEASE PLAN

## 13.1 Release Phases

### 13.1.1 Phase Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           RELEASE TIMELINE                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PHASE 1: MVP          PHASE 2: BETA         PHASE 3: LAUNCH           │
│  ───────────────       ──────────────        ──────────────            │
│  Weeks 1-8             Weeks 9-14            Weeks 15-18               │
│                                                                         │
│  • Core features       • AI Assistant        • Polish & bugs            │
│  • Local storage       • Cloud sync          • Store submission         │
│  • Basic budgets       • Advanced budgets    • Marketing launch         │
│  • Simple analytics    • Full analytics      • Premium IAP              │
│                                                                         │
│  Target: Internal      Target: 500 users     Target: Public             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 13.2 Phase 1: MVP (Weeks 1-8)

### 13.2.1 Scope

**In Scope:**
- [x] User authentication (email + social)
- [x] Wallet management (CRUD)
- [x] Transaction entry (manual)
- [x] Category system (defaults + custom)
- [x] Basic budgets (no rollover)
- [x] Monthly overview analytics
- [x] Category breakdown
- [x] Local storage only
- [x] Light/dark theme
- [x] Basic settings

**Out of Scope:**
- [ ] AI Assistant (Phase 2)
- [ ] Cloud sync (Phase 2)
- [ ] Rollover/envelope budgets (Phase 2)
- [ ] Advanced analytics (Phase 2)
- [ ] Premium features (Phase 3)

### 13.2.2 Milestones

| Week | Milestone | Deliverables |
|------|-----------|--------------|
| 1-2 | Foundation | Project setup, auth, navigation |
| 3-4 | Data Layer | Models, Hive setup, CRUD operations |
| 5-6 | Core UI | Dashboard, transactions, wallets |
| 7 | Budgets | Budget creation, tracking |
| 8 | Polish | Bug fixes, QA, internal release |

### 13.2.3 Exit Criteria

- [ ] All P0 features functional
- [ ] No P0/P1 bugs
- [ ] Performance benchmarks met
- [ ] Unit test coverage >70%
- [ ] Internal team using daily

## 13.3 Phase 2: Beta (Weeks 9-14)

### 13.3.1 Scope

**In Scope:**
- [ ] AI Assistant (chat interface)
- [ ] Smart categorization
- [ ] Cloud sync (Supabase)
- [ ] Rollover budgets
- [ ] Goal-based saving
- [ ] Full analytics suite
- [ ] Category heatmap
- [ ] Trend analysis
- [ ] Spending velocity
- [ ] Data export (CSV, JSON)

**Out of Scope:**
- [ ] Bank sync (Post-launch)
- [ ] Widgets (Post-launch)
- [ ] Premium paywall (Phase 3)

### 13.3.2 Milestones

| Week | Milestone | Deliverables |
|------|-----------|--------------|
| 9 | Cloud Setup | Supabase config, sync architecture |
| 10-11 | Sync Implementation | Offline-first, conflict resolution |
| 12 | AI Integration | OpenAI integration, chat UI |
| 13 | Advanced Features | Rollover, goals, analytics |
| 14 | Beta Launch | TestFlight/Firebase distribution |

### 13.3.3 Beta Program

**Distribution:**
- iOS: TestFlight (500 users max)
- Android: Firebase App Distribution / Open Beta

**Beta User Selection:**
- Existing waitlist signups
- Finance app power users
- Mix of technical and non-technical
- Geographic diversity

**Feedback Collection:**
- In-app feedback button
- Weekly survey
- Crash reporting (Sentry/Crashlytics)
- Usage analytics (privacy-safe)

### 13.3.4 Exit Criteria

- [ ] AI accuracy >85%
- [ ] Sync reliability >99%
- [ ] No data loss incidents
- [ ] NPS >30 from beta users
- [ ] Crash-free rate >99%

## 13.4 Phase 3: Public Launch (Weeks 15-18)

### 13.4.1 Scope

**In Scope:**
- [ ] Premium subscription integration
- [ ] Premium feature gating
- [ ] App Store optimization
- [ ] Store listing polish
- [ ] Marketing landing page
- [ ] Final bug fixes
- [ ] Performance optimization
- [ ] Accessibility audit

### 13.4.2 Milestones

| Week | Milestone | Deliverables |
|------|-----------|--------------|
| 15 | Premium IAP | StoreKit/Billing integration |
| 16 | Store Prep | Screenshots, descriptions, metadata |
| 17 | Submission | App Store + Play Store submission |
| 18 | Launch | Public release, marketing push |

### 13.4.3 Launch Checklist

**Pre-Submission:**
- [ ] All screenshots captured (all device sizes)
- [ ] App preview video recorded
- [ ] App description finalized
- [ ] Keywords optimized
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] Support email configured
- [ ] GDPR compliance verified
- [ ] Accessibility tested
- [ ] All languages checked

**App Store Specific:**
- [ ] App Store Connect configured
- [ ] Privacy nutrition labels completed
- [ ] Age rating set (4+)
- [ ] Category: Finance
- [ ] In-app purchase products created
- [ ] Review notes prepared

**Play Store Specific:**
- [ ] Play Console configured
- [ ] Data safety form completed
- [ ] Target API level ≥34
- [ ] Category: Finance
- [ ] In-app products created
- [ ] Content rating questionnaire

## 13.5 Store Requirements

### 13.5.1 App Store (iOS)

**Screenshots Required:**

| Device | Resolution | Required |
|--------|------------|----------|
| iPhone 6.7" (15 Pro Max) | 1290×2796 | Yes |
| iPhone 6.5" (14 Plus) | 1242×2688 | Yes |
| iPhone 5.5" (8 Plus) | 1242×2208 | Optional |
| iPad Pro 12.9" (6th gen) | 2048×2732 | If iPad support |

**Screenshot Content (suggested order):**
1. Dashboard with balance
2. Transaction entry
3. Analytics overview
4. AI Assistant
5. Budget tracking
6. Category management

**App Preview Video:**
- Duration: 15-30 seconds
- Resolution: Match device
- No hands/device shown
- Show key features
- Subtle background music (rights cleared)

**Privacy Nutrition Labels:**

| Category | Data Type | Usage |
|----------|-----------|-------|
| Contact Info | Email | Account creation |
| Financial Info | Transaction data | App functionality |
| Usage Data | Analytics | App improvement |
| Diagnostics | Crash logs | Bug fixes |

**Linked: No**  
**Tracked: No**

### 13.5.2 Google Play (Android)

**Assets Required:**

| Asset | Dimensions | Required |
|-------|------------|----------|
| App icon | 512×512 | Yes |
| Feature graphic | 1024×500 | Yes |
| Phone screenshots | Various | Yes (2+ required) |
| Tablet screenshots | Various | If tablet support |
| Promo video | YouTube link | Optional |

**Data Safety Declaration:**

| Question | Answer |
|----------|--------|
| Data collected? | Yes (account, financial) |
| Data shared? | No |
| Data encrypted? | Yes (in transit + at rest) |
| Data deletable? | Yes |
| Security practices | HTTPS, encryption |

**Target API Level:** 34 (Android 14)

**Permissions:**

| Permission | Reason |
|------------|--------|
| INTERNET | Sync, AI features |
| USE_BIOMETRIC | App lock |
| POST_NOTIFICATIONS | Budget alerts |
| CAMERA | Receipt scanning (future) |

### 13.5.3 App Descriptions

**Short Description (80 chars):**
```
Track spending, understand patterns, reach your financial goals with AI.
```

**Full Description:**
```
FINSOR - Clarity for your finances

Take control of your money with Finsor, the personal finance app that 
combines simple tracking with powerful AI insights.

EFFORTLESS TRACKING
• Add transactions in seconds
• Smart categorization learns your habits
• Multiple wallets for all your accounts
• Supports 150+ currencies

SMART BUDGETS
• Set spending limits by category
• Visual progress indicators
• Get alerts before overspending
• Goal-based savings tracking

POWERFUL ANALYTICS
• See where your money goes
• Track spending trends over time
• Compare month-to-month
• Category breakdown with charts

AI FINANCIAL ASSISTANT (Premium)
• Ask questions about your spending
• Get personalized insights
• Understand spending patterns
• Receive smart recommendations

PRIVACY FIRST
• Your data stays on your device
• Optional cloud backup
• No ads, ever
• No data selling

PREMIUM FEATURES
• Full AI Assistant access
• Advanced budgeting (rollover, envelopes)
• Detailed analytics & reports
• Data export (CSV, PDF)
• Priority support

Start your journey to financial clarity today!
```

**Keywords (iOS - 100 chars max):**
```
finance,budget,expense,tracker,money,spending,savings,wallet,AI,personal
```

## 13.6 Post-Launch Support

### 13.6.1 Immediate (Week 1-2)

- Monitor crash rates hourly
- Respond to reviews within 24h
- Hotfix critical bugs within 48h
- Track activation funnel

### 13.6.2 Ongoing

- Weekly app updates (bug fixes)
- Bi-weekly feature releases
- Monthly analytics review
- Quarterly roadmap planning

---

# 14. METRICS & SUCCESS CRITERIA

## 14.1 Metric Categories

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         SUCCESS METRICS FRAMEWORK                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐ │
│  │ ACTIVATION  │   │ ENGAGEMENT  │   │ RETENTION   │   │ REVENUE     │ │
│  │             │   │             │   │             │   │             │ │
│  │ First value │   │ Daily usage │   │ Coming back │   │ Paying us   │ │
│  │ moment      │   │ depth       │   │ over time   │   │             │ │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘ │
│                                                                         │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐                   │
│  │ PERFORMANCE │   │ AI QUALITY  │   │ SATISFACTION│                   │
│  │             │   │             │   │             │                   │
│  │ Speed,      │   │ Accuracy,   │   │ NPS, rating │                   │
│  │ stability   │   │ usefulness  │   │ reviews     │                   │
│  └─────────────┘   └─────────────┘   └─────────────┘                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 14.2 Activation Metrics

### 14.2.1 Definitions

| Metric | Definition | Target |
|--------|------------|--------|
| **Onboarding Completion** | % users completing setup | >85% |
| **First Transaction** | % users adding 1 tx in 24h | >60% |
| **Activation** | 3+ transactions in first week | >40% |
| **Time to First Value** | Minutes to first transaction | <5 min |

### 14.2.2 Funnel Analysis

```
Download
    │
    ▼ 100%
App Open
    │
    ▼ 95% (target)
Onboarding Started
    │
    ▼ 85% (target)
Onboarding Completed
    │
    ▼ 70% (target)
First Transaction
    │
    ▼ 40% (target)
Activated (3+ tx)
```

### 14.2.3 Tracking Implementation

```dart
class ActivationTracker {
  void trackOnboardingStep(int step, int total) {
    analytics.track('onboarding_step', {
      'step': step,
      'total': total,
      'completion': step / total,
    });
  }
  
  void trackFirstTransaction() {
    analytics.track('first_transaction', {
      'time_since_install': getTimeSinceInstall(),
      'time_since_onboarding': getTimeSinceOnboarding(),
    });
  }
  
  void checkActivation() {
    final txCount = getTransactionCountThisWeek();
    if (txCount >= 3 && !hasTrackedActivation) {
      analytics.track('user_activated', {
        'days_to_activate': getDaysSinceInstall(),
        'transaction_count': txCount,
      });
      hasTrackedActivation = true;
    }
  }
}
```

## 14.3 Engagement Metrics

### 14.3.1 Definitions

| Metric | Definition | Target |
|--------|------------|--------|
| **DAU/MAU** | Daily active / Monthly active | >25% |
| **Sessions per Day** | Average sessions per DAU | >1.5 |
| **Transactions per Week** | Avg tx per active user | >5 |
| **Feature Adoption** | % users using key features | Varies |

### 14.3.2 Feature Adoption Targets

| Feature | Target Adoption | Measurement |
|---------|-----------------|-------------|
| Transaction entry | >90% | Used in last 7 days |
| Budget creation | >40% | Has ≥1 active budget |
| Analytics view | >50% | Viewed in last 14 days |
| AI chat | >30% (Premium) | Sent ≥1 message this month |
| Export | >10% | Exported in last 30 days |

### 14.3.3 Session Depth

**Light Session (<1 min):**
- Quick balance check
- Single transaction add

**Medium Session (1-5 min):**
- Multiple transactions
- Budget review
- Quick analytics check

**Deep Session (>5 min):**
- Analytics exploration
- AI conversation
- Settings configuration

**Target Distribution:**
- Light: 50%
- Medium: 35%
- Deep: 15%

## 14.4 Retention Metrics

### 14.4.1 Cohort Retention

| Day | Target | Minimum |
|-----|--------|---------|
| D1 | >70% | 60% |
| D7 | >50% | 40% |
| D14 | >40% | 30% |
| D30 | >35% | 25% |
| D60 | >30% | 20% |
| D90 | >25% | 18% |

### 14.4.2 Retention Visualization

```
100% ─┬────────────────────────────────────────
      │ ████
  90% ─│ ████
      │ ████
  80% ─│ ████
      │ ████ ████
  70% ─│ ████ ████                    ← D1 Target
      │ ████ ████
  60% ─│ ████ ████
      │ ████ ████ ████
  50% ─│ ████ ████ ████               ← D7 Target
      │ ████ ████ ████ ████
  40% ─│ ████ ████ ████ ████ ████
      │ ████ ████ ████ ████ ████ ████
  30% ─│ ████ ████ ████ ████ ████ ████ ████
      │ ████ ████ ████ ████ ████ ████ ████ ████
  20% ─│ ████ ████ ████ ████ ████ ████ ████ ████
      └────────────────────────────────────────
       D1   D7   D14  D30  D60  D90  D120 D180
```

### 14.4.3 Churn Indicators

**Early Warning Signs:**
- No transactions in 7 days
- App opened but no action
- Notification disabled
- Sync turned off

**Win-back Triggers:**
- Personalized re-engagement email
- "We miss you" notification
- Feature update announcement

## 14.5 Revenue Metrics

### 14.5.1 Monetization Funnel

```
Free Users (100%)
      │
      ▼
Premium Page Views (15%)
      │
      ▼
Trial Started (8%)
      │
      ▼
Trial Converted (40% of trials = 3.2% of total)
      │
      ▼
Subscription Retained (70% annual)
```

### 14.5.2 Revenue KPIs

| Metric | Definition | Target |
|--------|------------|--------|
| **Conversion Rate** | Free → Premium | 3-5% |
| **Trial Start Rate** | Free → Trial | 8% |
| **Trial Conversion** | Trial → Paid | 40% |
| **ARPU** | Revenue / Active Users | $0.50/month |
| **ARPPU** | Revenue / Paying Users | $8/month |
| **LTV** | Customer Lifetime Value | >$50 |
| **Annual Retention** | % renewing after 1 year | >70% |

### 14.5.3 Premium Feature Value

| Feature | % Users Citing as Reason |
|---------|--------------------------|
| AI Assistant | 45% |
| Advanced Analytics | 25% |
| Cloud Sync | 15% |
| Export/Reports | 10% |
| No Limits | 5% |

## 14.6 Performance Metrics

### 14.6.1 Technical KPIs

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| **Crash-Free Rate** | >99.5% | <99% |
| **ANR Rate** | <0.5% | >1% |
| **Cold Start Time** | <2s | >3s |
| **API Latency (p50)** | <200ms | >500ms |
| **API Latency (p99)** | <1s | >2s |
| **Sync Success Rate** | >99% | <95% |

### 14.6.2 Monitoring Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTEM HEALTH                            │
├─────────────────────────────────────────────────────────────┤
│ Crash-Free: 99.7% ✓   ANR: 0.3% ✓   API: 142ms (p50) ✓     │
├─────────────────────────────────────────────────────────────┤
│ Errors (24h): 23      Sync Failures: 12    AI Timeouts: 5  │
└─────────────────────────────────────────────────────────────┘
```

## 14.7 AI-Specific Metrics

### 14.7.1 Quality Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **Categorization Accuracy** | AI correct first time | >90% |
| **User Acceptance Rate** | AI suggestion kept | >70% |
| **Correction Rate** | User changes AI category | <10% |
| **Response Quality** | User rates helpful (1-5) | >4.0 |

### 14.7.2 Engagement Metrics

| Metric | Definition | Target |
|--------|------------|--------|
| **AI Queries/User/Month** | Avg questions asked | >10 |
| **Insight Click-Through** | Taps on AI insights | >30% |
| **Conversation Length** | Avg messages per session | >3 |
| **Return Rate** | % returning to AI in 7 days | >50% |

### 14.7.3 AI Improvement Loop

```
User Correction
      │
      ▼
Log Correction + Context
      │
      ▼
Aggregate Anonymized Patterns
      │
      ▼
Update Categorization Model
      │
      ▼
Deploy Updated Model
      │
      ▼
Measure Accuracy Improvement
```

## 14.8 Satisfaction Metrics

### 14.8.1 NPS (Net Promoter Score)

**Question:** "How likely are you to recommend Finsor to a friend? (0-10)"

| Score | Category | Target % |
|-------|----------|----------|
| 9-10 | Promoters | >50% |
| 7-8 | Passives | ~30% |
| 0-6 | Detractors | <20% |

**Target NPS:** >50

### 14.8.2 Store Ratings

| Platform | Target | Minimum |
|----------|--------|---------|
| App Store | >4.7 | 4.5 |
| Play Store | >4.5 | 4.3 |

**Rating Request Strategy:**
- Ask after 5th successful transaction
- Don't ask if user had recent error
- Max once per 90 days
- In-app prompt, not interrupt

### 14.8.3 Qualitative Feedback

**Collection Methods:**
- In-app feedback button
- Post-transaction micro-survey (monthly)
- Beta tester interviews
- Support ticket analysis
- App store review monitoring

---

# 15. FUTURE EXTENSIONS

## 15.1 Post-Launch Roadmap

### 15.1.1 Priority Framework

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        FEATURE PRIORITIZATION                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  HIGH IMPACT                                                            │
│       │                                                                 │
│       │    ┌─────────────┐         ┌─────────────┐                     │
│       │    │ Bank Sync   │         │ Widgets     │                     │
│       │    │ (P1)        │         │ (P1)        │                     │
│       │    └─────────────┘         └─────────────┘                     │
│       │                                                                 │
│       │    ┌─────────────┐         ┌─────────────┐                     │
│       │    │ Family Mode │         │ OCR Receipt │                     │
│       │    │ (P1)        │         │ (P1)        │                     │
│       │    └─────────────┘         └─────────────┘                     │
│       │                                                                 │
│       │    ┌─────────────┐         ┌─────────────┐                     │
│       │    │ Investment  │         │ Tax Reports │                     │
│       │    │ (P2)        │         │ (P2)        │                     │
│       │    └─────────────┘         └─────────────┘                     │
│       │                                                                 │
│  LOW  └────────────────────────────────────────────────────────────────│
│               LOW EFFORT ─────────────────────────── HIGH EFFORT        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## 15.2 P1 Features (3-6 Months Post-Launch)

### 15.2.1 Bank Sync Integration

**Value:** Automatic transaction import  
**Effort:** High  
**Dependencies:** Banking APIs (Plaid, regional providers)

**Scope:**
- Connect to supported banks
- Auto-import transactions
- Match with manual entries
- Handle duplicates gracefully

**Technical Considerations:**
- Regional API variations
- Security certifications required
- Ongoing API costs
- User trust/privacy concerns

**Success Criteria:**
- 30% of active users connect a bank
- 90% transaction match accuracy
- <5% duplicate rate

### 15.2.2 Home Screen Widgets

**Value:** Glanceable information  
**Effort:** Medium  
**Platforms:** iOS (WidgetKit), Android (Glance)

**Widget Types:**

| Widget | Size | Content |
|--------|------|---------|
| Balance | Small | Total balance |
| Summary | Medium | Income/Expense/Net |
| Budget | Medium | Top budget progress |
| Quick Add | Small | Single-tap to add |

**Technical Considerations:**
- Background refresh limits
- Data freshness
- Deep linking
- Theme support

### 15.2.3 Receipt OCR Scanning

**Value:** Faster manual entry  
**Effort:** Medium  
**Dependencies:** Vision API (Google, Apple)

**Capabilities:**
- Extract amount
- Extract merchant name
- Extract date
- Suggest category

**Accuracy Targets:**
- Amount: >95%
- Merchant: >85%
- Date: >90%
- Category: >80%

### 15.2.4 Family/Shared Wallets

**Value:** Couples and family budgeting  
**Effort:** High  
**Dependencies:** Multi-user architecture

**Features:**
- Invite partner/family
- Shared wallets
- Shared budgets
- Individual + combined views
- Permission levels

**Challenges:**
- Real-time sync critical
- Conflict resolution more complex
- Privacy between members
- Premium-only (increased cost)

## 15.3 P2 Features (6-12 Months)

### 15.3.1 Investment Tracking

**Value:** Net worth visibility  
**Effort:** High

**Phase 1 (Manual):**
- Add investment accounts
- Manual balance updates
- Basic allocation view

**Phase 2 (Automated):**
- Brokerage API connections
- Real-time quotes
- Performance tracking
- Tax lot tracking

### 15.3.2 Net Worth Dashboard

**Value:** Complete financial picture  
**Effort:** Medium

**Components:**
- Assets (cash + investments)
- Liabilities (debt tracking)
- Net worth over time
- Milestone tracking

### 15.3.3 Tax Report Generation

**Value:** Tax season prep  
**Effort:** Medium

**Reports:**
- Annual spending summary
- Category breakdown for deductions
- Business expense export
- Donation tracking

**Limitations:**
- Not tax advice
- User responsible for accuracy
- Regional format variations

### 15.3.4 Multi-Device Improvements

**Value:** Seamless experience  
**Effort:** Medium

**Improvements:**
- Real-time sync across devices
- Handoff (iOS) support
- Better conflict resolution
- Device management UI

## 15.4 Experimental Features (12+ Months)

### 15.4.1 Voice Input

**Value:** Hands-free entry  
**Effort:** Medium

**Implementation:**
- "Add $15 for lunch today"
- Natural language parsing
- Confirmation before save
- Works with Siri/Assistant

### 15.4.2 Subscription Tracker

**Value:** Auto-detect recurring charges  
**Effort:** Medium

**Capabilities:**
- Identify subscription patterns
- Predict upcoming charges
- Alert on price changes
- Suggest cancellations

### 15.4.3 Credit Score Integration (US)

**Value:** Complete financial health  
**Effort:** High

**Partners:** TransUnion, Equifax, Experian (via aggregators)

**Features:**
- View credit score
- Score factors
- Change alerts
- Improvement tips

### 15.4.4 Gamification (Optional)

**Value:** Increased engagement  
**Effort:** Medium

**Elements:**
- Saving streaks
- Budget achievements
- Monthly challenges
- Progress badges

**Caution:**
- Keep optional
- Don't trivialize finances
- Avoid dark patterns

## 15.5 Explicitly NOT Planned

The following features are intentionally excluded from the roadmap:

| Feature | Reason |
|---------|--------|
| **Cryptocurrency** | Volatility, specialized needs, regulatory complexity |
| **Stock Trading** | Different product category, heavily regulated |
| **Peer-to-Peer Payments** | Requires banking licenses, liability |
| **Social Features** | Spending comparisons create negative psychology |
| **Bill Negotiation** | Third-party dependency, legal complexity |
| **Automated Investing** | Fiduciary responsibility, regulation |
| **Credit Cards/Loans** | Financial product licensing required |

## 15.6 Decision Framework

### 15.6.1 Feature Evaluation Criteria

| Criterion | Weight | Question |
|-----------|--------|----------|
| User Value | 30% | Does this solve a real problem? |
| Business Value | 25% | Does this drive revenue/retention? |
| Technical Feasibility | 20% | Can we build it well? |
| Strategic Fit | 15% | Does it align with our vision? |
| Competitive Edge | 10% | Does it differentiate us? |

### 15.6.2 Build vs. Buy vs. Partner

| Approach | When to Use |
|----------|-------------|
| **Build** | Core competency, unique UX required |
| **Buy** | Commodity feature, proven solution exists |
| **Partner** | Requires licenses/expertise we don't have |

**Examples:**
- Build: Transaction entry UI
- Buy: Push notification service
- Partner: Bank sync (Plaid)

---

# APPENDIX

## A. Glossary

| Term | Definition |
|------|------------|
| **Activation** | User reaches value threshold (3+ transactions) |
| **ARPPU** | Average Revenue Per Paying User |
| **DAU** | Daily Active Users |
| **Envelope Budgeting** | Pre-allocate funds to spending categories |
| **LTV** | Lifetime Value (total revenue from a customer) |
| **MAU** | Monthly Active Users |
| **NPS** | Net Promoter Score (-100 to +100) |
| **Pace Indicator** | Spending rate vs. budget allowance |
| **P0** | Must-have priority (launch blocker) |
| **P1** | High priority (soon after launch) |
| **P2** | Medium priority (roadmap) |
| **RLS** | Row Level Security (database) |
| **Rollover** | Surplus/deficit carries to next period |

## B. Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 2026 | Product Team | Initial complete PRD |

## C. References

- 1Money App (design inspiration)
- YNAB (budgeting philosophy)
- Mint (feature reference)
- Apple Human Interface Guidelines
- Material Design 3 Guidelines
- Supabase Documentation
- Flutter Documentation

---

**END OF DOCUMENT**

*This PRD is a living document and will be updated as the product evolves.*

