# Architecture Decisions

## 1. Cold Start Definition

### What "52ms" Actually Measures
```
Start: HiveDatabaseService.init() called
End:   HiveDatabaseService._isInitialized = true
```

**Includes:**
- Opening 6 Hive boxes (transactions, wallets, categories, budgets, settings, metadata)
- First-run detection
- Default data seeding (15 categories, 1 wallet, settings) on first run

**Does NOT include:**
- `Hive.initFlutter()` in main.dart (~10-50ms)
- Flutter engine startup
- Widget tree building
- First frame render

### True Cold Start Metrics Needed

| Phase | What | Target |
|-------|------|--------|
| Engine | Flutter engine init | <500ms |
| Hive Init | `Hive.initFlutter()` | <100ms |
| DB Init | `HiveDatabaseService.init()` | <100ms |
| First Frame | Widget tree + first paint | <1000ms |
| **Total** | App launch → interactive | <2000ms |

### TODO: Add full cold start instrumentation in main.dart

---

## 2. Transfer Model Design

### Decision: Single Entity with `toWalletId`

A transfer is stored as **one Transaction record**:

```dart
Transaction(
  id: 'transfer_123',
  type: TransactionType.transfer,
  amount: 100.0,
  walletId: 'source_wallet',      // FROM wallet
  toWalletId: 'destination_wallet', // TO wallet
  categoryId: 'transfer',
)
```

### Rationale

| Approach | Pros | Cons |
|----------|------|------|
| **Single entity** (chosen) | Simple queries, one source of truth | Must handle both wallets in update logic |
| Paired transactions | Atomic per wallet | Complexity, orphan risk, query overhead |
| Separate Transfer table | Clean separation | Another entity to manage |

### Balance Update Flow

```
addTransaction(transfer)
  └── _updateWalletBalance()
        ├── sourceWallet.balance -= amount
        └── toWallet.balance += amount

deleteTransaction(transfer)
  └── _reverseWalletBalance()
        ├── sourceWallet.balance += amount
        └── toWallet.balance -= amount
```

### Edge Cases Handled
- `toWalletId` is null → treated as expense from source
- `toWallet` doesn't exist → only source updated (logged)

---

## 3. Wallet Balance Source of Truth

### Decision: Stored Value with Reconciliation Capability

**Current:** `wallet.currentBalance` is stored and updated on each transaction.

### Why Stored (not computed)?

1. **Read Performance**: Dashboard shows balance without summing all transactions
2. **Currency Handling**: Multi-currency wallets need rate-locked values
3. **Audit Trail**: `initialBalance` + transactions should match `currentBalance`

### Single Source of Truth Guarantee

Balance is ONLY modified in two places:
1. `_updateWalletBalance()` - called by addTransaction, updateTransaction
2. `_reverseWalletBalance()` - called by deleteTransaction, updateTransaction

**No other code path modifies wallet balance.**

### Reconciliation (for Analytics phase)

```dart
Future<double> computeBalanceFromTransactions(String walletId) async {
  final wallet = await getWallet(walletId);
  final transactions = await getTransactionsByWallet(walletId);
  
  double computed = wallet.initialBalance;
  for (final tx in transactions) {
    switch (tx.type) {
      case TransactionType.income: computed += tx.amount;
      case TransactionType.expense: computed -= tx.amount;
      case TransactionType.transfer:
        if (tx.walletId == walletId) computed -= tx.amount;
        if (tx.toWalletId == walletId) computed += tx.amount;
    }
  }
  return computed;
}
```

---

## 4. Service Layer Architecture

### Current: HiveDatabaseService (God service - temporary)

```
UI → Provider → HiveDatabaseService → Hive
```

### Target: Repository Pattern (for Analytics phase)

```
UI → Provider → Repository → HiveDatabaseService → Hive
                    ↓
              Business Logic
              (aggregations, validation)
```

### Planned Repositories

| Repository | Responsibility |
|------------|----------------|
| TransactionRepository | CRUD + aggregations (sum by category, date range) |
| WalletRepository | CRUD + balance reconciliation |
| AnalyticsRepository | Spending trends, budget tracking, reports |
| SyncRepository | Cloud sync, conflict resolution (future) |

### HiveDatabaseService Remains
- Low-level storage only
- No business logic
- No aggregations
- Just CRUD and JSON serialization

---

## 5. Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-03 | Single transfer entity | Simplicity, one source of truth |
| 2026-02-03 | Stored balance | Read performance, audit trail |
| 2026-02-03 | JSON serialization | Avoid Hive adapters complexity |
| 2026-02-03 | Deferred repositories | Wait for Analytics requirements |
