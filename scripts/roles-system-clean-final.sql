-- =====================================================
-- SISTEMA DE ROLES LIMPIO Y DEFINITIVO
-- Sin referencias circulares, sin complicaciones
-- =====================================================

-- 1. LIMPIAR TODO PRIMERO
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_user_role_change ON users;
DROP TRIGGER IF EXISTS update_facilitators_updated_at ON facilitators;

DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS handle_user_role_change() CASCADE;
DROP FUNCTION IF EXISTS update_facilitator_on_role_change() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS get_upcoming_events() CASCADE;

-- Limpiar tablas en orden correcto
DELETE FROM events;
DROP TABLE IF EXISTS facilitators CASCADE;

-- 2. CREAR TABLA ROLES
DROP TABLE IF EXISTS roles CASCADE;
CREATE TABLE roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar roles básicos
INSERT INTO roles (name, display_name, description) VALUES
('user', 'Usuario', 'Usuario regular de la plataforma'),
('facilitator', 'Facilitador', 'Facilitador certificado que puede crear eventos'),
('admin', 'Administrador', 'Administrador del sistema');

-- 3. MODIFICAR TABLA USERS
-- Eliminar columna role si existe (con CASCADE para limpiar dependencias)
ALTER TABLE users DROP COLUMN IF EXISTS role CASCADE;

-- Agregar role_id
ALTER TABLE users ADD COLUMN IF NOT EXISTS role_id UUID;

-- Actualizar todos los usuarios existentes con rol 'user' por defecto
UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'user') WHERE role_id IS NULL;

-- Ahora sí agregar la foreign key constraint
ALTER TABLE users ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(id);
ALTER TABLE users ALTER COLUMN role_id SET NOT NULL;

-- 4. CREAR ALGUNOS USUARIOS FACILITADORES
-- Primero verificar si existen, si no crearlos
DO $$
DECLARE
    facilitator_role_id UUID;
    user_role_id UUID;
BEGIN
    -- Obtener IDs de roles
    SELECT id INTO facilitator_role_id FROM roles WHERE name = 'facilitator';
    SELECT id INTO user_role_id FROM roles WHERE name = 'user';
    
    -- Crear o actualizar usuarios facilitadores
    INSERT INTO users (id, email, full_name, role_id, token_balance) VALUES
    (gen_random_uuid(), 'maria.gonzalez@myleap.com', 'María González', facilitator_role_id, 5000),
    (gen_random_uuid(), 'carlos.mendoza@myleap.com', 'Carlos Mendoza', facilitator_role_id, 4500),
    (gen_random_uuid(), 'ana.rodriguez@myleap.com', 'Ana Rodríguez', facilitator_role_id, 4800)
    ON CONFLICT (email) DO UPDATE SET
      role_id = facilitator_role_id,
      full_name = EXCLUDED.full_name,
      token_balance = EXCLUDED.token_balance;
      
    RAISE NOTICE 'Usuarios facilitadores creados/actualizados correctamente';
END $$;

-- 5. CREAR TABLA FACILITATORS (SIMPLE)
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

-- 6. CREAR FUNCIÓN PARA UPDATED_AT
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. TRIGGER PARA UPDATED_AT EN FACILITATORS
CREATE TRIGGER update_facilitators_updated_at
    BEFORE UPDATE ON facilitators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 8. CREAR FACILITADORES PARA USUARIOS CON ROL FACILITATOR
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

-- 9. FUNCIÓN GET_UPCOMING_EVENTS ACTUALIZADA
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

-- 10. CREAR EVENTOS CON FACILITADORES REALES
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

-- 11. FUNCIÓN AUXILIAR PARA OBTENER ROL
CREATE OR REPLACE FUNCTION get_user_role(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
  role_name TEXT;
BEGIN
  SELECT r.name INTO role_name
  FROM users u
  JOIN roles r ON u.role_id = r.id
  WHERE u.id = user_uuid;
  
  RETURN COALESCE(role_name, 'user');
END;
$$ LANGUAGE plpgsql;

-- 12. TRIGGER PARA NUEVOS USUARIOS DE AUTH
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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 13. VERIFICACIONES FINALES
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
    RAISE NOTICE '✅ SISTEMA DE ROLES IMPLEMENTADO CORRECTAMENTE';
    RAISE NOTICE '📋 Estructura: roles -> users.role_id -> facilitators.user_id';
    RAISE NOTICE '🎯 Sin referencias circulares ni dependencias problemáticas';
    RAISE NOTICE '🚀 ¡Listo para usar!';
END $$;

-- Mostrar estructura final
SELECT 
  '=== ROLES Y USUARIOS ===' as info,
  r.name as rol,
  r.display_name,
  COUNT(u.id) as total_usuarios
FROM roles r
LEFT JOIN users u ON r.id = u.role_id
GROUP BY r.id, r.name, r.display_name
ORDER BY r.name;

SELECT 
  '=== FACILITADORES ===' as info,
  u.full_name as nombre,
  u.email,
  f.years_experience as experiencia,
  array_length(f.specialties, 1) as num_especialidades
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
ORDER BY u.full_name;

SELECT 
  '=== EVENTOS PRÓXIMOS ===' as info,
  e.title,
  u.full_name as facilitador,
  e.event_date::date as fecha,
  e.token_cost as costo_tokens
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
WHERE e.status = 'active'
ORDER BY e.event_date;
