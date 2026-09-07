# Deliverables: 1Money-style UX and settings

## Summary

Implemented five feature areas: account types (regular/debt/savings), UI cleanup (icons + FAB), category creation with subcategories, currency format setting, and week start + start screen. AI/Edge Functions and Supabase integration were not modified.

---

## 1) Account types (Типы счетов)

**Implementation:**
- **Model** (`lib/models/wallet.dart`): Added `AccountType` enum (`regular`, `debt`, `savings`) and fields: `accountType`, `creditLimit`, `debtIOwe`, `debtOwedToMe`, `debtTotal`, `showDebtInExpenses`, `goalAmount`. Defaults: debt/savings use `includeInTotal: false` when not set in JSON.
- **Add/Edit screen** (`lib/screens/wallets/add_edit_wallet_screen.dart`): Account type selector (3 cards: Regular, Debt, Savings). Name, type, currency, description, “Include in total balance” toggle. **Regular:** starting balance, optional credit limit, “Kind” dropdown (cash/card/etc). **Debt:** “I owe” / “Owed to me” segmented control, total debt amount, “Show in expenses” toggle. **Savings:** starting balance, goal amount.
- **Sync** (`lib/services/sync_service.dart`): `_remoteToLocal` and `_localToRemote` for `wallets` extended with `account_type`, `credit_limit`, `debt_i_owe`, `debt_owed_to_me`, `debt_total`, `show_debt_in_expenses`, `goal_amount`.
- **Transactions:** No change to creation flow. Debt “show in expenses” is stored on the wallet; analytics can later treat debt payments as expenses (e.g. “Debt” category) if desired.

**SQL:** `supabase/migrations/0007_account_types_and_settings.sql` adds columns on `wallets`: `account_type`, `credit_limit`, `debt_i_owe`, `debt_owed_to_me`, `debt_total`, `show_debt_in_expenses`, `goal_amount`.

---

## 2) UI cleanup (icons like 1Money)

**Implementation:**
- **Categories** (`lib/screens/categories/categories_overview_screen.dart`): Replaced “Manage” `TextButton.icon` with an `IconButton` (tune icon) and tooltip “Manage”.
- **Operations/Transactions** (`lib/screens/transactions/transactions_screen.dart`): Removed the small “repeat last” FAB; kept a single primary FAB “+” for adding an operation.

---

## 3) Category creation with subcategories (1Money-style)

**Implementation:**
- **Add/Edit category** (`lib/screens/categories/add_edit_category_screen.dart`): Header “New Category” / “Edit Category”. Fields: Name, Type (expense/income), Parent (optional), **Category currency** row (primary currency from settings, read-only). **Subcategories:** list of subcategories; each row has icon + name + ⋮ menu (Edit / Delete). “Add subcategory” row with + opens a dialog (name only); on save, new subcategory is created with parent’s type/icon/color. For a new parent category, subcategory names are collected in state and created after the parent is saved.
- **Data:** Existing `Category` with `parentId` and `subcategoriesProvider` is used; no new entities.

---

## 4) Currency format setting (Формат валюты)

**Implementation:**
- **Options** (`lib/constants/currency_format_options.dart`): List of 8 format options (e.g. `-1,234,567.90 $`, `-1 234 567,90 $`, `$ -1 234 567,90`) and `formatAmountWithId(amount, symbol, formatId, decimalDigits)` implementing thousand/decimal separators and symbol position.
- **Settings model** (`lib/models/user_settings.dart`): `currencyFormatId` (default `'default'`) and `startScreenIndex` (default `0`). Sync mappings updated in `lib/services/sync_service.dart` for `user_settings`.
- **Formatter** (`lib/utils/currency_formatter.dart`): `formatAmount(..., formatId)` and `formatBalance(..., formatId)`; when `formatId` is set and not `'default'`, they use `formatAmountWithId`.
- **Settings UI** (`lib/screens/settings/settings_screen.dart`): New “Currency format” tile in Appearance & Locale; tap opens bottom sheet with format list; selection is persisted via `updateCurrencyFormatId`. Call sites that have access to settings can pass `settings.currencyFormatId` into the formatter for full app-wide effect (additional wiring can be done where amounts are displayed).

**SQL:** `supabase/migrations/0007_account_types_and_settings.sql` adds `currency_format_id`, `start_screen_index` on `user_settings`.

---

## 5) Week start + start screen

**Implementation:**
- **Settings model:** `weekStartDay` already existed; `startScreenIndex` added (0=Accounts, 1=Categories, 2=Operations, 3=Budget, 4=Overview).
- **Settings UI:** “Calendar & Startup” section: “Week start” (Monday/Sunday picker), “Start screen” (tab list picker), “Start of Month” (unchanged). Persisted via `updateWeekStartDay` and `updateStartScreenIndex`.
- **Main screen** (`lib/screens/main_screen.dart`): On first load when settings are available, `startScreenIndex` is applied once to set the initial bottom-nav tab (via `ref.listen(settingsProvider)` and `addPostFrameCallback`).
- **Week start:** Stored and available for any date grouping; existing code that uses “week” can be updated to use `settings.weekStartDay` (e.g. for weekly views/charts).

---

## Files changed

- `lib/models/wallet.dart` – AccountType, new fields, fromJson/toJson/copyWith
- `lib/models/user_settings.dart` – currencyFormatId, startScreenIndex
- `lib/screens/wallets/add_edit_wallet_screen.dart` – Account type UI and type-specific fields
- `lib/screens/categories/add_edit_category_screen.dart` – Category currency row, subcategory list + Add subcategory dialog
- `lib/screens/categories/categories_overview_screen.dart` – Manage as IconButton
- `lib/screens/transactions/transactions_screen.dart` – Single FAB
- `lib/screens/settings/settings_screen.dart` – Currency format, week start, start screen pickers
- `lib/screens/main_screen.dart` – Initial tab from startScreenIndex
- `lib/providers/settings_provider.dart` – updateCurrencyFormatId, updateWeekStartDay, updateStartScreenIndex
- `lib/services/sync_service.dart` – Wallet and user_settings column mappings
- `lib/utils/currency_formatter.dart` – formatId parameter and formatAmountWithId
- `lib/constants/currency_format_options.dart` – New file: format options and formatAmountWithId
- `supabase/migrations/0007_account_types_and_settings.sql` – New migration
- `test/wallet_account_type_test.dart` – New: Wallet account type serialization
- `test/user_settings_format_test.dart` – New: UserSettings currencyFormatId/startScreenIndex

---

## SQL migration

**File:** `supabase/migrations/0007_account_types_and_settings.sql`

- **wallets:** `account_type` (TEXT, default `'regular'`), `credit_limit`, `debt_i_owe`, `debt_owed_to_me`, `debt_total`, `show_debt_in_expenses` (BOOLEAN, default FALSE), `goal_amount`.
- **user_settings:** `currency_format_id` (TEXT, default `'default'`), `start_screen_index` (INTEGER, default 0).

RLS unchanged; existing policies apply to new columns.

---

## TODOs / notes

1. **Currency format app-wide:** Only the settings value and formatter API are in place. To apply the chosen format everywhere (balances, transactions, charts), each place that formats amounts should pass `ref.watch(settingsProvider).value?.currencyFormatId` (or equivalent) into `CurrencyFormatter.formatAmount`/`formatBalance`. A few key screens were not fully wired to avoid touching too many files; the structure is ready.
2. **Week start usage:** `weekStartDay` is persisted and exposed; any weekly filters/charts should use it for “start of week” (e.g. Monday vs Sunday). No existing weekly views were changed.
3. **Debt in expenses:** Wallet has `showDebtInExpenses`; logic to treat debt account movements as expenses in analytics (e.g. under a “Debt” category) can be added later in the analytics layer.

---

## Tests

- `test/wallet_account_type_test.dart` – Wallet fromJson/toJson for account types and new fields.
- `test/user_settings_format_test.dart` – UserSettings currencyFormatId and startScreenIndex persistence.

Run: `flutter test test/wallet_account_type_test.dart test/user_settings_format_test.dart`
