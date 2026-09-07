# Sprint 19.1 — Auth + Sync critical fixes — summary

## Code changes

### AuthGate (lib/app.dart)
- Root UI now depends on `isAuthenticatedProvider`: when onboarding complete and Supabase ready but **not** authenticated → **AuthScreen**; when authenticated → **MainScreen**.
- When `recoverySessionPendingProvider` is true (password recovery from email link) → **ResetPasswordScreen**.
- Auth state listener sets `recoverySessionPendingProvider = true` on `AuthChangeEvent.passwordRecovery`.
- Route `/reset-password` added in `onGenerateRoute` → `ResetPasswordScreen`.

### Hard logout (lib/services/auth_service.dart)
- `signOut()` calls `_client.auth.signOut(scope: SignOutScope.global)`.
- On non-web: `GoogleSignIn` signOut + disconnect in try/catch (errors logged, do not block).

### Logout UI (lib/widgets/app_drawer.dart, lib/screens/settings/settings_screen.dart)
- After `signOut()`: clear sync service/status, invalidate `authStateProvider`, then pop navigation so AuthGate re-evaluates and shows AuthScreen.

### Google account chooser (lib/services/auth_service.dart)
- In `_signInWithGoogleNative()`, before `googleSignIn.signIn()`, call `signOut()` and `disconnect()` (try/catch) so the next sign-in shows the account picker.

### Deep links
- **Android** (android/app/src/main/AndroidManifest.xml): intent-filter for `io.supabase.finsor` with hosts `login-callback`, `auth-callback`, `reset-password`.
- **iOS** (ios/Runner/Info.plist): `CFBundleURLTypes` with scheme `io.supabase.finsor`.
- **main.dart**: After Supabase init, `AppLinks().getInitialLink()`; if URI is `io.supabase.finsor` with host `reset-password` / `auth-callback` / `login-callback`, call `Supabase.instance.client.auth.getSessionFromUrl(uri)`.
- **ResetPasswordScreen** (lib/screens/auth/reset_password_screen.dart): New screen to set new password after recovery link; calls `updateUser(UserAttributes(password: ...))`, then clears `recoverySessionPendingProvider` and invalidates auth providers.

### Sync
- Sync starts when `currentUser != null` in `_initSync()` (unchanged); on `signedOut` sync service/status are cleared. Debug log added when sync starts after login.

### Docs
- **docs/auth_deeplink_setup.md**: Supabase Site URL and Redirect URLs, app manifest/plist setup, testing on device.
- **docs/sprint19_1_auth_fix_summary.md**: This file.

### Tests (test/sprint19_auth_fix/)
- `auth_signout_scope_test.dart`: SignOutScope.global exists and differs from local.
- `auth_gate_session_test.dart`: Gate logic (session null → AuthScreen; session + no recovery → MainScreen; recovery pending → ResetPasswordScreen).
- `deeplink_reset_password_test.dart`: Deep link parsing for reset-password / auth-callback / login-callback.
- `reset_password_screen_test.dart`: ResetPasswordScreen builds and shows expected UI.

### Dependencies
- **pubspec.yaml**: Added `app_links: ^6.3.2` for initial deep link handling.

---

## Manual Supabase dashboard settings

1. **Authentication → URL Configuration**
   - **Site URL**: Set to your production domain (e.g. `https://finsor.app`). Do **not** use `http://localhost:...` for production.
   - **Redirect URLs**: Add these exactly:
     - `io.supabase.finsor://login-callback`
     - `io.supabase.finsor://auth-callback`
     - `io.supabase.finsor://reset-password`

2. No other dashboard changes were implemented in code; the above are required so reset-password and OAuth links open the app on device instead of localhost.
