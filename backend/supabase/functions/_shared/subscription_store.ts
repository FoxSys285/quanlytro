import { createClient } from "npm:@supabase/supabase-js@2";

let cachedClient: ReturnType<typeof createClient> | null = null;

export function subscriptionStore() {
  if (cachedClient) return cachedClient;
  const url = Deno.env.get("SUPABASE_URL")?.trim() ?? "";
  const legacyServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ?? "";
  let serviceKey = legacyServiceKey;
  if (!serviceKey) {
    try {
      const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}") as Record<string, string>;
      serviceKey = keys.default ?? "";
    } catch (_) {
      serviceKey = "";
    }
  }
  if (!url || !serviceKey) {
    throw new Error("Supabase server credentials are unavailable in the Edge Function runtime.");
  }
  cachedClient = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  return cachedClient;
}
