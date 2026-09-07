# S17 AI Chat auth test plan

## Manual verification

### 1. Signed in → chat works
- Sign in (email or OAuth).
- Open AI chat, set period (e.g. This month) or category.
- Send: "Summarize my spending for this period."
- **Expected:** Real AI answer (no "Invalid JWT"). Optional: check Edge logs for `user=<uuid>` and `calling OpenAI (finance)`.

### 2. Signed out → no request, shows re-login
- Sign out (or use a build that starts signed out).
- Open AI chat, set period, send a message.
- **Expected:** No Edge Function call (no request in Supabase logs). UI shows "Please sign in again." (message + SnackBar). No crash.

### 3. Expired token → refresh + retry works
- Sign in, then expire the token (e.g. wait for expiry, or manually corrupt token in dev).
- Send a message in AI chat.
- **Expected:** First request may 401; client refreshes session and retries once. Second request succeeds and returns AI answer. If still 401 after retry, UI shows "Session expired. Please sign in again."

## Automated test

- **AuthRequiredException:** `test/ai_chat/ai_chat_test.dart` — `AuthRequiredException has re-login message for UI` and `AuthRequiredException custom message` ensure the exception type and message are correct so the UI can show "Please sign in again." without calling the function when session is null or after 401 retry.

## Env / deployment

- Edge: `OPENAI_API_KEY` in Supabase secrets.
- Client: Supabase URL + anon key only (no OpenAI key). JWT is sent via `functions.invoke()` (session attached by client).
