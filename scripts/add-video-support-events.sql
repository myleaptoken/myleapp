-- Agregar campo video_url a la tabla events
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS video_url TEXT;

-- Actualizar algunos eventos con videos de ejemplo
UPDATE events 
SET video_url = 'https://www.youtube.com/embed/dQw4w9WgXcQ'
WHERE title LIKE '%Sanación Energética%'
LIMIT 1;

UPDATE events 
SET video_url = 'https://www.youtube.com/embed/dQw4w9WgXcQ'
WHERE title LIKE '%Expansión de Consciencia%'
LIMIT 1;

-- Actualizar la función get_upcoming_events para incluir video_url
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

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Campo video_url agregado a eventos';
    RAISE NOTICE '🎥 Algunos eventos actualizados con videos de ejemplo';
    RAISE NOTICE '🔄 Función get_upcoming_events actualizada';
END $$;
