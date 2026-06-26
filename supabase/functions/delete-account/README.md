# delete-account Edge Function

Permanently deletes the calling user's account and all associated data.
Satisfies **Apple App Store Guideline 5.1.1(v)** and **Google Play's account
deletion policy** (the in-app deletion path). The public web deletion request
URL lives on the marketing site at `https://kudlit.app/delete-account`.

## What it does

1. Verifies the caller's Supabase user JWT (forwarded automatically by
   `supabase_flutter` `functions.invoke`).
2. Deletes the user's avatar object(s) from the `avatars` storage bucket.
3. Calls `auth.admin.deleteUser(userId)` with the service role. All app tables
   reference `auth.users(id) on delete cascade`, so `profiles`,
   `learning_progress`, `scan_history`, `translation_history`, `chat_messages`,
   `chat_memory_facts`, and `user_preferences` rows are removed automatically.

> Verify each app table actually has `references auth.users(id) on delete
> cascade`. If any table lacks it, add an explicit delete for that table here
> before relying on the cascade.

## Deploy

```bash
supabase functions deploy delete-account
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected into Edge Functions
automatically in hosted projects. For local dev:

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
```

## Client call

```dart
await Supabase.instance.client.functions.invoke('delete-account');
// then sign out locally and route to the welcome screen.
```
