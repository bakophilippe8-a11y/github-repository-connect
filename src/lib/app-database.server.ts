import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from './app-database.types';
import { supabaseAdmin as cloudAdmin } from '@/integrations/supabase/client.server';

/** Reuse the managed privileged client; no new credentials or connection. */
export const supabaseAdmin = cloudAdmin as unknown as SupabaseClient<Database>;
