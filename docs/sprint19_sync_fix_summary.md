# Sprint 19 — Sync debug and fix summary

## Root cause and fixes

**Root cause:** (1) `lastSyncAt` was stored under a single Hive key. After user A logged out and user B logged in, the new `SyncService` read A’s timestamp, so B’s delta pull used the wrong window or saw no rows. (2) Push/pull failures were only logged as a short message with no table, status code, or response body, so RLS/constraint errors were hard to diagnose.

**Fixes:** (1) **Per-user lastSyncAt:** The metadata key is now `lastSyncAt_$userId`. The constructor reads `lastSyncAt_<currentUserId>`; after pull and after bootstrap snapshot push we write the same key. New users get no stored timestamp and thus a full pull. (2) **Verbose debug logging:** Under `kDebugMode`, sync logs bootstrap start/end and effective `userId`, push start/end and per-op success/failure (including `PostgrestException` code, message, details), and pull start/end with row counts per table. (3) **Sync now button:** In Settings → Data Management (debug only), a “Sync now” tile runs `SyncService.sync()` and shows a SnackBar with “Sync completed” or “Sync failed: …”. (4) **Tests:** Unit tests ensure remote payload construction adds `user_id`, transaction `toJson()` does not include `user_id`, lastSyncAt key is per-user, and sync init is gated on non-null `currentUser` id.

## Files touched

| File | Changes |
|------|--------|
| `lib/services/sync_service.dart` | `_debugLog`; constructor reads `lastSyncAt_$uid`; enqueue/push/pull/bootstrap/sync verbose logs; push/pull/bootstrap catch `PostgrestException` and log table/code/message/details; `setMetadata` uses `lastSyncAt_$_userId`; assert `user_id` in `_pushUpsert` in debug. |
| `lib/screens/settings/settings_screen.dart` | “Sync now” tile in Data Management (when `kDebugMode`); `_onSyncNow()` awaits `syncService.sync()` and shows SnackBar. |
| `test/sprint19_sync_fix/remote_payload_user_id_test.dart` | New: payload helper adds `user_id`; transaction `toJson()` has no `user_id`; full payload includes `user_id`. |
| `test/sprint19_sync_fix/last_sync_at_key_test.dart` | New: lastSyncAt key format `lastSyncAt_$userId`; different users, null handling. |
| `test/sprint19_sync_fix/sync_init_user_test.dart` | New: `shouldInitSync(currentUserId)` only true when non-null non-empty. |
| `docs/sprint19_sync_fix_summary.md` | This file. |

## Tests

All tests pass, including the new ones under `test/sprint19_sync_fix/`.
