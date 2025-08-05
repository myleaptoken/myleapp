-- =====================================================
-- DEBUG: VERIFICAR POR QUÉ NO SE VEN LOS EVENTOS
-- =====================================================

-- 1. Verificar que existen eventos activos
SELECT 
  'EVENTOS EN DB' as check_type,
  COUNT(*) as total_events,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_events,
  COUNT(CASE WHEN event_date > NOW() THEN 1 END) as future_events
FROM events;

-- 2. Verificar facilitadores activos
SELECT 
  'FACILITADORES' as check_type,
  COUNT(*) as total_facilitators,
  COUNT(CASE WHEN is_active = true THEN 1 END) as active_facilitators
FROM facilitators;

-- 3. Verificar la función get_upcoming_events
SELECT 
  'FUNCIÓN RPC' as check_type,
  COUNT(*) as eventos_retornados
FROM get_upcoming_events();

-- 4. Ver eventos específicos con detalles
SELECT 
  e.id,
  e.title,
  e.status,
  e.event_date,
  e.event_date > NOW() as is_future,
  u.full_name as facilitator_name,
  f.is_active as facilitator_active,
  r.name as facilitator_role
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
JOIN roles r ON u.role_id = r.id
ORDER BY e.event_date;

-- 5. Probar la función directamente
SELECT * FROM get_upcoming_events();

-- 6. Si no hay eventos, recrear algunos
DO $$
DECLARE
    event_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO event_count FROM events WHERE status = 'active' AND event_date > NOW();
    
    IF event_count = 0 THEN
        RAISE NOTICE '⚠️  No hay eventos activos futuros, creando algunos...';
        
        -- Crear eventos de prueba
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
          'Sanación Energética - Sesión Especial',
          'Una sesión profunda de sanación energética con técnicas avanzadas.',
          (SELECT f.id FROM facilitators f JOIN users u ON f.user_id = u.id WHERE u.full_name ILIKE '%maría%' LIMIT 1),
          NOW() + INTERVAL '1 day',
          90,
          'Online',
          true,
          20,
          5,
          250,
          'active',
          '/placeholder.svg?height=200&width=300&text=Sanación+Energética',
          ARRAY[
            'Sesión de sanación de 90 minutos',
            'Material de apoyo',
            'Grabación disponible',
            'Certificado de participación'
          ]
        ),
        (
          'Workshop de Expansión Consciente',
          'Taller intensivo para expandir tu consciencia y percepción.',
          (SELECT f.id FROM facilitators f JOIN users u ON f.user_id = u.id WHERE u.full_name ILIKE '%carlos%' LIMIT 1),
          NOW() + INTERVAL '3 days',
          120,
          'Madrid, España',
          false,
          15,
          8,
          400,
          'active',
          '/placeholder.svg?height=200&width=300&text=Workshop+Consciencia',
          ARRAY[
            'Workshop de 2 horas',
            'Manual del participante',
            'Técnicas avanzadas',
            'Certificado'
          ]
        ),
        (
          'Sesión Individual Personalizada',
          'Sesión uno a uno completamente personalizada para tu proceso.',
          (SELECT f.id FROM facilitators f JOIN users u ON f.user_id = u.id WHERE u.full_name ILIKE '%ana%' LIMIT 1),
          NOW() + INTERVAL '5 days',
          60,
          'Online',
          true,
          1,
          0,
          500,
          'active',
          '/placeholder.svg?height=200&width=300&text=Sesión+Individual',
          ARRAY[
            'Sesión individual de 60 minutos',
            'Diagnóstico personalizado',
            'Plan específico',
            'Seguimiento'
          ]
        );
        
        RAISE NOTICE '✅ Eventos de prueba creados';
    ELSE
        RAISE NOTICE '✅ Ya existen % eventos activos futuros', event_count;
    END IF;
END $$;

-- 7. Verificar resultado final
SELECT 
  '=== RESUMEN FINAL ===' as titulo,
  (SELECT COUNT(*) FROM events WHERE status = 'active' AND event_date > NOW()) as eventos_activos_futuros,
  (SELECT COUNT(*) FROM facilitators WHERE is_active = true) as facilitadores_activos,
  (SELECT COUNT(*) FROM get_upcoming_events()) as eventos_en_funcion_rpc;

-- 8. Mostrar eventos que deberían aparecer
SELECT 
  'EVENTOS QUE DEBERÍAN APARECER' as seccion,
  e.title,
  u.full_name as facilitador,
  e.event_date::timestamp as fecha_hora,
  e.status,
  f.is_active as facilitador_activo
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
WHERE e.status = 'active' 
  AND e.event_date > NOW()
  AND f.is_active = true
ORDER BY e.event_date;
