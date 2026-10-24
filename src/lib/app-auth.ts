import { createMiddleware } from '@tanstack/react-start';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from './app-database.types';
import { requireSupabaseAuth as cloudAuth } from '@/integrations/supabase/auth-middleware';

/** Preserve managed authentication and RLS; refine only the schema type. */
export const requireSupabaseAuth = createMiddleware({ type: 'function' })
  .middleware([cloudAuth])
  .server(({ context, next }) => next({ context: {
    ...context,
    supabase: context.supabase as unknown as SupabaseClient<Database>,
  } }));
