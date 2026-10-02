-- ============================================================================
-- SUPABASE POSTGRESQL CLEANUP SCRIPT: DELETE ROOMS WITH NO ACTIVE HOST
-- Table: public.game_rooms
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. IMMEDIATE CLEANUP: Run this once to immediately delete all ghost rooms
--    where the host has disconnected, the room has been inactive for > 1 minute,
--    has 0 players, or has status = 'closed'.
-- ----------------------------------------------------------------------------
DELETE FROM public.game_rooms
WHERE 
  updated_at < (NOW() - INTERVAL '1 minute')
  OR player_count <= 0
  OR status = 'closed'
  OR host_name IS NULL
  OR TRIM(host_name) = '';

-- ----------------------------------------------------------------------------
-- 2. POSTGRES STORED FUNCTION: Reusable cleanup function
--    Can be invoked manually, via RPC (supabase.rpc('delete_stale_rooms')),
--    or called by a background cron job.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_stale_rooms()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_count integer;
BEGIN
  DELETE FROM public.game_rooms
  WHERE 
    updated_at < (NOW() - INTERVAL '1 minute')
    OR player_count <= 0
    OR status = 'closed'
    OR host_name IS NULL
    OR TRIM(host_name) = '';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

-- Grant execute permissions to anonymous & authenticated users
GRANT EXECUTE ON FUNCTION public.delete_stale_rooms() TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 3. AUTOMATED BACKGROUND CRON (Runs every 1 minute)
--    Requires pg_cron extension (enabled by default in Supabase).
-- ----------------------------------------------------------------------------
-- Step A: Enable pg_cron
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Step B: Unschedule old job if exists (prevents duplicate jobs)
SELECT cron.unschedule('cleanup_stale_game_rooms')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'cleanup_stale_game_rooms'
);

-- Step C: Schedule automated cleanup every 1 minute
SELECT cron.schedule(
  'cleanup_stale_game_rooms',
  '* * * * *',
  $$SELECT public.delete_stale_rooms();$$
);

-- ----------------------------------------------------------------------------
-- 4. RLS POLICIES (Ensure clients can delete their own or stale rooms)
-- ----------------------------------------------------------------------------
ALTER TABLE public.game_rooms ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read waiting rooms
DROP POLICY IF EXISTS "Public can view active game rooms" ON public.game_rooms;
CREATE POLICY "Public can view active game rooms"
ON public.game_rooms FOR SELECT
TO anon, authenticated
USING (status = 'waiting');

-- Allow anyone to insert/upsert their room
DROP POLICY IF EXISTS "Hosts can manage their game rooms" ON public.game_rooms;
CREATE POLICY "Hosts can manage their game rooms"
ON public.game_rooms FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Allow deletion of stale rooms
DROP POLICY IF EXISTS "Anyone can purge stale rooms" ON public.game_rooms;
CREATE POLICY "Anyone can purge stale rooms"
ON public.game_rooms FOR DELETE
TO anon, authenticated
USING (
  updated_at < (NOW() - INTERVAL '1 minute')
  OR player_count <= 0
  OR status = 'closed'
);
