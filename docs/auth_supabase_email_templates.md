# Supabase Auth Email Templates (Finsor)

Configure these in **Supabase Dashboard → Authentication → Email Templates**.

## 1. Confirm signup (CODE only, no magic link)

- **Template:** Confirm signup
- **Goal:** Send a 6-digit OTP so the user verifies in-app. Do not use the confirmation link for login.

**Subject (example):**
```
Your Finsor verification code
```

**Body (example):** Use only the token. Remove or minimize `ConfirmationURL` so users rely on the code.

```html
<h2>Verify your email</h2>
<p>Use this code in the Finsor app:</p>
<p style="font-size:24px; font-weight:bold; letter-spacing:4px;">{{ .Token }}</p>
<p>This code expires in 1 hour.</p>
<p>If you didn't sign up for Finsor, you can ignore this email.</p>
```

- **Variables:** `{{ .Token }}` = 6-digit OTP, `{{ .Email }}` = user email.
- In-app: call `verifyOTP(email, token, type: OtpType.signup)` after user enters the code.

## 2. Reset password

- **Template:** Reset password
- **Goal:** Clean, minimal email. Supabase uses a link for recovery; keep copy short and on-brand.

**Subject (example):**
```
Reset your Finsor password
```

**Body (example):**
```html
<h2>Reset your password</h2>
<p>Click the link below to set a new password:</p>
<p><a href="{{ .ConfirmationURL }}">Reset password</a></p>
<p>If you didn't request this, you can ignore this email.</p>
<p>— Finsor</p>
```

- **Variables:** `{{ .ConfirmationURL }}` = one-time reset link.
- Optional: configure redirect URL in Supabase so the link opens the app (deep link) if supported.

## Notes

- **Confirm signup:** Use `OtpType.signup` in `verifyOTP()`. Do not use `signInWithOtp()` for the main login flow; login is email + password only.
- **Session:** Session is created only after signup is confirmed (or when user signs in with password / Google).
- **Resend:** In-app "Resend code" calls `auth.resend(type: OtpType.signup, email: email)`.
