# Sprint 16 – Completion and Production Hardening

## Final corrections (added before implementation)

### 1) Restore must be FULL REPLACE (no merge)
- Do **not** use merge-only import for restore.
- Implement `clearAllDataForRestore()` + `importDataReplace()` (or `importData(mode: replace)`).
- Ensure no duplicates/old records remain. Invalidate all providers after restore.

### 2) Web import robustness
- File picker may return bytes/string inconsistently. Implement robust read:
  - utf8 decode → jsonDecode
  - try/catch with user-friendly error
  - never crash on malformed JSON

### 3) Biggest Expense display
- Do **not** rely on description/notes (PII / may be empty).
- Prefer `merchantNormalized` or `categoryName` fallback ("Unknown").

### 4) Subcategory filtering – descendants (future-proof)
- Implement `getDescendantCategoryIds(parentId)` (DFS) and use it for:
  - transaction filtering
  - budget spent calculation
- Not just direct children; support full descendant tree.

### 5) After restore – sync trigger timing
- Invalidate providers **first**, then trigger sync in a safe delayed/microtask way to avoid race conditions.

---

## Plan summary (from original S16 scope)

- **1** Disable onboarding (DEV): `AppConfig.skipOnboarding`, no flicker.
- **2** Overview: Net Cash Flow, Savings Rate %, Biggest Expense (category/merchantNormalized, not description), Average Daily Spend; empty states; tests.
- **3** Export: `ExportStrategy` + `CsvExportStrategy`, `PdfExportStrategy`/`XlsxExportStrategy` stubs.
- **4** Backup import: validate version/keys, **clearAllDataForRestore() + importDataReplace()**, then invalidate providers, then delayed sync.
- **5** Subcategories: tree picker, **getDescendantCategoryIds** for filter + budget, type from parent; test.
- **6** Sync: no parallel, lightweight logs.
- **7** Wallet currency: verify + test.
- **8** Overview UX: empty states, net delta (green/red).
- **9** Defensive: division by zero, null category.
- **10** Final verification checklist.
