# Guest sync + AI chat manual test checklist

## A) Guest → Login → Sync reconciliation

1. **Setup:** Sign in, ensure 3 transactions exist and are synced (check Supabase or sync status in app).
2. **Sign out** (Settings → Account → Sign out).
3. **Guest mode:** Add a 4th transaction (and optionally edit an existing one). Confirm data is in the app.
4. **Sign in again** (Settings → Account → Sign in).
5. **Result:** After sign-in, wait a few seconds. Supabase should show 4 transactions (and edits). No app restart, no manual sync. Check Supabase Dashboard → Table Editor → transactions (filter by your user_id).

**Pass:** All guest-created/edited data appears in Supabase under the signed-in user after login.

---

## B) AI chat 401 Invalid JWT

1. **Signed out:** Open AI chat, set period/category, tap Send.  
   **Expected:** "Please sign in to use this feature." (no network call to Edge Function).

2. **Signed in:** Set period, send e.g. "Summarize my spending for this period."  
   **Expected:** Real AI response (no "Invalid JWT").

3. **Token expired (optional):** If you can force an expired token, send a message.  
   **Expected:** Either auto-refresh and success, or "Session expired. Please sign in again." (no raw FunctionException stack in UI).

**Pass:** Signed-out → prompt only; signed-in → real response; 401 → clean message, no stack trace.
