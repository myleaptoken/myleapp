-- =====================================================
-- CONVERTIR USUARIO A FACILITATOR (VERSIÓN SIMPLE)
-- =====================================================

-- Primero, verificar el usuario actual
SELECT 
  'USUARIO ACTUAL' as info,
  u.id,
  u.email,
  u.full_name,
  r.name as rol_actual
FROM users u
LEFT JOIN roles r ON u.role_id = r.id
WHERE u.email = 'myleaptoken@gmail.com';

-- Cambiar rol a facilitator (simple)
UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'facilitator')
WHERE email = 'myleaptoken@gmail.com';

-- Crear/actualizar registro en facilitators
INSERT INTO facilitators (
  user_id,
  bio,
  specialties,
  is_active
)
SELECT 
  u.id,
  'Facilitador experto en sanación energética y desarrollo personal. Con años de experiencia guiando procesos de transformación.',
  ARRAY['Sanación Energética', 'Desarrollo Personal', 'Meditación', 'Terapias Holísticas'],
  true
FROM users u
WHERE u.email = 'myleaptoken@gmail.com'
ON CONFLICT (user_id) DO UPDATE SET
  bio = EXCLUDED.bio,
  specialties = EXCLUDED.specialties,
  is_active = EXCLUDED.is_active;

-- Actualizar eventos sin facilitator
UPDATE events 
SET facilitator_id = (
  SELECT f.id 
  FROM facilitators f 
  JOIN users u ON f.user_id = u.id 
  WHERE u.email = 'myleaptoken@gmail.com'
)
WHERE facilitator_id IS NULL;

-- Activar eventos de Método ONE futuros
UPDATE events 
SET status = 'active'
WHERE (title ILIKE '%método one%' OR title ILIKE '%metodo one%')
  AND event_date > NOW()
  AND status != 'active';

-- =====================================================
-- ARREGLAR FUNCIÓN get_upcoming_events
-- =====================================================

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
    COALESCE(e.description, '') as description,
    COALESCE(u.full_name, 'Facilitador') as facilitator_name,
    COALESCE(f.bio, '') as facilitator_bio,
    COALESCE(f.specialties, ARRAY[]::TEXT[]) as facilitator_specialties,
    f.user_id as facilitator_user_id,
    e.event_date,
    TO_CHAR(e.event_date, 'HH24:MI') as event_time,
    TO_CHAR(e.event_date, 'YYYY-MM-DD') as event_date_formatted,
    e.duration_minutes,
    COALESCE(e.location, '') as location,
    e.is_online,
    e.max_attendees,
    e.current_attendees,
    e.token_cost,
    e.status,
    COALESCE(e.image_url, '') as image_url,
    COALESCE(e.video_url, '') as video_url,
    COALESCE(e.what_includes, ARRAY[]::TEXT[]) as what_includes
  FROM events e
  JOIN facilitators f ON e.facilitator_id = f.id
  JOIN users u ON f.user_id = u.id
  JOIN roles r ON u.role_id = r.id
  WHERE e.status = 'active' 
    AND e.event_date > NOW()
    AND f.is_active = true
    AND r.name = 'facilitator'
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Verificar resultados
SELECT 
  'USUARIO DESPUÉS DEL CAMBIO' as info,
  u.id,
  u.email,
  u.full_name,
  r.name as rol_nuevo
FROM users u
LEFT JOIN roles r ON u.role_id = r.id
WHERE u.email = 'myleaptoken@gmail.com';

-- Verificar facilitator
SELECT 
  'FACILITATOR CREADO' as info,
  f.id,
  u.email,
  f.is_active
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE u.email = 'myleaptoken@gmail.com';

-- Probar función
SELECT 'EVENTOS ENCONTRADOS' as test, COUNT(*) as total FROM get_upcoming_events();

-- Mostrar algunos eventos
SELECT 
  'EVENTOS DISPONIBLES' as info,
  title,
  event_date::date as fecha,
  status
FROM get_upcoming_events()
LIMIT 3;
