-- 🔍 SCRIPT DE DEBUG COMPLETO
-- Ejecuta este script para verificar todo

-- 1. Verificar eventos activos y futuros
SELECT 
  '=== EVENTOS ACTIVOS Y FUTUROS ===' as debug_section;

SELECT 
  id,
  title,
  event_date,
  status,
  facilitator_id,
  NOW() as current_time,
  (event_date > NOW()) as is_future,
  (status = 'active') as is_active
FROM events 
WHERE status = 'active' AND event_date > NOW()
ORDER BY event_date;

-- 2. Verificar que la función RPC existe y funciona
SELECT 
  '=== FUNCIÓN GET_UPCOMING_EVENTS ===' as debug_section;

-- Verificar si la función existe
SELECT 
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines 
WHERE routine_name = 'get_upcoming_events';

-- Probar la función
SELECT * FROM get_upcoming_events() LIMIT 3;

-- 3. Verificar facilitadores
SELECT 
  '=== FACILITADORES ===' as debug_section;

SELECT id, name, email, is_active FROM facilitators WHERE is_active = true;

-- 4. Verificar políticas RLS
SELECT 
  '=== POLÍTICAS RLS ===' as debug_section;

SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename IN ('events', 'facilitators');

-- 5. Crear evento de prueba AHORA MISMO
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
  '🚨 DEBUG EVENT - ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
  'Evento creado para debug del frontend. Si ves esto, la conexión funciona.',
  (SELECT id FROM facilitators WHERE name = 'María González' LIMIT 1),
  NOW() + INTERVAL '2 hours', -- En 2 horas
  60,
  'Online DEBUG',
  true,
  10,
  1,
  100,
  'active',
  '/placeholder.svg?height=200&width=300&text=DEBUG+EVENT',
  ARRAY[
    'Evento de prueba para debug',
    'Verificación de conexión frontend',
    'Si aparece, todo funciona'
  ]
) ON CONFLICT DO NOTHING;

-- 6. Verificar el evento recién creado
SELECT 
  '=== EVENTO DEBUG CREADO ===' as debug_section;

SELECT 
  title,
  event_date,
  status,
  facilitator_id,
  (event_date > NOW()) as is_future
FROM events 
WHERE title LIKE '%DEBUG EVENT%'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Contar eventos por status
SELECT 
  '=== RESUMEN POR STATUS ===' as debug_section;

SELECT 
  status,
  COUNT(*) as total,
  COUNT(CASE WHEN event_date > NOW() THEN 1 END) as futuros
FROM events 
GROUP BY status;
