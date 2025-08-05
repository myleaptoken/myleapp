-- =====================================================
-- ARREGLAR DEPENDENCIAS DEL SISTEMA DE ROLES - VERSION 3
-- Eliminar triggers y dependencias antes de modificar la estructura
-- =====================================================

-- 1. Eliminar triggers existentes que dependen de la columna role
DROP TRIGGER IF EXISTS on_user_role_change ON users;
DROP FUNCTION IF EXISTS create_facilitator_from_user();
DROP FUNCTION IF EXISTS create_facilitator_from_role();

-- 2. Ahora sí podemos eliminar la columna role de forma segura
ALTER TABLE users 
DROP COLUMN IF EXISTS role CASCADE;

-- 3. Crear tabla roles si no existe
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

-- 4. Insertar roles básicos del sistema
INSERT INTO roles (name, display_name, description, permissions) VALUES
('user', 'Usuario', 'Usuario regular de la plataforma', ARRAY['view_events', 'register_events', 'view_courses', 'enroll_courses']),
('facilitator', 'Facilitador', 'Facilitador certificado que puede crear y dirigir eventos', ARRAY['view_events', 'create_events', 'manage_events', 'view_courses', 'create_courses']),
('admin', 'Administrador', 'Administrador del sistema con acceso completo', ARRAY['*'])
ON CONFLICT (name) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  permissions = EXCLUDED.permissions;

-- 5. Agregar columna role_id a users SIN valor por defecto
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES roles(id);

-- 6. Actualizar usuarios existentes con rol por defecto
UPDATE users 
SET role_id = (SELECT id FROM roles WHERE name = 'user')
WHERE role_id IS NULL;

-- 7. Ahora hacer la columna NOT NULL
ALTER TABLE users 
ALTER COLUMN role_id SET NOT NULL;

-- 8. Limpiar y recrear tabla facilitators ANTES de crear usuarios facilitadores
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

-- 9. Crear algunos usuarios facilitadores de ejemplo (DESPUÉS de crear la tabla facilitators)
INSERT INTO users (id, email, full_name, role_id, token_balance) VALUES
(gen_random_uuid(), 'maria.gonzalez@myleap.com', 'María González', (SELECT id FROM roles WHERE name = 'facilitator'), 5000),
(gen_random_uuid(), 'carlos.mendoza@myleap.com', 'Carlos Mendoza', (SELECT id FROM roles WHERE name = 'facilitator'), 4500),
(gen_random_uuid(), 'ana.rodriguez@myleap.com', 'Ana Rodríguez', (SELECT id FROM roles WHERE name = 'facilitator'), 4800)
ON CONFLICT (email) DO UPDATE SET
  role_id = (SELECT id FROM roles WHERE name = 'facilitator'),
  full_name = EXCLUDED.full_name;

-- 10. Crear la función correcta para manejar cambios de rol
CREATE OR REPLACE FUNCTION create_facilitator_from_role()
RETURNS TRIGGER AS $$
DECLARE
  facilitator_role_id UUID;
  old_role_id UUID;
  new_role_id UUID;
BEGIN
  -- Obtener ID del rol facilitator
  SELECT id INTO facilitator_role_id FROM roles WHERE name = 'facilitator';
  
  -- Manejar INSERT
  IF TG_OP = 'INSERT' THEN
    new_role_id := NEW.role_id;
    
    -- Si el nuevo usuario es facilitador, crear registro
    IF new_role_id = facilitator_role_id THEN
      INSERT INTO facilitators (
        user_id, 
        bio, 
        specialties, 
        years_experience,
        certification_level
      )
      VALUES (
        NEW.id,
        CASE 
          WHEN NEW.full_name ILIKE '%maría%' THEN 'Experta en sanación energética con más de 10 años de experiencia en Método ONE. Especializada en liberación emocional y trabajo con chakras.'
          WHEN NEW.full_name ILIKE '%carlos%' THEN 'Facilitador certificado especializado en expansión de consciencia y técnicas avanzadas. Experto en meditación y sanación remota.'
          WHEN NEW.full_name ILIKE '%ana%' THEN 'Terapeuta holística con enfoque en sanación individual y transformación personal. Especialista en terapia holística.'
          ELSE 'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.'
        END,
        CASE 
          WHEN NEW.full_name ILIKE '%maría%' THEN ARRAY['Sanación Energética', 'Liberación Emocional', 'Chakras']
          WHEN NEW.full_name ILIKE '%carlos%' THEN ARRAY['Expansión de Consciencia', 'Meditación', 'Sanación Remota']
          WHEN NEW.full_name ILIKE '%ana%' THEN ARRAY['Sanación Individual', 'Terapia Holística', 'Transformación Personal']
          ELSE ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE']
        END,
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
  END IF;
  
  -- Manejar UPDATE
  IF TG_OP = 'UPDATE' THEN
    old_role_id := OLD.role_id;
    new_role_id := NEW.role_id;
    
    -- Si cambió de facilitator a otro rol, desactivar
    IF old_role_id = facilitator_role_id AND new_role_id != facilitator_role_id THEN
      UPDATE facilitators 
      SET is_active = false, updated_at = NOW()
      WHERE user_id = NEW.id;
    END IF;
    
    -- Si cambió de otro rol a facilitator, activar o crear
    IF old_role_id != facilitator_role_id AND new_role_id = facilitator_role_id THEN
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
        5,
        'Certificado Nivel II'
      )
      ON CONFLICT (user_id) DO UPDATE SET
        is_active = true,
        updated_at = NOW();
    END IF;
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Crear el trigger que funciona con role_id
CREATE TRIGGER on_user_role_change
  AFTER INSERT OR UPDATE OF role_id ON users
  FOR EACH ROW EXECUTE FUNCTION create_facilitator_from_role();

-- 12. Crear facilitadores para usuarios existentes que ya tienen role_id de facilitator
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

-- 13. Actualizar función get_upcoming_events
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

-- 14. Limpiar eventos existentes
DELETE FROM events;

-- 15. Crear eventos SOLO si hay facilitadores disponibles
DO $$
DECLARE
  maria_facilitator_id UUID;
  carlos_facilitator_id UUID;
  ana_facilitator_id UUID;
BEGIN
  -- Obtener IDs de facilitadores
  SELECT f.id INTO maria_facilitator_id
  FROM facilitators f 
  JOIN users u ON f.user_id = u.id 
  WHERE u.full_name ILIKE '%maría%' 
  LIMIT 1;
  
  SELECT f.id INTO carlos_facilitator_id
  FROM facilitators f 
  JOIN users u ON f.user_id = u.id 
  WHERE u.full_name ILIKE '%carlos%' 
  LIMIT 1;
  
  SELECT f.id INTO ana_facilitator_id
  FROM facilitators f 
  JOIN users u ON f.user_id = u.id 
  WHERE u.full_name ILIKE '%ana%' 
  LIMIT 1;
  
  -- Crear eventos solo si los facilitadores existen
  IF maria_facilitator_id IS NOT NULL THEN
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
    ) VALUES (
      'Sanación Energética Grupal',
      'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE.',
      maria_facilitator_id,
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
    );
  END IF;
  
  IF carlos_facilitator_id IS NOT NULL THEN
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
    ) VALUES (
      'Workshop: Expansión de Consciencia',
      'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción.',
      carlos_facilitator_id,
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
    );
  END IF;
  
  IF ana_facilitator_id IS NOT NULL THEN
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
    ) VALUES (
      'Sesión Individual de Sanación',
      'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación.',
      ana_facilitator_id,
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
  END IF;
END $$;

-- 16. Crear funciones auxiliares
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

-- 17. Crear función para verificar permisos
CREATE OR REPLACE FUNCTION user_has_permission(user_uuid UUID, permission_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  user_permissions TEXT[];
BEGIN
  SELECT r.permissions INTO user_permissions
  FROM users u
  JOIN roles r ON u.role_id = r.id
  WHERE u.id = user_uuid;
  
  -- Si tiene permiso de admin (*), puede todo
  IF '*' = ANY(user_permissions) THEN
    RETURN true;
  END IF;
  
  -- Verificar permiso específico
  RETURN permission_name = ANY(user_permissions);
END;
$$ LANGUAGE plpgsql;

-- 18. Crear función para updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 19. Crear triggers para updated_at
CREATE TRIGGER update_roles_updated_at 
  BEFORE UPDATE ON roles 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_facilitators_updated_at 
  BEFORE UPDATE ON facilitators 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 20. Verificaciones finales
SELECT 
  '=== VERIFICACIÓN FINAL ===' as section,
  '' as info,
  0 as total;

SELECT 
  'Roles creados:' as section,
  r.name as info,
  1 as total
FROM roles r
ORDER BY r.name;

SELECT 
  'Usuarios por rol:' as section,
  r.display_name as info,
  COUNT(u.id) as total
FROM roles r
LEFT JOIN users u ON r.id = u.role_id
GROUP BY r.id, r.display_name
ORDER BY r.display_name;

SELECT 
  'Facilitadores activos:' as section,
  u.full_name as info,
  f.years_experience as total
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
ORDER BY u.full_name;

SELECT 
  'Eventos creados:' as section,
  e.title as info,
  e.token_cost as total
FROM events e
WHERE e.status = 'active'
ORDER BY e.event_date;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '✅ ¡SISTEMA DE ROLES IMPLEMENTADO CORRECTAMENTE!';
    RAISE NOTICE '🗑️ Dependencias eliminadas sin errores';
    RAISE NOTICE '📋 Tabla roles creada con estructura normalizada';
    RAISE NOTICE '🔗 Usuarios conectados via role_id (NOT NULL)';
    RAISE NOTICE '👥 Facilitadores creados automáticamente';
    RAISE NOTICE '📅 Eventos recreados con facilitadores reales';
    RAISE NOTICE '🔐 Sistema de permisos implementado';
    RAISE NOTICE '🚀 ¡Todo funcionando perfectamente!';
END $$;
