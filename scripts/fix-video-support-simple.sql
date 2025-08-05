-- 1. Agregar campo video_url a la tabla events (si no existe)
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS video_url TEXT;

-- 2. Eliminar la función existente y recrearla con el nuevo campo
DROP FUNCTION IF EXISTS get_upcoming_events();

CREATE OR REPLACE FUNCTION get_upcoming_events()
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  facilitator_name TEXT,
  facilitator_bio TEXT,
  facilitator_rating DECIMAL(3,2),
  facilitator_specialties TEXT[],
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
    f.name as facilitator_name,
    f.bio as facilitator_bio,
    f.rating as facilitator_rating,
    f.specialties as facilitator_specialties,
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
  WHERE e.status = 'active' 
    AND e.event_date > NOW()
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- 3. Agregar algunos videos de ejemplo a eventos existentes
UPDATE events 
SET video_url = 'https://www.youtube.com/embed/dQw4w9WgXcQ'
WHERE title ILIKE '%sanación energética%' 
  AND video_url IS NULL;

UPDATE events 
SET video_url = 'https://www.youtube.com/embed/jNQXAC9IVRw'
WHERE title ILIKE '%expansión%' 
  AND video_url IS NULL;

-- 4. Verificar que todo funciona
SELECT 
  title,
  CASE 
    WHEN video_url IS NOT NULL THEN '🎥 Video'
    WHEN image_url IS NOT NULL THEN '🖼️ Imagen'
    ELSE '❌ Sin media'
  END as media_type
FROM events 
WHERE status = 'active'
ORDER BY event_date;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Todo listo! Campo video_url agregado y función actualizada';
    RAISE NOTICE '🎥 Algunos eventos ahora tienen videos';
    RAISE NOTICE '🔄 El modal mostrará video cuando esté disponible';
END $$;
