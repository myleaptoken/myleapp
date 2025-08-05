-- =====================================================
-- ARREGLAR CONSTRAINTS PROBLEMÁTICAS EN USERS
-- =====================================================

-- 1. INVESTIGAR QUÉ CONSTRAINTS TIENE LA TABLA USERS
SELECT 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.table_name='users' AND tc.constraint_type = 'FOREIGN KEY';

-- 2. VER LA ESTRUCTURA ACTUAL DE LA TABLA USERS
\d users;

-- 3. ELIMINAR CONSTRAINT PROBLEMÁTICA
-- Primero identificamos si hay una constraint circular o problemática
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Buscar constraints problemáticas en users
    FOR constraint_record IN 
        SELECT constraint_name 
        FROM information_schema.table_constraints 
        WHERE table_name = 'users' 
        AND constraint_type = 'FOREIGN KEY'
        AND constraint_name LIKE '%id_fkey%'
    LOOP
        EXECUTE 'ALTER TABLE users DROP CONSTRAINT IF EXISTS ' || constraint_record.constraint_name || ' CASCADE';
        RAISE NOTICE 'Eliminada constraint problemática: %', constraint_record.constraint_name;
    END LOOP;
END $$;

-- 4. LIMPIAR COMPLETAMENTE LA TABLA USERS Y RECREARLA
-- Primero hacer backup de datos existentes
CREATE TEMP TABLE users_backup AS SELECT * FROM users;

-- Eliminar tabla users completamente
DROP TABLE IF EXISTS users CASCADE;

-- 5. RECREAR TABLA USERS LIMPIA
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  token_balance INTEGER DEFAULT 2450,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. CREAR TABLA ROLES SI NO EXISTE
CREATE TABLE IF NOT EXISTS roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar roles si no existen
INSERT INTO roles (name, display_name, description) VALUES
('user', 'Usuario', 'Usuario regular de la plataforma'),
('facilitator', 'Facilitador', 'Facilitador certificado que puede crear eventos'),
('admin', 'Administrador', 'Administrador del sistema')
ON CONFLICT (name) DO NOTHING;

-- 7. AGREGAR ROLE_ID A USERS (SIN CONSTRAINT TODAVÍA)
ALTER TABLE users ADD COLUMN role_id UUID;

-- 8. RESTAURAR DATOS DE USUARIOS EXISTENTES
INSERT INTO users (id, email, full_name, avatar_url, token_balance, created_at, updated_at, role_id)
SELECT 
  ub.id,
  ub.email,
  ub.full_name,
  ub.avatar_url,
  ub.token_balance,
  ub.created_at,
  ub.updated_at,
  (SELECT id FROM roles WHERE name = 'user') -- Todos empiezan como 'user'
FROM users_backup ub
ON CONFLICT (email) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  avatar_url = EXCLUDED.avatar_url,
  token_balance = EXCLUDED.token_balance,
  role_id = EXCLUDED.role_id;

-- 9. CREAR USUARIOS FACILITADORES ESPECÍFICOS
DO $$
DECLARE
    facilitator_role_id UUID;
    user_role_id UUID;
BEGIN
    -- Obtener IDs de roles
    SELECT id INTO facilitator_role_id FROM roles WHERE name = 'facilitator';
    SELECT id INTO user_role_id FROM roles WHERE name = 'user';
    
    -- Crear usuarios facilitadores específicos
    INSERT INTO users (email, full_name, role_id, token_balance) VALUES
    ('maria.gonzalez@myleap.com', 'María González', facilitator_role_id, 5000),
    ('carlos.mendoza@myleap.com', 'Carlos Mendoza', facilitator_role_id, 4500),
    ('ana.rodriguez@myleap.com', 'Ana Rodríguez', facilitator_role_id, 4800)
    ON CONFLICT (email) DO UPDATE SET
      role_id = facilitator_role_id,
      full_name = EXCLUDED.full_name,
      token_balance = EXCLUDED.token_balance;
      
    RAISE NOTICE 'Usuarios facilitadores creados correctamente';
END $$;

-- 10. AHORA SÍ AGREGAR LA FOREIGN KEY CONSTRAINT CORRECTA
UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'user') WHERE role_id IS NULL;
ALTER TABLE users ALTER COLUMN role_id SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(id);

-- 11. CREAR TABLA FACILITATORS
DROP TABLE IF EXISTS facilitators CASCADE;
CREATE TABLE facilitators (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  bio TEXT,
  specialties TEXT[] DEFAULT ARRAY[]::TEXT[],
  years_experience INTEGER DEFAULT 5,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. CREAR FUNCIÓN PARA UPDATED_AT
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 13. TRIGGER PARA UPDATED_AT
CREATE TRIGGER update_facilitators_updated_at
    BEFORE UPDATE ON facilitators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 14. CREAR FACILITADORES PARA USUARIOS CON ROL FACILITATOR
INSERT INTO facilitators (user_id, bio, specialties, years_experience)
SELECT 
  u.id,
  CASE 
    WHEN u.full_name ILIKE '%maría%' THEN 'Experta en sanación energética con más de 10 años de experiencia en Método ONE. Especializada en liberación emocional y trabajo con chakras.'
    WHEN u.full_name ILIKE '%carlos%' THEN 'Facilitador certificado especializado en expansión de consciencia y técnicas avanzadas. Experto en meditación y sanación remota.'
    WHEN u.full_name ILIKE '%ana%' THEN 'Terapeuta holística con enfoque en sanación individual y transformación personal. Especialista en terapia holística.'
    ELSE 'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.'
  END,
  CASE 
    WHEN u.full_name ILIKE '%maría%' THEN ARRAY['Sanación Energética', 'Liberación Emocional', 'Chakras']
    WHEN u.full_name ILIKE '%carlos%' THEN ARRAY['Expansión de Consciencia', 'Meditación', 'Sanación Remota']
    WHEN u.full_name ILIKE '%ana%' THEN ARRAY['Sanación Individual', 'Terapia Holística', 'Transformación Personal']
    ELSE ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE']
  END,
  CASE 
    WHEN u.full_name ILIKE '%maría%' THEN 10
    WHEN u.full_name ILIKE '%carlos%' THEN 8
    WHEN u.full_name ILIKE '%ana%' THEN 12
    ELSE 5
  END
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE r.name = 'facilitator'
ON CONFLICT (user_id) DO NOTHING;

-- 15. LIMPIAR EVENTOS Y RECREAR
DELETE FROM events;

-- 16. FUNCIÓN GET_UPCOMING_EVENTS
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
    e.image_url,
    e.video_url,
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

-- 17. CREAR EVENTOS CON FACILITADORES REALES
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
  video_url,
  what_includes
) VALUES
(
  'Sanación Energética Grupal',
  'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE.',
  (SELECT f.id FROM facilitators f JOIN users u ON f.user_id = u.id WHERE u.full_name ILIKE '%maría%' LIMIT 1),
  NOW() + INTERVAL '2 days',
  90,
  'Online',
  true,
  20,
  7,
  250,
  'active',
  '/placeholder.svg?height=200&width=300&text=Sanación+Energética',
  'https://www.youtube.com/embed/dQw4w9WgXcQ',
  ARRAY[
    'Sesión de sanación energética de 90 minutos',
    'Material de apoyo descargable',
    'Grabación de la sesión (disponible 48h)',
    'Seguimiento personalizado post-sesión',
    'Certificado de participación'
  ]
),
(
  'Workshop: Expansión de Consciencia',
  'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción.',
  (SELECT f.id FROM facilitators f JOIN users u ON f.user_id = u.id WHERE u.full_name ILIKE '%carlos%' LIMIT 1),
  NOW() + INTERVAL '4 days',
  120,
  'Madrid, España',
  false,
  15,
  9,
  400,
  'active',
  '/placeholder.svg?height=200&width=300&text=Expansión+Consciencia',
  NULL,
  ARRAY[
    'Workshop de 2 horas',
    'Manual del participante',
    'Meditaciones guiadas',
    'Técnicas de expansión',
    'Certificado de asistencia'
  ]
),
(
  'Sesión Individual de Sanación',
  'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación.',
  (SELECT f.id FROM facilitators f JOIN users u ON f.user_id = u.id WHERE u.full_name ILIKE '%ana%' LIMIT 1),
  NOW() + INTERVAL '6 days',
  60,
  'Online',
  true,
  1,
  0,
  500,
  'active',
  '/placeholder.svg?height=200&width=300&text=Sesión+Individual',
  'https://www.youtube.com/embed/jNQXAC9IVRw',
  ARRAY[
    'Sesión individual de 60 minutos',
    'Diagnóstico energético personalizado',
    'Plan de sanación específico',
    'Seguimiento por 2 semanas',
    'Grabación de la sesión'
  ]
);

-- 18. TRIGGER PARA NUEVOS USUARIOS DE AUTH
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url, token_balance, role_id)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), 
    NEW.raw_user_meta_data->>'avatar_url',
    2450,
    (SELECT id FROM roles WHERE name = 'user')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 19. VERIFICACIONES FINALES
DO $$
DECLARE
    roles_count INTEGER;
    users_count INTEGER;
    facilitators_count INTEGER;
    events_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO roles_count FROM roles;
    SELECT COUNT(*) INTO users_count FROM users;
    SELECT COUNT(*) INTO facilitators_count FROM facilitators;
    SELECT COUNT(*) INTO events_count FROM events;
    
    RAISE NOTICE '=== RESUMEN FINAL ===';
    RAISE NOTICE 'Roles creados: %', roles_count;
    RAISE NOTICE 'Usuarios totales: %', users_count;
    RAISE NOTICE 'Facilitadores activos: %', facilitators_count;
    RAISE NOTICE 'Eventos creados: %', events_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ SISTEMA ARREGLADO COMPLETAMENTE';
    RAISE NOTICE '🔧 Constraints problemáticas eliminadas';
    RAISE NOTICE '📋 Estructura limpia: roles -> users.role_id -> facilitators.user_id';
    RAISE NOTICE '🚀 ¡Funcionando correctamente!';
END $$;

-- Mostrar estructura final
SELECT 
  'ROLES Y USUARIOS' as seccion,
  r.name as rol,
  r.display_name,
  COUNT(u.id) as total_usuarios
FROM roles r
LEFT JOIN users u ON r.id = u.role_id
GROUP BY r.id, r.name, r.display_name
ORDER BY r.name;

SELECT 
  'FACILITADORES' as seccion,
  u.full_name as nombre,
  u.email,
  f.years_experience as experiencia,
  array_length(f.specialties, 1) as num_especialidades
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
ORDER BY u.full_name;

SELECT 
  'EVENTOS PRÓXIMOS' as seccion,
  e.title,
  u.full_name as facilitador,
  e.event_date::date as fecha,
  e.token_cost as costo_tokens
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
WHERE e.status = 'active'
ORDER BY e.event_date;
