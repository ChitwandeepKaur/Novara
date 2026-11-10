# Novara personal setup

## Install on your iPhone

1. Open `ASCEND.xcodeproj` in Xcode. The existing project/scheme name is ASCEND; the installed app is Novara.
2. Sign in to your Apple Account under Xcode > Settings > Apple Accounts.
3. Select the ASCEND target, then Signing & Capabilities. Automatic signing is enabled. Select your Personal Team.
4. Connect and unlock your iPhone, accept Trust, and enable Developer Mode if Xcode asks.
5. Select your iPhone as the run destination and Run. The deployment target is iOS 17 or later.
6. Keep the existing bundle identifier `com.ascend.app` to preserve updates. If Apple reports that identifier is unavailable, choose a unique identifier in Xcode before the first physical installation and keep it thereafter.

Alternatively, after account/device setup:

```sh
bash Scripts/install_on_iphone.sh YOUR_TEAM_ID YOUR_IPHONE_DEVICE_ID
```

This builds, signs, installs, and launches the app. It does not uninstall your existing app or delete progress. Never share your Apple password, signing private key, or API key in chat.

A free Personal Team's provisioning profiles expire after seven days. Apple may require rebuilding and reinstalling from Xcode to keep using a development build. Update the existing installation instead of deleting the app. See [Apple's account comparison](https://developer.apple.com/help/account/basics/about-your-developer-account).

## Connect cloud sync with your free Apple account

Novara uses Supabase rather than CloudKit so cloud sync does not require Apple's paid CloudKit capability.

Configured on November 9, 2026: the Novara project at `https://ltwnjymjocdyudyhidfm.supabase.co` is healthy, the schema is applied, and its public URL and publishable key are bundled with this build. The database reports RLS enabled and three own-user policies. A live anonymous REST request returns HTTP 401, permission denied. For this build, skip steps 1 through 4 and start by creating your cloud account in Novara. No private account credentials are bundled.

1. Create a Free project named Novara at [Supabase Dashboard](https://supabase.com/dashboard). Keep the database password private.
2. In that project's SQL Editor, run `Backend/supabase.sql` once. It creates one saved-progress row per authenticated user and enables row-level security. Anonymous clients cannot read or write saves.
3. Find the project's HTTPS URL and publishable key in its Connect/API settings. A legacy `anon` key also works. Never use a secret or service-role key in the app.
4. In Novara, open Settings > Cloud sync and online AI. Save the project URL and public key.
5. Create your cloud account using your email and a password. Confirm the email if required by the project, then sign in. These are the app's cloud account credentials, separate from your Supabase Dashboard login.
6. Enable Automatically sync progress, then tap Sync now. The status must confirm a successful sync before relying on it.
7. On another installation, configure the same project and sign in with the same cloud account. Enable sync to download existing progress. If both copies already contain changes, choose the copy to keep. Novara preserves the other copy locally before replacement.

Sync checks five seconds after a successful local save, when the app becomes active, and about once a minute while open. This is whole-save synchronization, not simultaneous per-task merging. Divergent versions produce a conflict instead of silently discarding changes. Network, sign-in, and setup failures leave local progress intact and appear in Online Services. Signing out disables sync on that device and retains local and cloud data.

Cloud sync uploads the full saved app state, including challenge measurements and notes, to your own Supabase project. It never includes the OpenAI API key or cloud login tokens. Row-level security separates users; this is not end-to-end encryption against the project owner or hosting provider. See [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) and [password authentication](https://supabase.com/docs/guides/auth/passwords).

## Free-only planning and services

Novara uses the editable on-device template planner for main quests and mini quests. Paid AI integration and API-key entry have been removed. No OpenAI key or credits are needed. A previously enabled online-planning preference cannot activate paid requests in this build. This planner is a local template system, not a hosted AI model.

Verified November 9, 2026 in the Novara billing dashboard: Free Plan, spend cap enabled, and no extra usage charges. Keep the Supabase organization on Free ($0/month). Novara has no payment, subscription, purchase, or automatic upgrade flow. Supabase can restrict service at free-tier limits or pause a project after a week of low activity; local progress, planning, and Files backups continue to work. Resume a paused project from the dashboard without upgrading. Check [Supabase Free pricing](https://supabase.com/pricing) for current limits.

Use a free Apple Personal Team for installation. Its seven-day signing renewal remains necessary; a paid developer membership is optional and is not required by this app.

## Daily use and recovery

- Progress saves automatically. Novara also flushes a save when leaving the app and keeps the previous good local copy.
- Focus sessions are saved as timestamps, so locking the phone, changing tabs, or closing the timer sheet does not lose elapsed time. Paused time is excluded. Reopening after a completed interval logs the planned duration once, not the full time away.
- Allow notifications when starting your first timer if you want a completion reminder while the phone is locked. Notification denial does not break timing. Open iOS notification settings from Novara Settings if needed.
- Settings > Backups and saved progress > Save JSON backup to Files creates a separate backup. Restore JSON backup from Files validates the file and preserves the previous save before replacement.
- A damaged primary save is recovered from the previous good copy when possible. The damaged original is preserved separately. If recovery is impossible, normal editing and automatic saving stop so an empty state cannot overwrite your files. Retry after unlocking, import a JSON backup, or sign in to Online Services and restore the cloud copy.
- Save failures are visible. Retry saving or export a JSON backup before closing the app if a failure persists.

## Verification record

Completed locally: 68 core checks pass, including protection against legacy paid-planning preferences, timer relaunch/pause/capped completion, duplicate reward protection, disk-save failure, damaged-save recovery, invalid restore rejection, cloud configuration validation, and conflict decisions. Simulator packaging and an unsigned physical-iPhone Release build pass. The isolated simulator accepted installation and launched the app. Visual walkthrough automation was blocked by a Device Hub screen-capture failure, so it is not counted as passed. Remote-response checks use synthetic fixtures; they are not live API or database tests.

Supabase project setup and schema verification are complete, including a live anonymous-access rejection. Still requires the user's accounts and physical device: signed installation, the phone walkthrough below, real sign-in/sync and cross-device recovery, and free on-device planning on the phone. Do not treat those as passed until exercised.

## Phone walkthrough before relying on the app

1. Launch and finish onboarding. Create/review a plan and verify the four daily non-negotiables.
2. Add a mini quest and import a weekly plan using headings only.
3. Start a five-minute focus session. Lock the phone, reopen before completion, and confirm the time is correct. Pause for a minute and verify paused time is excluded. Close and reopen the app and resume.
4. Let the session finish, reopen, and verify one session and one XP award. Reopening again must not award XP twice.
5. Log a challenge day and verify the stats and character XP update. Confirm fairy unlocks and selection at the intended milestones using the automated checks rather than editing your real XP.
6. Export to Files, close/reopen, and verify progress remains. Restore the exported backup and compare quests, tasks, challenge logs, XP, and fairy choice.
7. Confirm a successful cloud sync. Test another installation with the same account; verify a download and explicit conflict handling if both copies change.
8. Generate and refine a free on-device plan, then turn off networking and verify planning, existing tasks, challenge logging, and manual backups remain usable.
