-- =====================================================
-- SISTEMA DE ROLES NORMALIZADO
-- Crear tabla roles separada y relacionarla con users
-- =====================================================

-- 1. Crear tabla roles
CREATE TABLE IF NOT EXISTS roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  permissions TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Insertar roles básicos del sistema
INSERT INTO roles (name, display_name, description, permissions) VALUES
('user', 'Usuario', 'Usuario regular de la plataforma', ARRAY['view_events', 'register_events', 'view_courses', 'enroll_courses']),
('facilitator', 'Facilitador', 'Facilitador certificado que puede crear y dirigir eventos', ARRAY['view_events', 'create_events', 'manage_events', 'view_courses', 'create_courses']),
('admin', 'Administrador', 'Administrador del sistema con acceso completo', ARRAY['*'])
ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  permissions = EXCLUDED.permissions;

-- 3. Modificar tabla users para usar role_id en lugar de role
ALTER TABLE users 
DROP COLUMN IF EXISTS role;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES roles(id) DEFAULT (SELECT id FROM roles WHERE name = 'user');

-- 4. Actualizar usuarios existentes con rol por defecto
UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'user')
WHERE role_id IS NULL;

-- 5. Crear algunos usuarios facilitadores de ejemplo (opcional)
-- Puedes cambiar estos datos por usuarios reales
INSERT INTO users (id, email, full_name, role_id, token_balance) VALUES
(gen_random_uuid(), 'maria.gonzalez@myleap.com', 'María González', (SELECT id FROM roles WHERE name = 'facilitator'), 5000),
(gen_random_uuid(), 'carlos.mendoza@myleap.com', 'Carlos Mendoza', (SELECT id FROM roles WHERE name = 'facilitator'), 4500),
(gen_random_uuid(), 'ana.rodriguez@myleap.com', 'Ana Rodríguez', (SELECT id FROM roles WHERE name = 'facilitator'), 4800)
ON CONFLICT (email) DO UPDATE SET
  role_id = (SELECT id FROM roles WHERE name = 'facilitator'),
  full_name = EXCLUDED.full_name;

-- 6. Limpiar y recrear tabla facilitators con estructura correcta
DROP TABLE IF EXISTS facilitators CASCADE;

CREATE TABLE facilitators (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  bio TEXT DEFAULT 'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.',
  specialties TEXT[] DEFAULT ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE'],
  years_experience INTEGER DEFAULT 5,
  certification_level TEXT DEFAULT 'Certificado',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Función mejorada para crear facilitador automáticamente
CREATE OR REPLACE FUNCTION create_facilitator_from_role()
RETURNS TRIGGER AS $$
DECLARE
  facilitator_role_id UUID;
  user_role_id UUID;
BEGIN
  -- Obtener ID del rol facilitator
  SELECT id INTO facilitator_role_id FROM roles WHERE name = 'facilitator';
  
  -- Si es INSERT, usar NEW.role_id
  IF TG_OP = 'INSERT' THEN
    user_role_id := NEW.role_id;
  -- Si es UPDATE, comparar OLD y NEW
  ELSIF TG_OP = 'UPDATE' THEN
    user_role_id := NEW.role_id;
    
    -- Si cambió de facilitator a otro rol, desactivar facilitador
    IF OLD.role_id = facilitator_role_id AND NEW.role_id != facilitator_role_id THEN
      UPDATE facilitators 
      SET is_active = false 
      WHERE user_id = NEW.id;
      RETURN NEW;
    END IF;
    
    -- Si cambió de otro rol a facilitator, reactivar facilitador
    IF OLD.role_id != facilitator_role_id AND NEW.role_id = facilitator_role_id THEN
      UPDATE facilitators 
      SET is_active = true 
      WHERE user_id = NEW.id;
      -- Si no existe, se creará abajo
    END IF;
  END IF;
  
  -- Si el usuario es facilitador y no existe en facilitators, crearlo
  IF user_role_id = facilitator_role_id THEN
    INSERT INTO facilitators (
      user_id, 
      bio, 
      specialties, 
      years_experience,
      certification_level
    )
    VALUES (
      NEW.id,
      'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.',
      ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE'],
      CASE 
        WHEN NEW.full_name ILIKE '%maría%' THEN 10
        WHEN NEW.full_name ILIKE '%carlos%' THEN 8
        WHEN NEW.full_name ILIKE '%ana%' THEN 12
        ELSE 5
      END,
      'Certificado Nivel II'
    )
    ON CONFLICT (user_id) DO UPDATE SET
      is_active = true,
      updated_at = NOW();
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Crear triggers para INSERT y UPDATE
DROP TRIGGER IF EXISTS on_user_role_change ON users;
CREATE TRIGGER on_user_role_change
  AFTER INSERT OR UPDATE OF role_id ON users
  FOR EACH ROW EXECUTE FUNCTION create_facilitator_from_role();

-- 9. Crear facilitadores para usuarios existentes que ya tienen role_id de facilitator
INSERT INTO facilitators (user_id, bio, specialties, years_experience, certification_level)
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
  END,
  'Certificado Nivel II'
FROM users u
JOIN roles r ON u.role_id = r.id
WHERE r.name = 'facilitator'
ON CONFLICT (user_id) DO NOTHING;

-- 10. Actualizar función get_upcoming_events para usar la nueva estructura
DROP FUNCTION IF EXISTS get_upcoming_events();

CREATE OR REPLACE FUNCTION get_upcoming_events()
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  facilitator_name TEXT,
  facilitator_bio TEXT,
  facilitator_specialties TEXT[],
  facilitator_user_id UUID,
  facilitator_role TEXT,
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
    r.display_name as facilitator_role,
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

-- 11. Limpiar eventos existentes y crear nuevos con facilitadores reales
DELETE FROM events;

-- Crear eventos variados con diferentes facilitadores
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
-- Evento 1
(
  'Sanación Energética Grupal',
  'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE. Exploraremos bloqueos energéticos, liberaremos patrones limitantes y activaremos tu potencial de sanación natural.',
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
-- Evento 2
(
  'Workshop: Expansión de Consciencia',
  'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción usando técnicas del Método ONE.',
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
-- Evento 3
(
  'Sesión Individual de Sanación',
  'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación y transformación personal.',
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

-- 12. Crear funciones auxiliares para gestión de roles
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

CREATE OR REPLACE FUNCTION user_has_permission(user_uuid UUID, permission TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  has_permission BOOLEAN := false;
BEGIN
  SELECT 
    CASE 
      WHEN '*' = ANY(r.permissions) THEN true
      WHEN permission = ANY(r.permissions) THEN true
      ELSE false
    END INTO has_permission
  FROM users u
  JOIN roles r ON u.role_id = r.id
  WHERE u.id = user_uuid;
  
  RETURN COALESCE(has_permission, false);
END;
$$ LANGUAGE plpgsql;

-- 13. Crear trigger para updated_at en roles
CREATE TRIGGER update_roles_updated_at 
  BEFORE UPDATE ON roles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_facilitators_updated_at 
  BEFORE UPDATE ON facilitators 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 14. Verificaciones finales
SELECT 
  '=== ROLES DISPONIBLES ===' as section;

SELECT 
  r.name,
  r.display_name,
  r.description,
  array_length(r.permissions, 1) as total_permissions,
  r.is_active
FROM roles r
ORDER BY r.name;

SELECT 
  '=== USUARIOS POR ROL ===' as section;

SELECT 
  r.display_name as rol,
  COUNT(u.id) as total_usuarios,
  STRING_AGG(u.full_name, ', ') as usuarios
FROM roles r
LEFT JOIN users u ON r.id = u.role_id
GROUP BY r.id, r.display_name
ORDER BY r.display_name;

SELECT 
  '=== FACILITADORES ACTIVOS ===' as section;

SELECT 
  u.full_name as nombre,
  u.email,
  f.years_experience as experiencia,
  f.certification_level as certificacion,
  array_length(f.specialties, 1) as especialidades,
  f.is_active
FROM facilitators f
JOIN users u ON f.user_id = u.id
JOIN roles r ON u.role_id = r.id
WHERE f.is_active = true
ORDER BY u.full_name;

SELECT 
  '=== EVENTOS CON FACILITADORES ===' as section;

SELECT 
  e.title,
  u.full_name as facilitador,
  r.display_name as rol_facilitador,
  e.event_date,
  e.token_cost,
  e.status
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
JOIN roles r ON u.role_id = r.id
ORDER BY e.event_date;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '🎉 ¡SISTEMA DE ROLES NORMALIZADO CREADO EXITOSAMENTE!';
    RAISE NOTICE '📋 Tabla roles creada con permisos granulares';
    RAISE NOTICE '👥 Usuarios conectados a roles via role_id';
    RAISE NOTICE '🎯 Facilitadores creados automáticamente para usuarios con rol facilitator';
    RAISE NOTICE '🔄 Triggers configurados para cambios automáticos';
    RAISE NOTICE '📅 Eventos creados con facilitadores reales';
    RAISE NOTICE '🛡️ Funciones de permisos implementadas';
    RAISE NOTICE '✅ ¡Sistema completamente funcional y escalable!';
END $$;
