-- Script para debuggear los eventos

-- 1. Verificar que hay eventos en la tabla
SELECT 
  id, 
  title, 
  event_date,
  status,
  facilitator_id,
  NOW() as current_time,
  (event_date > NOW()) as is_future
FROM events 
ORDER BY event_date;

-- 2. Verificar que hay facilitadores
SELECT id, name, email FROM facilitators;

-- 3. Probar la función get_upcoming_events
SELECT * FROM get_upcoming_events();

-- 4. Verificar políticas RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'events';

-- 5. Insertar un evento de prueba con fecha futura
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
) VALUES (
  'EVENTO DE PRUEBA - Sanación Inmediata',
  'Evento de prueba para verificar que el sistema funciona correctamente.',
  (SELECT id FROM facilitators WHERE name = 'María González' LIMIT 1),
  NOW() + INTERVAL '1 day', -- Mañana
  90,
  'Online',
  true,
  20,
  5,
  200,
  'active',
  '/placeholder.svg?height=200&width=300&text=Evento+Prueba',
  ARRAY[
    'Sesión de prueba de 90 minutos',
    'Verificación del sistema',
    'Grabación incluida'
  ]
) ON CONFLICT DO NOTHING;

-- 6. Verificar el evento recién insertado
SELECT 
  title,
  event_date,
  status,
  (event_date > NOW()) as is_future_event
FROM events 
WHERE title LIKE '%PRUEBA%';
