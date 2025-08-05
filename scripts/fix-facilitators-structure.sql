-- 1. Primero, modificar la tabla facilitators para agregar user_id
ALTER TABLE facilitators 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- 2. Eliminar la columna rating
ALTER TABLE facilitators 
DROP COLUMN IF EXISTS rating;

-- 3. En lugar de crear usuarios nuevos, vamos a usar usuarios existentes
-- o crear una estructura temporal hasta que tengamos usuarios reales

-- Opción A: Usar el primer usuario existente para todos los facilitadores (temporal)
UPDATE facilitators 
SET user_id = (SELECT id FROM users LIMIT 1)
WHERE user_id IS NULL;

-- Opción B: Si no hay usuarios, crear facilitadores sin user_id por ahora
-- y actualizar la función para manejar casos donde user_id sea NULL

-- 4. Actualizar la función get_upcoming_events para manejar casos sin user_id
DROP FUNCTION IF EXISTS get_upcoming_events();

CREATE OR REPLACE FUNCTION get_upcoming_events()
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  facilitator_name TEXT,
  facilitator_bio TEXT,
  facilitator_specialties TEXT[],
  facilitator_user_id UUID,
  event_date TIMESTAMP WITH TIME ZONE,
  event_time TEXT,
  event_date_formatted TEXT,
  duration_minutes INTEGER,
  location TEXT,
  is_online BOOLEAN,
  max_attendees INTEGER,
  current_attendees INTEGER,
  token_cost INTEGER,
  status TEXT,
  image_url TEXT,
  video_url TEXT,
  what_includes TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.title,
    e.description,
    COALESCE(u.full_name, f.name) as facilitator_name,  -- Usar users.full_name si existe, sino facilitators.name
    f.bio as facilitator_bio,
    f.specialties as facilitator_specialties,
    f.user_id as facilitator_user_id,
    e.event_date,
    TO_CHAR(e.event_date, 'HH24:MI') as event_time,
    TO_CHAR(e.event_date, 'YYYY-MM-DD') as event_date_formatted,
    e.duration_minutes,
    e.location,
    e.is_online,
    e.max_attendees,
    e.current_attendees,
    e.token_cost,
    e.status,
    e.image_url,
    e.video_url,
    e.what_includes
  FROM events e
  JOIN facilitators f ON e.facilitator_id = f.id
  LEFT JOIN users u ON f.user_id = u.id  -- LEFT JOIN para permitir facilitadores sin user_id
  WHERE e.status = 'active' 
    AND e.event_date > NOW()
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- 5. Verificar qué usuarios existen actualmente
SELECT 
  'Usuarios existentes:' as info,
  COUNT(*) as total_users
FROM users;

-- 6. Verificar facilitadores y su conexión con usuarios
SELECT 
  f.id as facilitator_id,
  f.name as facilitator_name,
  f.email as facilitator_email,
  f.user_id,
  CASE 
    WHEN f.user_id IS NOT NULL THEN '✅ Conectado'
    ELSE '❌ Sin usuario'
  END as status
FROM facilitators f
WHERE f.is_active = true;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Estructura de facilitadores actualizada';
    RAISE NOTICE '❌ Columna rating eliminada';
    RAISE NOTICE '🔄 Función get_upcoming_events actualizada con LEFT JOIN';
    RAISE NOTICE '⚠️ Facilitadores pueden funcionar con o sin user_id';
END $$;
