-- 1. Modificar la tabla facilitators para que use user_id de la tabla users
-- Primero agregar la columna user_id
ALTER TABLE facilitators 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE CASCADE;

-- 2. Eliminar la columna rating que no vamos a usar
ALTER TABLE facilitators 
DROP COLUMN IF EXISTS rating;

-- 3. Hacer que user_id sea único (un usuario solo puede ser un facilitador)
ALTER TABLE facilitators 
ADD CONSTRAINT facilitators_user_id_unique UNIQUE (user_id);

-- 4. Actualizar los facilitadores existentes con usuarios de ejemplo
-- Primero crear algunos usuarios para los facilitadores existentes
INSERT INTO users (id, email, full_name, token_balance) VALUES
(gen_random_uuid(), 'maria.gonzalez@myleap.com', 'María González', 5000),
(gen_random_uuid(), 'carlos.mendoza@myleap.com', 'Carlos Mendoza', 4500),
(gen_random_uuid(), 'ana.rodriguez@myleap.com', 'Ana Rodríguez', 4800)
ON CONFLICT (email) DO NOTHING;

-- 5. Conectar facilitadores existentes con usuarios
UPDATE facilitators 
SET user_id = u.id
FROM users u 
WHERE facilitators.email = u.email
  AND facilitators.user_id IS NULL;

-- 6. Actualizar la función get_upcoming_events para eliminar rating
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
    u.full_name as facilitator_name,  -- Ahora viene de users
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
  JOIN users u ON f.user_id = u.id  -- Join con users para obtener el nombre
  WHERE e.status = 'active' 
    AND e.event_date > NOW()
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- 7. Verificar la nueva estructura
SELECT 
  f.id as facilitator_id,
  u.full_name as user_name,
  u.email as user_email,
  f.bio,
  f.specialties,
  f.is_active
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Facilitadores ahora conectados con tabla users';
    RAISE NOTICE '❌ Columna rating eliminada';
    RAISE NOTICE '🔄 Función get_upcoming_events actualizada';
    RAISE NOTICE '👥 Nombres de facilitadores ahora vienen de users.full_name';
END $$;
