-- Actualizar las fechas de los eventos para que sean futuras
-- Movemos todos los eventos de 2024 a 2025

UPDATE events 
SET event_date = event_date + INTERVAL '1 year'
WHERE EXTRACT(YEAR FROM event_date) = 2024;

-- Verificar las fechas actualizadas
SELECT 
  title,
  event_date,
  status,
  (event_date > NOW()) as is_future_event
FROM events 
ORDER BY event_date;

-- También podemos agregar algunos eventos más recientes
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
  'Activación de Chakras - Sesión Grupal',
  'Sesión especializada en activación y equilibrio de los 7 chakras principales usando técnicas del Método ONE.',
  (SELECT id FROM facilitators WHERE name = 'María González' LIMIT 1),
  NOW() + INTERVAL '3 days',
  105,
  'Online',
  true,
  18,
  7,
  350,
  'active',
  '/placeholder.svg?height=200&width=300&text=Activación+Chakras',
  ARRAY[
    'Sesión de activación de 105 minutos',
    'Meditaciones para cada chakra',
    'Kit de cristales (envío incluido)',
    'Grabación de la sesión',
    'Guía de mantenimiento energético'
  ]
),
(
  'Sanación del Niño Interior',
  'Workshop profundo para sanar heridas de la infancia y reconectar con tu esencia más pura.',
  (SELECT id FROM facilitators WHERE name = 'Ana Rodríguez' LIMIT 1),
  NOW() + INTERVAL '5 days',
  180,
  'Madrid, España',
  false,
  12,
  4,
  550,
  'active',
  '/placeholder.svg?height=200&width=300&text=Niño+Interior',
  ARRAY[
    'Workshop intensivo de 3 horas',
    'Técnicas de regresión guiada',
    'Trabajo con arquetipos infantiles',
    'Material de apoyo personalizado',
    'Sesión de seguimiento individual'
  ]
),
(
  'Círculo de Medicina Ancestral',
  'Ceremonia sagrada con plantas maestras y técnicas ancestrales de sanación energética.',
  (SELECT id FROM facilitators WHERE name = 'Carlos Mendoza' LIMIT 1),
  NOW() + INTERVAL '1 week',
  240,
  'Online',
  true,
  8,
  3,
  750,
  'active',
  '/placeholder.svg?height=200&width=300&text=Medicina+Ancestral',
  ARRAY[
    'Ceremonia de 4 horas',
    'Preparación pre-ceremonia',
    'Kit de medicina sagrada',
    'Integración post-ceremonia',
    'Acompañamiento durante 1 semana'
  ]
)
ON CONFLICT DO NOTHING;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '✅ Fechas de eventos actualizadas exitosamente';
    RAISE NOTICE '📅 Todos los eventos ahora tienen fechas futuras';
    RAISE NOTICE '🎯 Los eventos deberían aparecer en el dashboard';
END $$;
