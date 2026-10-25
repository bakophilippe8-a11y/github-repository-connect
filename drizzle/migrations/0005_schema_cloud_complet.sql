-- SCHÉMA POUR LOVABLE CLOUD (à exécuter UNE fois, tel quel, sur une base vide), dans l'ordre :
-- schéma de base + migrations 0000 à 0004.

-- ===== Schéma de base (produits, leads, historique) =====
CREATE TYPE public.lead_stage AS ENUM ('nouveau','contacte','repondu','a_qualifier','matche','en_negociation','paye','perdu','dormant');
CREATE TYPE public.agent_kind AS ENUM ('segmentation','matching','closing','suivi','manuel');

CREATE TABLE public.products (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  code TEXT NOT NULL,
  nom TEXT NOT NULL,
  mots_cles_interet TEXT[] NOT NULL DEFAULT '{}',
  argument_cle TEXT NOT NULL DEFAULT '',
  prix NUMERIC NOT NULL DEFAULT 0,
  devise TEXT NOT NULL DEFAULT 'XOF',
  lien_maketou TEXT NOT NULL DEFAULT '',
  statut TEXT NOT NULL DEFAULT 'actif',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, code)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own products" ON public.products FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.leads (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  nom TEXT NOT NULL,
  telephone TEXT NOT NULL DEFAULT '',
  source TEXT NOT NULL DEFAULT 'whatsapp',
  stage public.lead_stage NOT NULL DEFAULT 'nouveau',
  product_id UUID REFERENCES public.products ON DELETE SET NULL,
  score_confiance NUMERIC,
  notes TEXT NOT NULL DEFAULT '',
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  next_followup_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.leads TO authenticated;
GRANT ALL ON public.leads TO service_role;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own leads" ON public.leads FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE TABLE public.lead_events (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  lead_id UUID NOT NULL REFERENCES public.leads ON DELETE CASCADE,
  agent public.agent_kind NOT NULL DEFAULT 'manuel',
  type TEXT NOT NULL DEFAULT 'note',
  contenu TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.lead_events TO authenticated;
GRANT ALL ON public.lead_events TO service_role;
ALTER TABLE public.lead_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own lead events" ON public.lead_events FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE INDEX leads_user_stage_idx ON public.leads (user_id, stage);
CREATE INDEX lead_events_lead_idx ON public.lead_events (lead_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.update_updated_at_column() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
-- ===== 0000 : automatisation vendeur =====
CREATE TABLE public.seller_connections (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL, channel text NOT NULL CHECK(channel IN ('telegram','whatsapp','meta')), credentials_ciphertext text NOT NULL, tested_at timestamptz, test_error text, enabled boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id,channel));
GRANT ALL ON public.seller_connections TO service_role;
ALTER TABLE public.seller_connections ENABLE ROW LEVEL SECURITY;
CREATE TABLE public.sales_guidelines (user_id uuid PRIMARY KEY, tone text NOT NULL DEFAULT 'Professionnel, chaleureux, concis', sales_info text NOT NULL DEFAULT '', human_conditions text NOT NULL DEFAULT 'Demande explicite, réclamation, information manquante ou incertitude', ai_paused boolean NOT NULL DEFAULT false, pause_reason text NOT NULL DEFAULT '', updated_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT,INSERT,UPDATE,DELETE ON public.sales_guidelines TO authenticated; GRANT ALL ON public.sales_guidelines TO service_role;
ALTER TABLE public.sales_guidelines ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_guidelines ON public.sales_guidelines FOR ALL TO authenticated USING(auth.uid()=user_id) WITH CHECK(auth.uid()=user_id);
CREATE TABLE public.sales_conversations (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL, channel text NOT NULL CHECK(channel IN ('telegram','whatsapp','internal')), external_contact text NOT NULL DEFAULT '', contact_name text NOT NULL DEFAULT '', contact_status text NOT NULL DEFAULT 'Prospect', status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','human','closed')), opted_out boolean NOT NULL DEFAULT false, last_inbound_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE(user_id,channel,external_contact));
GRANT SELECT ON public.sales_conversations TO authenticated; GRANT ALL ON public.sales_conversations TO service_role;
ALTER TABLE public.sales_conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_conversations ON public.sales_conversations FOR SELECT TO authenticated USING(auth.uid()=user_id);
CREATE TABLE public.sales_messages (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL, conversation_id uuid NOT NULL REFERENCES public.sales_conversations(id) ON DELETE CASCADE, direction text NOT NULL CHECK(direction IN ('inbound','outbound','decision')), content text NOT NULL, provider_id text, decision jsonb, status text NOT NULL DEFAULT 'received', error text, created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.sales_messages TO authenticated; GRANT ALL ON public.sales_messages TO service_role;
ALTER TABLE public.sales_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_messages ON public.sales_messages FOR SELECT TO authenticated USING(auth.uid()=user_id);
CREATE UNIQUE INDEX sales_provider_message_unique ON public.sales_messages(user_id,provider_id) WHERE provider_id IS NOT NULL;
CREATE TABLE public.sales_campaigns (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL, title text NOT NULL, facebook_copy text NOT NULL DEFAULT '', voiceover_script text NOT NULL DEFAULT '', status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','approved','rejected')), approved_at timestamptz, created_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.sales_campaigns TO authenticated; GRANT ALL ON public.sales_campaigns TO service_role;
ALTER TABLE public.sales_campaigns ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_campaigns ON public.sales_campaigns FOR SELECT TO authenticated USING(auth.uid()=user_id);
CREATE TABLE public.sales_inbox (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), connection_id uuid NOT NULL REFERENCES public.seller_connections(id), user_id uuid NOT NULL, delivery_id text NOT NULL, payload jsonb NOT NULL, state text NOT NULL DEFAULT 'pending', error text, created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(connection_id,delivery_id));
GRANT SELECT ON public.sales_inbox TO authenticated; GRANT ALL ON public.sales_inbox TO service_role;
ALTER TABLE public.sales_inbox ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_inbox ON public.sales_inbox FOR SELECT TO authenticated USING(auth.uid()=user_id);
CREATE TABLE public.sales_processing_locks (user_id uuid PRIMARY KEY, expires_at timestamptz NOT NULL);
GRANT ALL ON public.sales_processing_locks TO service_role; ALTER TABLE public.sales_processing_locks ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION public.claim_sales_lock(owner_id uuid) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ BEGIN INSERT INTO sales_processing_locks(user_id,expires_at) VALUES(owner_id,now()+interval '5 minutes') ON CONFLICT(user_id) DO UPDATE SET expires_at=excluded.expires_at WHERE sales_processing_locks.expires_at<now(); RETURN FOUND; END $$;
REVOKE ALL ON FUNCTION public.claim_sales_lock(uuid) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.claim_sales_lock(uuid) TO service_role;
-- ===== 0001 : historique de conversation et passage à l'humain =====
ALTER TABLE public.sales_conversations ADD COLUMN automation_epoch integer NOT NULL DEFAULT 0;
ALTER TABLE public.sales_messages ADD COLUMN author text NOT NULL DEFAULT 'system' CHECK (author IN ('client','ai','human','system'));
UPDATE public.sales_messages SET author = CASE WHEN direction='inbound' THEN 'client' WHEN direction='outbound' OR decision IS NOT NULL THEN 'ai' ELSE 'system' END;
CREATE TABLE public.sales_product_views (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), user_id uuid NOT NULL, conversation_id uuid NOT NULL REFERENCES public.sales_conversations(id) ON DELETE CASCADE, product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE, viewed_at timestamptz NOT NULL DEFAULT now(), UNIQUE(conversation_id,product_id));
GRANT SELECT ON public.sales_product_views TO authenticated; GRANT ALL ON public.sales_product_views TO service_role;
ALTER TABLE public.sales_product_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_product_views ON public.sales_product_views FOR SELECT TO authenticated USING(auth.uid()=user_id);
CREATE FUNCTION public.set_sales_mode(owner_id uuid, conversation uuid, next_status text) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE c public.sales_conversations; BEGIN
IF next_status NOT IN ('active','human','closed') THEN RAISE EXCEPTION 'Invalid mode'; END IF;
SELECT * INTO c FROM public.sales_conversations WHERE id=conversation AND user_id=owner_id FOR UPDATE;
IF NOT FOUND THEN RETURN false; END IF;
IF c.opted_out AND next_status='active' THEN RAISE EXCEPTION 'Contact opted out'; END IF;
IF c.status=next_status THEN RETURN true; END IF;
UPDATE public.sales_conversations SET status=next_status,automation_epoch=automation_epoch+1,updated_at=now() WHERE id=c.id;
INSERT INTO public.sales_messages(user_id,conversation_id,direction,content,author,status,decision) VALUES(owner_id,c.id,'decision',next_status,'human','internal',jsonb_build_object('mode',next_status));
RETURN true; END $$;
REVOKE ALL ON FUNCTION public.set_sales_mode(uuid,uuid,text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.set_sales_mode(uuid,uuid,text) TO service_role;
CREATE FUNCTION public.commit_sales_decision(owner_id uuid, conversation uuid, expected_epoch integer, result jsonb) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE c public.sales_conversations; act text; BEGIN
SELECT * INTO c FROM public.sales_conversations WHERE id=conversation AND user_id=owner_id FOR UPDATE;
IF NOT FOUND OR c.status<>'active' OR c.opted_out OR c.automation_epoch<>expected_epoch THEN RETURN false; END IF;
IF EXISTS(SELECT 1 FROM public.sales_guidelines WHERE user_id=owner_id AND ai_paused) THEN RETURN false; END IF;
act:=result->>'action';
IF act NOT IN ('SEND_MESSAGE','TRANSFER_TO_HUMAN','GENERATE_AD_CAMPAIGN') OR act IS NULL THEN RAISE EXCEPTION 'Invalid decision'; END IF;
IF c.channel<>'internal' THEN RETURN false; END IF;
IF act='TRANSFER_TO_HUMAN' THEN UPDATE public.sales_conversations SET status='human',automation_epoch=automation_epoch+1 WHERE id=c.id; END IF;
IF act='GENERATE_AD_CAMPAIGN' THEN INSERT INTO public.sales_campaigns(user_id,title,facebook_copy,voiceover_script) VALUES(owner_id,c.contact_name,COALESCE(result->>'facebook_copy',''),COALESCE(result->>'voiceover_script','')); END IF;
INSERT INTO public.sales_messages(user_id,conversation_id,direction,content,decision,status,author) VALUES(owner_id,c.id,CASE WHEN act='SEND_MESSAGE' THEN 'outbound' ELSE 'decision' END,COALESCE(NULLIF(result->>'message',''),result->>'reason',''),result,'internal','ai');
UPDATE public.sales_conversations SET updated_at=now() WHERE id=c.id;
RETURN true; END $$;
REVOKE ALL ON FUNCTION public.commit_sales_decision(uuid,uuid,integer,jsonb) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.commit_sales_decision(uuid,uuid,integer,jsonb) TO service_role;
CREATE FUNCTION public.touch_sales_conversation() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$ BEGIN UPDATE public.sales_conversations SET updated_at=greatest(updated_at,NEW.created_at),last_inbound_at=CASE WHEN NEW.direction='inbound' THEN greatest(last_inbound_at,NEW.created_at) ELSE last_inbound_at END WHERE id=NEW.conversation_id AND user_id=NEW.user_id; RETURN NEW; END $$;
CREATE TRIGGER touch_sales_history AFTER INSERT ON public.sales_messages FOR EACH ROW EXECUTE FUNCTION public.touch_sales_conversation();
-- ===== 0002 : publication Facebook et refus de contact =====
ALTER TABLE public.sales_campaigns DROP CONSTRAINT IF EXISTS sales_campaigns_status_check;
ALTER TABLE public.sales_campaigns ADD CONSTRAINT sales_campaigns_status_check CHECK (status IN ('draft','approved','rejected','publishing','published','failed'));
ALTER TABLE public.sales_campaigns ADD COLUMN IF NOT EXISTS published_at timestamptz, ADD COLUMN IF NOT EXISTS facebook_post_id text, ADD COLUMN IF NOT EXISTS publish_error text;
CREATE UNIQUE INDEX IF NOT EXISTS sales_campaigns_post_unique ON public.sales_campaigns(user_id, facebook_post_id) WHERE facebook_post_id IS NOT NULL;
CREATE OR REPLACE FUNCTION public.register_sales_optout(owner_id uuid, conversation uuid, message text) RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE c public.sales_conversations; BEGIN
SELECT * INTO c FROM public.sales_conversations WHERE id=conversation AND user_id=owner_id FOR UPDATE;
IF NOT FOUND THEN RETURN false; END IF;
INSERT INTO public.sales_messages(user_id,conversation_id,direction,content,author,status) VALUES(owner_id,c.id,'inbound',message,'client','received');
UPDATE public.sales_conversations SET opted_out=true,status='closed',automation_epoch=automation_epoch+1,updated_at=now() WHERE id=c.id;
INSERT INTO public.sales_messages(user_id,conversation_id,direction,content,author,status,decision) VALUES(owner_id,c.id,'decision','closed','system','internal',jsonb_build_object('mode','closed','reason','opt_out'));
RETURN true; END $$;
REVOKE ALL ON FUNCTION public.register_sales_optout(uuid,uuid,text) FROM PUBLIC,anon,authenticated; GRANT EXECUTE ON FUNCTION public.register_sales_optout(uuid,uuid,text) TO service_role;

-- ===== 0003 : vidéo des publicités =====
ALTER TABLE public.sales_campaigns
  ADD COLUMN IF NOT EXISTS video_status text NOT NULL DEFAULT 'none' CHECK (video_status IN ('none','generating','ready','failed')),
  ADD COLUMN IF NOT EXISTS video_job_id text,
  ADD COLUMN IF NOT EXISTS video_model text,
  ADD COLUMN IF NOT EXISTS video_path text,
  ADD COLUMN IF NOT EXISTS video_error text,
  ADD COLUMN IF NOT EXISTS video_started_at timestamptz;
CREATE INDEX IF NOT EXISTS sales_campaigns_video_generating_idx ON public.sales_campaigns(user_id) WHERE video_status = 'generating';
-- (Le bucket privé « campaign-videos » est créé par l'application elle-même au premier usage.)

-- ===== 0004 : clé IA du vendeur et plafonds =====
-- Canal 'ai' : clé API Google (Gemini) du vendeur, chiffrée comme les autres accès.
ALTER TABLE public.seller_connections DROP CONSTRAINT IF EXISTS seller_connections_channel_check;
ALTER TABLE public.seller_connections
  ADD CONSTRAINT seller_connections_channel_check CHECK (channel IN ('telegram','whatsapp','meta','ai'));

-- Plafonds quotidiens : réglages du vendeur (valeurs par défaut raisonnables).
ALTER TABLE public.sales_guidelines
  ADD COLUMN IF NOT EXISTS daily_ai_limit integer NOT NULL DEFAULT 300 CHECK (daily_ai_limit BETWEEN 1 AND 100000),
  ADD COLUMN IF NOT EXISTS daily_ads_limit integer NOT NULL DEFAULT 30 CHECK (daily_ads_limit BETWEEN 1 AND 10000),
  ADD COLUMN IF NOT EXISTS daily_video_limit integer NOT NULL DEFAULT 5 CHECK (daily_video_limit BETWEEN 1 AND 1000);