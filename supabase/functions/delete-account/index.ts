// supabase/functions/delete-account/index.ts
//
// Permanently deletes the calling user's account and all associated data.
// Required by Apple App Store Guideline 5.1.1(v) and Google Play's account
// deletion policy.
//
// Flow:
//   1. Verify the caller's Supabase user JWT (forwarded automatically by
//      supabase_flutter `functions.invoke`).
//   2. Use a SERVICE-ROLE client to delete the user's avatar object(s) from
//      the `avatars` storage bucket.
//   3. Call `auth.admin.deleteUser(userId)`. All app tables reference
//      `auth.users(id) on delete cascade`, so profile / history / chat /
//      memory-fact rows are removed automatically.
//
// Deploy:
//   supabase functions deploy delete-account
//
// Required secrets (service role is auto-injected for Edge Functions, but set
// it explicitly if running locally):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY  (do NOT expose these to clients)

// deno-lint-ignore-file no-explicit-any
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

const CORS_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Server is not configured' }, 500);
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!jwt) {
    return jsonResponse({ error: 'Missing Authorization token' }, 401);
  }

  // Service-role client: can verify any JWT and perform admin deletes.
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Resolve the caller from their JWT.
  const { data: userData, error: userErr } = await admin.auth.getUser(jwt);
  if (userErr || !userData?.user) {
    return jsonResponse({ error: 'Invalid or expired session' }, 401);
  }
  const userId = userData.user.id;

  // 1. Best-effort: remove avatar objects under the user's folder.
  try {
    const { data: files } = await admin.storage
      .from('avatars')
      .list(userId, { limit: 100 });
    if (files && files.length > 0) {
      const paths = files.map((f: any) => `${userId}/${f.name}`);
      await admin.storage.from('avatars').remove(paths);
    }
  } catch (_) {
    // Non-fatal: continue with account deletion even if storage cleanup fails.
  }

  // 2. Delete the auth user. DB rows cascade via `on delete cascade`.
  const { error: delErr } = await admin.auth.admin.deleteUser(userId);
  if (delErr) {
    return jsonResponse({ error: 'Failed to delete account' }, 500);
  }

  return jsonResponse({ success: true });
});
