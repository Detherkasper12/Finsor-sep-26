# Sprint 17 regression checklist

Manual verification steps before release. Run on both emulator and device where applicable.

## Auth
- [ ] Login (email/password)
- [ ] Sign up
- [ ] Logout

## Wallets
- [ ] Add wallet (fiat)
- [ ] Add wallet (crypto)
- [ ] Edit / delete wallet (when allowed)

## Categories
- [ ] Add category (top-level)
- [ ] Add category with subcategories in one flow (e.g. parent "Car", subcategories "Fuel, Tires, Service")
- [ ] Verify new subcategories appear indented in category picker
- [ ] Add transaction in a subcategory
- [ ] Filter by parent category includes child transactions

## Budgets
- [ ] Create budget (global)
- [ ] Create budget (category / wallet)
- [ ] Budget list and detail render

## Analytics
- [ ] Analytics overview opens
- [ ] No division-by-zero or crash (e.g. empty data)

## Export
- [ ] Export CSV runs and produces file

## Backup & restore
- [ ] Backup export (web + mobile if applicable)
- [ ] Restore import (web + mobile if applicable)

## Sync
- [ ] Sync triggers after mutations (debounced)
- [ ] No parallel syncs (single in-flight)

## AI Chat
- [ ] Send message (with context) → real OpenAI response
- [ ] Error states: rate limit / config error / temporary → toast + retry
- [ ] Retry after error works
- [ ] Long response does not overflow; lists/code render correctly
- [ ] Copy message works for assistant replies

## Final
- [ ] `flutter analyze` clean (or known issues documented)
- [ ] `flutter test` passes
