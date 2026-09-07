# Auth UX manual test checklist

- **Fresh install** → App opens to MainScreen in guest mode (no login gate).
- **Settings → Account** → Shows "Sign in / Create account" when signed out.
- **Tap Sign in / Create account** → AuthScreen opens. Sign in with Google or email.
- **After successful sign-in** → AuthScreen closes (or success banner), Settings immediately shows signed-in state (email + "Sign out") without restart.
- **AI chat** → When signed in, sending a message returns real AI response (no Invalid JWT). When signed out, sending shows "Please sign in to use this feature." and does not call the network.
- **Tap Sign out** (Settings or drawer) → Immediately shows signed-out state; stays in app (guest mode). No forced navigation to a blank login screen.
- **Tap Sign in again** → Opens AuthScreen; sign in works without closing the app.
