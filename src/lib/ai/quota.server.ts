import type { supabaseAdmin } from '@/integrations/supabase/client.server';

type Db = typeof supabaseAdmin;
const since = () => new Date(Date.now() - 24 * 3600 * 1000).toISOString();
const limit = (name: string, fallback: number) => {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? Math.floor(value) : fallback;
};

/** Plafond glissant sur 24 h pour protéger les crédits IA du vendeur. */
export async function decisionQuotaExceeded(db: Db, userId: string) {
  const result = await db.from('sales_messages').select('id', { count: 'exact', head: true }).eq('user_id', userId).eq('direction', 'inbound').eq('author', 'client').gte('created_at', since());
  if (result.error) throw result.error;
  return (result.count ?? 0) >= limit('SALES_DAILY_AI_LIMIT', 300);
}

export async function campaignQuotaExceeded(db: Db, userId: string) {
  const result = await db.from('sales_campaigns').select('id', { count: 'exact', head: true }).eq('user_id', userId).gte('created_at', since());
  if (result.error) throw result.error;
  return (result.count ?? 0) >= limit('ADS_DAILY_LIMIT', 30);
}
