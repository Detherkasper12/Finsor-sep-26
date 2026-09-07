# Finsor Testing

Finsor tests should prove behavior, not merely avoid crashes. Required controls/screens must produce failing assertions when they disappear.

## Baseline gates

Normal Flutter changes should pass:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

The repository CI currently runs dependency installation, static analysis, and the unit/widget test suite. Formatting can be made a blocking CI gate once the existing codebase has been normalized without mixing a large formatting diff into functional work.

## Integration smoke test

`integration_test/app_test.dart` verifies debug startup reaches the main shell and that critical navigation destinations exist. It must not silently return or skip a required destination when UI is missing.

Run it on a target when startup, navigation, auth, sync or shell behavior changes:

```bash
flutter test integration_test/app_test.dart -d <device_id>
```

## High-risk test expectations

Transaction and wallet changes should cover balance effects, edits, deletion/soft deletion, transfers and persistence. Sync changes should cover outbox/retry/conflict/bootstrap behavior and user isolation. Authentication changes should cover signed-in/signed-out/recovery states. AI changes should verify that financial numbers come from supplied datasets and that empty/missing context is handled safely. Premium changes should test entitlement gating separately from UI presentation.

## Performance tests

Performance thresholds are useful only when the environment and dataset are controlled. Generated local output files are not source-of-truth evidence; keep assertions in executable tests and let CI/device runs produce fresh results.
