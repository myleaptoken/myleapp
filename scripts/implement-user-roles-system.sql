-- 1. Agregar columna role a la tabla users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('user', 'facilitator', 'admin'));

-- 2. Actualizar usuarios existentes - puedes cambiar estos roles según tus usuarios reales
-- Primero vamos a ver qué usuarios tienes
SELECT 
  id,
  email,
  full_name,
  role
FROM users
ORDER BY created_at;

-- 3. Actualizar algunos usuarios para que sean facilitadores
-- Cambia estos emails por los de tus usuarios reales que quieres que sean facilitadores
UPDATE users 
SET role = 'facilitator'
WHERE email IN (
  -- Reemplaza estos emails con los de tus usuarios reales
  'maria@example.com',
  'carlos@example.com'
) OR full_name ILIKE '%maría%' OR full_name ILIKE '%carlos%';

-- 4. Limpiar tabla facilitators existente y recrearla con la nueva estructura
DROP TABLE IF EXISTS facilitators CASCADE;

CREATE TABLE facilitators (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  bio TEXT,
  specialties TEXT[] DEFAULT ARRAY[]::TEXT[],
  years_experience INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Función para crear facilitador automáticamente cuando un user tiene role 'facilitator'
CREATE OR REPLACE FUNCTION create_facilitator_from_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Si el usuario es facilitador y no existe en facilitators, crearlo
  IF NEW.role = 'facilitator' THEN
    INSERT INTO facilitators (user_id, bio, specialties, years_experience)
    VALUES (
      NEW.id,
      'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.',
      ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE'],
      5
    )
    ON CONFLICT (user_id) DO NOTHING; -- No duplicar si ya existe
  END IF;
  
  -- Si cambió de facilitator a user, desactivar facilitador
  IF OLD.role = 'facilitator' AND NEW.role != 'facilitator' THEN
    UPDATE facilitators 
    SET is_active = false 
    WHERE user_id = NEW.id;
  END IF;
  
  -- Si cambió de user a facilitator, reactivar facilitador
  IF OLD.role != 'facilitator' AND NEW.role = 'facilitator' THEN
    UPDATE facilitators 
    SET is_active = true 
    WHERE user_id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Crear trigger para INSERT y UPDATE
DROP TRIGGER IF EXISTS on_user_role_change ON users;
CREATE TRIGGER on_user_role_change
  AFTER INSERT OR UPDATE OF role ON users
  FOR EACH ROW EXECUTE FUNCTION create_facilitator_from_user();

-- 7. Crear facilitadores para usuarios existentes que ya tienen role 'facilitator'
INSERT INTO facilitators (user_id, bio, specialties, years_experience)
SELECT 
  id,
  'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.',
  ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE'],
  5
FROM users 
WHERE role = 'facilitator'
ON CONFLICT (user_id) DO NOTHING;

-- 8. Actualizar función get_upcoming_events para usar la nueva estructura
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
  WHERE e.status = 'active' 
    AND e.event_date > NOW()
    AND f.is_active = true
    AND u.role = 'facilitator'
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- 9. Recrear eventos con los nuevos facilitadores
DELETE FROM events; -- Limpiar eventos existentes

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
) 
SELECT 
  'Sanación Energética Grupal - ' || u.full_name,
  'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE. Facilitada por ' || u.full_name || ', experto certificado en sanación energética.',
  f.id,
  NOW() + INTERVAL '3 days',
  90,
  'Online',
  true,
  20,
  5,
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
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
LIMIT 1;

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
) 
SELECT 
  'Workshop: Expansión de Consciencia - ' || u.full_name,
  'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción usando técnicas del Método ONE. Facilitado por ' || u.full_name || '.',
  f.id,
  NOW() + INTERVAL '5 days',
  120,
  'Madrid, España',
  false,
  15,
  8,
  400,
  'active',
  '/placeholder.svg?height=200&width=300&text=Expansión+Consciencia',
  ARRAY[
    'Workshop de 2 horas',
    'Manual del participante',
    'Meditaciones guiadas',
    'Técnicas de expansión',
    'Certificado de asistencia'
  ]
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
LIMIT 1
OFFSET 1;

-- 10. Verificar el resultado final
SELECT 
  '=== USUARIOS CON ROLES ===' as section;

SELECT 
  u.id,
  u.email,
  u.full_name,
  u.role,
  CASE WHEN f.id IS NOT NULL THEN '✅ Facilitador creado' ELSE '❌ Sin facilitador' END as facilitator_status
FROM users u
LEFT JOIN facilitators f ON u.id = f.user_id
ORDER BY u.role DESC, u.created_at;

SELECT 
  '=== FACILITADORES ACTIVOS ===' as section;

SELECT 
  f.id,
  u.full_name as name,
  u.email,
  f.bio,
  f.specialties,
  f.is_active
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true;

SELECT 
  '=== EVENTOS CON FACILITADORES REALES ===' as section;

SELECT 
  e.title,
  u.full_name as facilitator,
  e.event_date,
  e.status
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
ORDER BY e.event_date;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '🎉 ¡SISTEMA DE ROLES IMPLEMENTADO EXITOSAMENTE!';
    RAISE NOTICE '👥 Usuarios con role "facilitator" automáticamente crean registro en facilitators';
    RAISE NOTICE '🔄 Triggers configurados para cambios de rol automáticos';
    RAISE NOTICE '📅 Eventos recreados con facilitadores reales';
    RAISE NOTICE '✅ ¡Todo listo para usar!';
END $$;
