import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from './app-database.types';
import { supabase as cloudClient } from '@/integrations/supabase/client';

/** Keep the generated connection and session; only supply the application schema contract. */
export const supabase = cloudClient as unknown as SupabaseClient<Database>;
