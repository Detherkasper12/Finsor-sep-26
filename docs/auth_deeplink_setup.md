# Auth deep link setup (Finsor)

Configure Supabase and the app so login callbacks and password reset open the app on real devices instead of localhost.

## Supabase Dashboard

### URL configuration

1. **Supabase Dashboard** → **Authentication** → **URL Configuration**.

2. **Site URL**
   - Must **not** be `http://localhost:...` for production.
   - Use your real site, e.g. `https://finsor.app` (or your actual domain).
   - This is used as the base for email links (e.g. reset password).

3. **Redirect URLs**
   - Add these **Additional Redirect URLs** (one per line):
     - `io.supabase.finsor://login-callback`
     - `io.supabase.finsor://auth-callback`
     - `io.supabase.finsor://reset-password`
   - Supabase will only redirect to URLs in this list.

### Email templates (optional)

- **Authentication** → **Email Templates**.
- Reset password and confirm signup templates use the **Site URL** and redirect paths.
- Ensure redirect paths match the app (e.g. `io.supabase.finsor://reset-password` for recovery).

## App configuration (already in repo)

- **Android:** `android/app/src/main/AndroidManifest.xml` — intent-filters for `io.supabase.finsor` with hosts `login-callback`, `auth-callback`, `reset-password`.
- **iOS:** `ios/Runner/Info.plist` — `CFBundleURLTypes` with scheme `io.supabase.finsor`.

## Testing on a real device

1. **Reset password**
   - On device, open app → Forgot password → enter email → send.
   - Open the reset email on the **same device** and tap the link.
   - The link should open the **app** (not the browser, not localhost).
   - Set new password in the in-app screen and submit.

2. **OAuth (e.g. Google)**
   - After choosing account, Supabase redirects to `io.supabase.finsor://login-callback` (or auth-callback).
   - The app should open and complete sign-in.

3. **If the link opens browser or localhost**
   - Check Site URL and Redirect URLs in Supabase.
   - Ensure the app is installed and the custom scheme is registered (rebuild after manifest/plist changes).
