-- =====================================================
-- DIAGNÓSTICO: POR QUÉ NO HAY EVENTOS
-- =====================================================

-- 1. Verificar que el usuario es facilitator
SELECT 
  '=== VERIFICAR FACILITATOR ===' as seccion,
  u.email,
  u.full_name,
  r.name as rol,
  f.id as facilitator_id,
  f.is_active as facilitator_activo
FROM users u
LEFT JOIN roles r ON u.role_id = r.id
LEFT JOIN facilitators f ON f.user_id = u.id
WHERE u.email = 'myleaptoken@gmail.com';

-- 2. Ver todos los eventos existentes
SELECT 
  '=== TODOS LOS EVENTOS ===' as seccion,
  e.id,
  e.title,
  e.status,
  e.event_date,
  e.event_date > NOW() as es_futuro,
  e.facilitator_id,
  CASE 
    WHEN e.facilitator_id IS NULL THEN 'SIN FACILITADOR'
    ELSE 'CON FACILITADOR'
  END as tiene_facilitador
FROM events e
ORDER BY e.event_date DESC
LIMIT 10;

-- 3. Contar eventos por criterios
SELECT '=== DIAGNÓSTICO DE EVENTOS ===' as seccion;

SELECT 'Total eventos' as criterio, COUNT(*) as cantidad FROM events
UNION ALL
SELECT 'Eventos activos' as criterio, COUNT(*) as cantidad FROM events WHERE status = 'active'
UNION ALL
SELECT 'Eventos futuros' as criterio, COUNT(*) as cantidad FROM events WHERE event_date > NOW()
UNION ALL
SELECT 'Eventos activos futuros' as criterio, COUNT(*) as cantidad FROM events WHERE status = 'active' AND event_date > NOW()
UNION ALL
SELECT 'Eventos con facilitador' as criterio, COUNT(*) as cantidad FROM events WHERE facilitator_id IS NOT NULL
UNION ALL
SELECT 'Facilitadores activos' as criterio, COUNT(*) as cantidad FROM facilitators WHERE is_active = true;

-- 4. Ver eventos que NO cumplen cada criterio
SELECT 
  '=== EVENTOS QUE NO CUMPLEN CRITERIOS ===' as seccion,
  e.title,
  e.status,
  e.event_date,
  e.event_date > NOW() as es_futuro,
  f.is_active as facilitador_activo,
  r.name as rol_facilitador
FROM events e
LEFT JOIN facilitators f ON e.facilitator_id = f.id
LEFT JOIN users u ON f.user_id = u.id
LEFT JOIN roles r ON u.role_id = r.id
WHERE e.status != 'active' 
   OR e.event_date <= NOW() 
   OR f.is_active != true 
   OR r.name != 'facilitator'
ORDER BY e.event_date DESC
LIMIT 5;

-- =====================================================
-- CREAR EVENTOS DE PRUEBA SI NO HAY NINGUNO VÁLIDO
-- =====================================================

-- Obtener el facilitator_id del usuario convertido
DO $$
DECLARE
    facilitator_uuid UUID;
    events_created INTEGER := 0;
BEGIN
    -- Obtener el ID del facilitador
    SELECT f.id INTO facilitator_uuid 
    FROM facilitators f
    JOIN users u ON f.user_id = u.id
    WHERE u.email = 'myleaptoken@gmail.com' AND f.is_active = true;
    
    IF facilitator_uuid IS NOT NULL THEN
        -- Crear eventos de Método ONE si no existen eventos activos futuros
        IF (SELECT COUNT(*) FROM events WHERE status = 'active' AND event_date > NOW()) = 0 THEN
            
            -- Evento 1: Método ONE Nivel I
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
                'Método ONE - Nivel I: Fundamentos',
                'Descubre los fundamentos del Método ONE para la sanación energética y el desarrollo personal. Una experiencia transformadora que te conectará con tu verdadero potencial.',
                facilitator_uuid,
                NOW() + INTERVAL '2 days',
                120,
                'Online - Zoom',
                true,
                25,
                8,
                350,
                'active',
                '/placeholder.svg?height=200&width=300&text=Método+ONE+Nivel+I',
                ARRAY[
                    'Sesión de 2 horas en vivo',
                    'Material de apoyo digital',
                    'Grabación disponible 7 días',
                    'Certificado de participación',
                    'Acceso a comunidad privada'
                ]
            );
            events_created := events_created + 1;
            
            -- Evento 2: Método ONE Nivel II
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
                'Método ONE - Nivel II: Profundización',
                'Profundiza en las técnicas avanzadas del Método ONE. Para quienes ya han completado el Nivel I y desean expandir su práctica de sanación energética.',
                facilitator_uuid,
                NOW() + INTERVAL '5 days',
                150,
                'Madrid, España',
                false,
                15,
                5,
                500,
                'active',
                '/placeholder.svg?height=200&width=300&text=Método+ONE+Nivel+II',
                ARRAY[
                    'Sesión presencial de 2.5 horas',
                    'Manual avanzado incluido',
                    'Práticas individualizadas',
                    'Certificado de nivel avanzado',
                    'Seguimiento personalizado'
                ]
            );
            events_created := events_created + 1;
            
            -- Evento 3: Sesión Individual
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
                'Sesión Individual de Sanación Energética',
                'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación y desarrollo personal.',
                facilitator_uuid,
                NOW() + INTERVAL '1 week',
                90,
                'Online - Sesión Privada',
                true,
                1,
                0,
                750,
                'active',
                '/placeholder.svg?height=200&width=300&text=Sesión+Individual',
                ARRAY[
                    'Sesión privada de 90 minutos',
                    'Diagnóstico energético personalizado',
                    'Plan de trabajo específico',
                    'Grabación de la sesión',
                    'Seguimiento por email'
                ]
            );
            events_created := events_created + 1;
            
            RAISE NOTICE '✅ % eventos de prueba creados exitosamente', events_created;
        ELSE
            RAISE NOTICE '⚠️ Ya existen eventos activos futuros, no se crearon nuevos';
        END IF;
    ELSE
        RAISE NOTICE '❌ No se encontró facilitador activo para crear eventos';
    END IF;
END $$;

-- =====================================================
-- VERIFICAR RESULTADOS FINALES
-- =====================================================

-- Probar la función después de crear eventos
SELECT 'DESPUÉS DE CREAR EVENTOS' as test, COUNT(*) as eventos_encontrados 
FROM get_upcoming_events();

-- Mostrar los eventos que ahora deberían aparecer
SELECT 
  '=== EVENTOS QUE APARECERÁN EN EL DASHBOARD ===' as seccion,
  title,
  facilitator_name,
  event_date::date as fecha,
  token_cost,
  status
FROM get_upcoming_events()
ORDER BY event_date
LIMIT 5;

-- Resumen final
SELECT 
  '=== RESUMEN FINAL ===' as titulo,
  (SELECT COUNT(*) FROM events WHERE status = 'active' AND event_date > NOW()) as eventos_activos_futuros,
  (SELECT COUNT(*) FROM facilitators WHERE is_active = true) as facilitadores_activos,
  (SELECT COUNT(*) FROM get_upcoming_events()) as eventos_en_dashboard;
