# Integration tests (full app crashtest)

Run the full app, open key screens, and assert no crash/timeout. Requires a running device or Chrome (builds the app for that platform).

## Run

```bash
flutter pub get
# Chrome (no physical device):
flutter test integration_test/app_test.dart -d chrome
# Or a connected device (Android / iOS):
flutter test integration_test/app_test.dart -d <device_id>
flutter devices   # list device_id
```

## What it does

1. Calls `main()` and waits for the app to settle (splash, optional onboarding).
2. Opens the drawer (menu icon), taps Settings, then goes back.
3. Taps the AI tab, then the Accounts tab.
4. Asserts `MaterialApp` is present (app did not crash).

If the app is on onboarding or a different locale, some steps are skipped; the test still passes if the app stays alive.
