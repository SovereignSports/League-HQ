-- LEAGUE HQ / M3 - SEASON OPERATIONS (new League HQ Supabase project ONLY)
-- Run after M1 and M2, with the organization owner already established.
-- No Tournament HQ hq_ objects referenced. Transactional + safely repeatable.
-- Only authenticated organization directors/owners may read or write these records.
-- Public Player Hub publication and outbound messaging remain a later security-gated phase.
BEGIN;

CREATE TABLE IF NOT EXISTS public.lhq_teams (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 season_id uuid NOT NULL, name text NOT NULL CHECK(length(btrim(name)) BETWEEN 1 AND 160),
 registration_type text NOT NULL DEFAULT 'individual' CHECK(registration_type IN ('individual','team')),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(id,organization_id,season_id),
 FOREIGN KEY(season_id,organization_id) REFERENCES public.lhq_seasons(id,organization_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS lhq_teams_season_idx ON public.lhq_teams(season_id);

CREATE TABLE IF NOT EXISTS public.lhq_season_players (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 season_id uuid NOT NULL, player_id uuid NOT NULL,
 registration_source text NOT NULL DEFAULT 'manual' CHECK(registration_source IN ('manual','csv','jotform','team')),
 registration_status text NOT NULL DEFAULT 'registered' CHECK(registration_status IN ('registered','waitlist','withdrawn')),
 notes text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(season_id,player_id), UNIQUE(id,organization_id,season_id),
 FOREIGN KEY(season_id,organization_id) REFERENCES public.lhq_seasons(id,organization_id) ON DELETE RESTRICT,
 FOREIGN KEY(player_id,organization_id) REFERENCES public.lhq_players(id,organization_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS lhq_season_players_season_idx ON public.lhq_season_players(season_id);

CREATE TABLE IF NOT EXISTS public.lhq_team_members (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 season_id uuid NOT NULL, team_id uuid NOT NULL, player_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(season_id,player_id),
 FOREIGN KEY(team_id,organization_id,season_id) REFERENCES public.lhq_teams(id,organization_id,season_id) ON DELETE CASCADE,
 FOREIGN KEY(season_id,player_id) REFERENCES public.lhq_season_players(season_id,player_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS lhq_team_members_team_idx ON public.lhq_team_members(team_id);

CREATE TABLE IF NOT EXISTS public.lhq_assignment_groups (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 season_id uuid NOT NULL, label text NOT NULL CHECK(length(btrim(label)) BETWEEN 1 AND 160),
 preference text NOT NULL CHECK(preference IN ('required','preferred')),
 notes text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(id,organization_id,season_id),
 FOREIGN KEY(season_id,organization_id) REFERENCES public.lhq_seasons(id,organization_id) ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS public.lhq_assignment_group_members (
 group_id uuid NOT NULL, organization_id uuid NOT NULL, season_id uuid NOT NULL,
 player_id uuid NOT NULL,
 PRIMARY KEY(group_id,player_id),
 FOREIGN KEY(group_id,organization_id,season_id) REFERENCES public.lhq_assignment_groups(id,organization_id,season_id) ON DELETE CASCADE,
 FOREIGN KEY(season_id,player_id) REFERENCES public.lhq_season_players(season_id,player_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS public.lhq_matches (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 season_id uuid NOT NULL, home_team_id uuid NOT NULL, away_team_id uuid NOT NULL,
 match_date date NOT NULL, start_time time, court text NOT NULL DEFAULT '',
 stage text NOT NULL DEFAULT 'regular' CHECK(stage IN ('regular','championship')),
 round_label text NOT NULL DEFAULT '',
 home_score integer CHECK(home_score >= 0), away_score integer CHECK(away_score >= 0),
 status text NOT NULL DEFAULT 'scheduled' CHECK(status IN ('scheduled','completed')),
 notes text NOT NULL DEFAULT '', created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK(home_team_id <> away_team_id),
 CHECK ((status='scheduled' AND home_score IS NULL AND away_score IS NULL)
     OR (status='completed' AND home_score IS NOT NULL AND away_score IS NOT NULL AND home_score <> away_score)),
 FOREIGN KEY(season_id,organization_id) REFERENCES public.lhq_seasons(id,organization_id) ON DELETE RESTRICT,
 FOREIGN KEY(home_team_id,organization_id,season_id) REFERENCES public.lhq_teams(id,organization_id,season_id) ON DELETE RESTRICT,
 FOREIGN KEY(away_team_id,organization_id,season_id) REFERENCES public.lhq_teams(id,organization_id,season_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS lhq_matches_season_idx ON public.lhq_matches(season_id,match_date);

CREATE TABLE IF NOT EXISTS public.lhq_news (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL,
 season_id uuid NOT NULL, title text NOT NULL CHECK(length(btrim(title)) BETWEEN 1 AND 160),
 body text NOT NULL DEFAULT '', status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published')),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(season_id,organization_id) REFERENCES public.lhq_seasons(id,organization_id) ON DELETE RESTRICT
);
CREATE INDEX IF NOT EXISTS lhq_news_season_idx ON public.lhq_news(season_id);

DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['lhq_teams','lhq_season_players','lhq_team_members','lhq_assignment_groups','lhq_assignment_group_members','lhq_matches','lhq_news'] LOOP
   EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t);
   EXECUTE format('REVOKE ALL ON TABLE public.%I FROM PUBLIC, anon, authenticated',t);
   EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.%I TO authenticated',t);
   EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',t||'_director_select',t);
   EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',t||'_director_insert',t);
   EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',t||'_director_update',t);
   EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I',t||'_director_delete',t);
   EXECUTE format('CREATE POLICY %I ON public.%I FOR SELECT TO authenticated USING (public.lhq_has_role(organization_id,ARRAY[''owner'',''director'']::text[]))',t||'_director_select',t);
   EXECUTE format('CREATE POLICY %I ON public.%I FOR INSERT TO authenticated WITH CHECK (public.lhq_has_role(organization_id,ARRAY[''owner'',''director'']::text[]))',t||'_director_insert',t);
   EXECUTE format('CREATE POLICY %I ON public.%I FOR UPDATE TO authenticated USING (public.lhq_has_role(organization_id,ARRAY[''owner'',''director'']::text[])) WITH CHECK (public.lhq_has_role(organization_id,ARRAY[''owner'',''director'']::text[]))',t||'_director_update',t);
   EXECUTE format('CREATE POLICY %I ON public.%I FOR DELETE TO authenticated USING (public.lhq_has_role(organization_id,ARRAY[''owner'',''director'']::text[]))',t||'_director_delete',t);
 END LOOP;
END $$;
COMMIT;

-- Expect seven M3 tables, each with RLS=true and policy_count=4.
SELECT c.relname AS table_name,c.relrowsecurity AS rls_enabled,
 (SELECT count(*) FROM pg_policies p WHERE p.schemaname='public' AND p.tablename=c.relname) AS policy_count
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname IN
('lhq_teams','lhq_season_players','lhq_team_members','lhq_assignment_groups','lhq_assignment_group_members','lhq_matches','lhq_news')
ORDER BY c.relname;
