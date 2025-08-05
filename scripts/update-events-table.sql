-- Actualizar la tabla events para asegurar que tenga toda la información necesaria
-- para las cards y el modal

-- Agregar campos que podrían faltar
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS facilitator_bio TEXT,
ADD COLUMN IF NOT EXISTS facilitator_rating DECIMAL(3,2) DEFAULT 5.0,
ADD COLUMN IF NOT EXISTS facilitator_specialties TEXT[];

-- Actualizar eventos existentes con datos del facilitador
UPDATE events 
SET 
  facilitator_bio = f.bio,
  facilitator_rating = f.rating,
  facilitator_specialties = f.specialties
FROM facilitators f 
WHERE events.facilitator_id = f.id;

-- Insertar más eventos de ejemplo para testing
INSERT INTO events (
  title, 
  description, 
  facilitator_id, 
  event_date, 
  duration_minutes,
  location, 
  is_online, 
  max_attendees, 
  current_attendees,
  token_cost, 
  status, 
  image_url, 
  what_includes
) VALUES 
(
  'Meditación Profunda con Cuencos Tibetanos',
  'Sesión de meditación profunda utilizando la vibración sanadora de cuencos tibetanos para equilibrar chakras y liberar tensiones.',
  (SELECT id FROM facilitators WHERE name = 'María González'),
  '2024-02-22 18:00:00+00',
  120,
  'Online',
  true,
  25,
  8,
  300,
  'active',
  '/placeholder.svg?height=200&width=300&text=Cuencos+Tibetanos',
  ARRAY[
    'Sesión de meditación de 2 horas',
    'Técnicas de respiración consciente',
    'Trabajo con cuencos tibetanos',
    'Grabación de la sesión',
    'Guía de práctica personal'
  ]
),
(
  'Taller: Liberación de Traumas Ancestrales',
  'Workshop especializado en identificar y sanar patrones traumáticos heredados de generaciones anteriores.',
  (SELECT id FROM facilitators WHERE name = 'Carlos Mendoza'),
  '2024-02-25 16:00:00+00',
  180,
  'Barcelona, España',
  false,
  12,
  5,
  600,
  'active',
  '/placeholder.svg?height=200&width=300&text=Traumas+Ancestrales',
  ARRAY[
    'Taller intensivo de 3 horas',
    'Técnicas de sanación transgeneracional',
    'Trabajo con árbol genealógico',
    'Material de apoyo completo',
    'Seguimiento personalizado'
  ]
),
(
  'Círculo de Sanación Femenina',
  'Espacio sagrado para mujeres que buscan reconectar con su poder femenino y sanar heridas del linaje materno.',
  (SELECT id FROM facilitators WHERE name = 'Ana Rodríguez'),
  '2024-02-28 19:30:00+00',
  150,
  'Online',
  true,
  15,
  11,
  450,
  'active',
  '/placeholder.svg?height=200&width=300&text=Sanación+Femenina',
  ARRAY[
    'Círculo de sanación de 2.5 horas',
    'Rituales de conexión femenina',
    'Meditaciones guiadas específicas',
    'Kit de hierbas sagradas (envío incluido)',
    'Acceso a comunidad privada'
  ]
)
ON CONFLICT DO NOTHING;

-- Función para obtener eventos con información del facilitador
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
    e.what_includes
  FROM events e
  JOIN facilitators f ON e.facilitator_id = f.id
  WHERE e.status = 'active' 
    AND e.event_date > NOW()
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- Política para permitir que los usuarios vean los eventos
DROP POLICY IF EXISTS "Anyone can view upcoming events" ON events;
CREATE POLICY "Anyone can view upcoming events" ON events 
FOR SELECT USING (status = 'active' AND event_date > NOW());
