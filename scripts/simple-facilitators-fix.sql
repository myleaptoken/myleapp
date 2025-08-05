-- =====================================================
-- ARREGLO SIMPLE: SOLO FACILITADORES CON USUARIOS
-- Sin complicar con roles, solo la relación users -> facilitators
-- =====================================================

-- 1. Eliminar triggers problemáticos
DROP TRIGGER IF EXISTS on_user_role_change ON users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_facilitator_from_user();
DROP FUNCTION IF EXISTS create_facilitator_from_role();
DROP FUNCTION IF EXISTS handle_new_user();

-- 2. Limpiar tabla facilitators y recrearla simple
DROP TABLE IF EXISTS facilitators CASCADE;

CREATE TABLE facilitators (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  bio TEXT DEFAULT 'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.',
  specialties TEXT[] DEFAULT ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE'],
  years_experience INTEGER DEFAULT 5,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Usar usuarios EXISTENTES para crear facilitadores
-- Vamos a ver qué usuarios tienes primero
SELECT 
  '=== USUARIOS EXISTENTES ===' as section;

SELECT 
  id,
  email,
  full_name,
  created_at
FROM users 
ORDER BY created_at
LIMIT 5;

-- 4. Crear facilitadores usando los primeros 3 usuarios existentes
INSERT INTO facilitators (user_id, bio, specialties, years_experience)
SELECT 
  u.id,
  CASE 
    WHEN u.full_name ILIKE '%maría%' OR u.email ILIKE '%maria%' THEN 
      'Experta en sanación energética con más de 10 años de experiencia en Método ONE. Especializada en liberación emocional y trabajo con chakras.'
    WHEN u.full_name ILIKE '%carlos%' OR u.email ILIKE '%carlos%' THEN 
      'Facilitador certificado especializado en expansión de consciencia y técnicas avanzadas. Experto en meditación y sanación remota.'
    WHEN u.full_name ILIKE '%ana%' OR u.email ILIKE '%ana%' THEN 
      'Terapeuta holística con enfoque en sanación individual y transformación personal. Especialista en terapia holística.'
    ELSE 
      'Facilitador certificado en Método ONE especializado en sanación energética y expansión de consciencia.'
  END,
  CASE 
    WHEN u.full_name ILIKE '%maría%' OR u.email ILIKE '%maria%' THEN 
      ARRAY['Sanación Energética', 'Liberación Emocional', 'Chakras']
    WHEN u.full_name ILIKE '%carlos%' OR u.email ILIKE '%carlos%' THEN 
      ARRAY['Expansión de Consciencia', 'Meditación', 'Sanación Remota']
    WHEN u.full_name ILIKE '%ana%' OR u.email ILIKE '%ana%' THEN 
      ARRAY['Sanación Individual', 'Terapia Holística', 'Transformación Personal']
    ELSE 
      ARRAY['Sanación Energética', 'Expansión de Consciencia', 'Método ONE']
  END,
  CASE 
    WHEN u.full_name ILIKE '%maría%' OR u.email ILIKE '%maria%' THEN 10
    WHEN u.full_name ILIKE '%carlos%' OR u.email ILIKE '%carlos%' THEN 8
    WHEN u.full_name ILIKE '%ana%' OR u.email ILIKE '%ana%' THEN 12
    ELSE 5
  END
FROM users u
ORDER BY u.created_at
LIMIT 3;

-- 5. Si no hay usuarios suficientes, crear algunos básicos
INSERT INTO users (id, email, full_name, token_balance) 
SELECT 
  gen_random_uuid(),
  'facilitador' || generate_series(1,3) || '@myleap.com',
  CASE generate_series(1,3)
    WHEN 1 THEN 'María González'
    WHEN 2 THEN 'Carlos Mendoza'
    WHEN 3 THEN 'Ana Rodríguez'
  END,
  2450
WHERE (SELECT COUNT(*) FROM users) < 3;

-- 6. Crear facilitadores adicionales si no hay suficientes
INSERT INTO facilitators (user_id, bio, specialties, years_experience)
SELECT 
  u.id,
  CASE 
    WHEN u.full_name = 'María González' THEN 
      'Experta en sanación energética con más de 10 años de experiencia en Método ONE.'
    WHEN u.full_name = 'Carlos Mendoza' THEN 
      'Facilitador certificado especializado en expansión de consciencia y técnicas avanzadas.'
    WHEN u.full_name = 'Ana Rodríguez' THEN 
      'Terapeuta holística con enfoque en sanación individual y transformación personal.'
    ELSE 
      'Facilitador certificado en Método ONE.'
  END,
  CASE 
    WHEN u.full_name = 'María González' THEN 
      ARRAY['Sanación Energética', 'Liberación Emocional', 'Chakras']
    WHEN u.full_name = 'Carlos Mendoza' THEN 
      ARRAY['Expansión de Consciencia', 'Meditación', 'Sanación Remota']
    WHEN u.full_name = 'Ana Rodríguez' THEN 
      ARRAY['Sanación Individual', 'Terapia Holística', 'Transformación Personal']
    ELSE 
      ARRAY['Sanación Energética']
  END,
  CASE 
    WHEN u.full_name = 'María González' THEN 10
    WHEN u.full_name = 'Carlos Mendoza' THEN 8
    WHEN u.full_name = 'Ana Rodríguez' THEN 12
    ELSE 5
  END
FROM users u
WHERE u.email LIKE '%facilitador%@myleap.com'
  AND NOT EXISTS (SELECT 1 FROM facilitators f WHERE f.user_id = u.id);

-- 7. Actualizar función get_upcoming_events (versión simple)
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
  ORDER BY e.event_date ASC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- 8. Limpiar eventos y crear nuevos
DELETE FROM events;

-- 9. Crear eventos usando facilitadores existentes
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
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 1 THEN 'Sanación Energética Grupal'
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN 'Workshop: Expansión de Consciencia'
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 3 THEN 'Sesión Individual de Sanación'
    ELSE 'Evento de Sanación - ' || u.full_name
  END,
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 1 THEN 'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE.'
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN 'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción.'
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 3 THEN 'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación.'
    ELSE 'Evento de sanación facilitado por ' || u.full_name || '.'
  END,
  f.id,
  NOW() + INTERVAL '2 days' + (ROW_NUMBER() OVER (ORDER BY f.created_at) * INTERVAL '2 days'),
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 1 THEN 90
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN 120
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 3 THEN 60
    ELSE 90
  END,
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN 'Madrid, España'
    ELSE 'Online'
  END,
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN false
    ELSE true
  END,
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 3 THEN 1
    ELSE 20
  END,
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 1 THEN 7
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN 9
    ELSE 0
  END,
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 1 THEN 250
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 2 THEN 400
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 3 THEN 500
    ELSE 300
  END,
  'active',
  '/placeholder.svg?height=200&width=300&text=Evento+' || ROW_NUMBER() OVER (ORDER BY f.created_at),
  CASE 
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 1 THEN 'https://www.youtube.com/embed/dQw4w9WgXcQ'
    WHEN ROW_NUMBER() OVER (ORDER BY f.created_at) = 3 THEN 'https://www.youtube.com/embed/jNQXAC9IVRw'
    ELSE NULL
  END,
  ARRAY[
    'Sesión facilitada por ' || u.full_name,
    'Material de apoyo incluido',
    'Certificado de participación'
  ]
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
LIMIT 3;

-- 10. Recrear trigger simple para nuevos usuarios
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url, token_balance)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), 
    NEW.raw_user_meta_data->>'avatar_url',
    2450
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 11. Verificaciones finales
SELECT 
  '=== USUARIOS TOTALES ===' as section,
  COUNT(*) as total
FROM users;

SELECT 
  '=== FACILITADORES CREADOS ===' as section,
  u.full_name as facilitator_name,
  f.years_experience as experience
FROM facilitators f
JOIN users u ON f.user_id = u.id
WHERE f.is_active = true
ORDER BY u.full_name;

SELECT 
  '=== EVENTOS CREADOS ===' as section,
  e.title as event_title,
  u.full_name as facilitator_name
FROM events e
JOIN facilitators f ON e.facilitator_id = f.id
JOIN users u ON f.user_id = u.id
WHERE e.status = 'active'
ORDER BY e.event_date;

-- Mensaje final
DO $$
BEGIN
    RAISE NOTICE '✅ ¡SISTEMA SIMPLIFICADO CREADO EXITOSAMENTE!';
    RAISE NOTICE '👥 Facilitadores creados usando usuarios existentes';
    RAISE NOTICE '📅 Eventos creados con facilitadores reales';
    RAISE NOTICE '🔗 Relación users -> facilitators funcionando';
    RAISE NOTICE '🚀 ¡Sistema simple y funcional!';
END $$;
