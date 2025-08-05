-- =====================================================
-- ARREGLAR FUNCIÓN get_upcoming_events PARA USAR role_id
-- =====================================================

-- Eliminar función anterior
DROP FUNCTION IF EXISTS get_upcoming_events();

-- Recrear función con role_id y tipos correctos
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
    u.full_name as facilitator_name,
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
    COALESCE(e.image_url, '') as image_url,
    COALESCE(e.video_url, '') as video_url,
    e.what_includes
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

-- Verificar que la función funciona
SELECT 'FUNCIÓN ARREGLADA' as status, COUNT(*) as eventos_encontrados 
FROM get_upcoming_events();

-- Mostrar eventos que debería retornar
SELECT 
  '=== EVENTOS QUE DEBERÍA MOSTRAR LA FUNCIÓN ===' as titulo,
  e.title,
  u.full_name as facilitador,
  r.name as rol_facilitador,
  e.event_date::timestamp as fecha_hora,
  e.status,
  f.is_active as facilitador_activo
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
JOIN roles r ON u.role_id = r.id
WHERE e.status = 'active' 
  AND e.event_date > NOW()
  AND f.is_active = true
  AND r.name = 'facilitator'
ORDER BY e.event_date;

-- Si no hay eventos, crear algunos de prueba
DO $$
DECLARE
    event_count INTEGER;
    facilitator_role_id INTEGER;
    first_facilitator_id UUID;
BEGIN
    -- Obtener role_id de facilitator
    SELECT id INTO facilitator_role_id FROM roles WHERE name = 'facilitator';
    
    -- Obtener primer facilitador activo
    SELECT f.id INTO first_facilitator_id 
    FROM facilitators f 
    JOIN users u ON f.user_id = u.id 
    WHERE f.is_active = true AND u.role_id = facilitator_role_id
    LIMIT 1;
    
    -- Contar eventos activos futuros
    SELECT COUNT(*) INTO event_count 
    FROM events e
    JOIN facilitators f ON e.facilitator_id = f.id
    JOIN users u ON f.user_id = u.id
    WHERE e.status = 'active' 
      AND e.event_date > NOW()
      AND f.is_active = true
      AND u.role_id = facilitator_role_id;
    
    IF event_count = 0 AND first_facilitator_id IS NOT NULL THEN
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
          first_facilitator_id,
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
          first_facilitator_id,
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
          first_facilitator_id,
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

-- Verificar resultado final
SELECT 
  '=== RESUMEN FINAL ===' as titulo,
  (SELECT COUNT(*) FROM get_upcoming_events()) as eventos_en_funcion_rpc,
  (SELECT COUNT(*) FROM facilitators f JOIN users u ON f.user_id = u.id JOIN roles r ON u.role_id = r.id WHERE f.is_active = true AND r.name = 'facilitator') as facilitadores_activos;

-- Probar la función una vez más
SELECT 'PRUEBA FINAL DE LA FUNCIÓN' as test, * FROM get_upcoming_events() LIMIT 3;
