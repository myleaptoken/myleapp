-- =====================================================
-- MY LEAP - CONFIGURACIÓN COMPLETA DE BASE DE DATOS
-- Ejecuta este script completo en Supabase SQL Editor
-- =====================================================

-- 1. HABILITAR EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. CREAR TABLAS PRINCIPALES

-- Tabla de usuarios (extiende auth.users de Supabase)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  token_balance INTEGER DEFAULT 2450,
  level INTEGER DEFAULT 1,
  experience_points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de facilitadores
CREATE TABLE IF NOT EXISTS public.facilitators (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  rating DECIMAL(3,2) DEFAULT 5.0,
  specialties TEXT[],
  years_experience INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de eventos
CREATE TABLE IF NOT EXISTS public.events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  facilitator_id UUID REFERENCES facilitators(id),
  event_date TIMESTAMP WITH TIME ZONE NOT NULL,
  duration_minutes INTEGER DEFAULT 90,
  location TEXT,
  is_online BOOLEAN DEFAULT true,
  max_attendees INTEGER DEFAULT 20,
  current_attendees INTEGER DEFAULT 0,
  token_cost INTEGER NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'completed')),
  image_url TEXT,
  what_includes TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de cursos
CREATE TABLE IF NOT EXISTS public.courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES facilitators(id),
  duration_weeks INTEGER NOT NULL,
  level TEXT CHECK (level IN ('Principiante', 'Intermedio', 'Avanzado')),
  token_cost INTEGER NOT NULL,
  max_students INTEGER DEFAULT 50,
  current_students INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 5.0,
  image_url TEXT,
  preview_video_url TEXT,
  what_you_learn TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de módulos de cursos
CREATE TABLE IF NOT EXISTS public.course_modules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  duration_weeks INTEGER DEFAULT 1,
  order_index INTEGER NOT NULL,
  video_url TEXT,
  materials TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de inscripciones a eventos
CREATE TABLE IF NOT EXISTS public.user_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'registered' CHECK (status IN ('registered', 'attended', 'cancelled', 'no_show')),
  tokens_paid INTEGER NOT NULL,
  registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  attended_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, event_id)
);

-- Tabla de inscripciones a cursos
CREATE TABLE IF NOT EXISTS public.user_courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'in_progress', 'completed', 'dropped')),
  progress_percentage INTEGER DEFAULT 0,
  tokens_paid INTEGER NOT NULL,
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, course_id)
);

-- Tabla de transacciones de tokens
CREATE TABLE IF NOT EXISTS public.token_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type TEXT CHECK (type IN ('earned', 'spent', 'bonus', 'refund')),
  description TEXT NOT NULL,
  reference_id UUID,
  reference_type TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de testimonios
CREATE TABLE IF NOT EXISTS public.testimonials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  role TEXT,
  company TEXT,
  content TEXT NOT NULL,
  rating INTEGER DEFAULT 5 CHECK (rating >= 1 AND rating <= 5),
  avatar_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de video testimonios
CREATE TABLE IF NOT EXISTS public.video_testimonials (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  name TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  duration TEXT NOT NULL,
  thumbnail_url TEXT,
  video_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  is_approved BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. HABILITAR ROW LEVEL SECURITY (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;

-- 4. CREAR POLÍTICAS DE SEGURIDAD (RLS POLICIES)

-- Políticas para usuarios
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Políticas para inscripciones de eventos
DROP POLICY IF EXISTS "Users can view own events" ON user_events;
CREATE POLICY "Users can view own events" ON user_events FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own events" ON user_events;
CREATE POLICY "Users can insert own events" ON user_events FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para inscripciones de cursos
DROP POLICY IF EXISTS "Users can view own courses" ON user_courses;
CREATE POLICY "Users can view own courses" ON user_courses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own courses" ON user_courses;
CREATE POLICY "Users can insert own courses" ON user_courses FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para transacciones
DROP POLICY IF EXISTS "Users can view own transactions" ON token_transactions;
CREATE POLICY "Users can view own transactions" ON token_transactions FOR SELECT USING (auth.uid() = user_id);

-- Políticas de lectura pública
DROP POLICY IF EXISTS "Anyone can view active events" ON events;
CREATE POLICY "Anyone can view active events" ON events FOR SELECT USING (status = 'active');

DROP POLICY IF EXISTS "Anyone can view active courses" ON courses;
CREATE POLICY "Anyone can view active courses" ON courses FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Anyone can view facilitators" ON facilitators;
CREATE POLICY "Anyone can view facilitators" ON facilitators FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Anyone can view approved testimonials" ON testimonials;
CREATE POLICY "Anyone can view approved testimonials" ON testimonials FOR SELECT USING (is_approved = true);

DROP POLICY IF EXISTS "Anyone can view approved video testimonials" ON video_testimonials;
CREATE POLICY "Anyone can view approved video testimonials" ON video_testimonials FOR SELECT USING (is_approved = true);

-- 5. CREAR FUNCIONES Y TRIGGERS

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_facilitators_updated_at ON facilitators;
CREATE TRIGGER update_facilitators_updated_at BEFORE UPDATE ON facilitators FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_events_updated_at ON events;
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_courses_updated_at ON courses;
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para manejar nuevos usuarios
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url, token_balance)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email), 
    NEW.raw_user_meta_data->>'avatar_url',
    2450 -- Balance inicial de tokens
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para nuevos usuarios
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. INSERTAR DATOS DE PRUEBA

-- Facilitadores
INSERT INTO facilitators (name, email, bio, avatar_url, rating, specialties, years_experience) VALUES
('María González', 'maria@myleap.com', 'Experta en sanación energética con más de 10 años de experiencia en Método ONE.', '/placeholder.svg?height=60&width=60', 4.9, ARRAY['Sanación Energética', 'Liberación Emocional', 'Chakras'], 10),
('Carlos Mendoza', 'carlos@myleap.com', 'Facilitador certificado especializado en expansión de consciencia y técnicas avanzadas.', '/placeholder.svg?height=60&width=60', 4.8, ARRAY['Expansión de Consciencia', 'Meditación', 'Sanación Remota'], 8),
('Ana Rodríguez', 'ana@myleap.com', 'Terapeuta holística con enfoque en sanación individual y transformación personal.', '/placeholder.svg?height=60&width=60', 4.9, ARRAY['Sanación Individual', 'Terapia Holística', 'Transformación Personal'], 12)
ON CONFLICT (email) DO NOTHING;

-- Eventos
INSERT INTO events (title, description, facilitator_id, event_date, location, is_online, max_attendees, token_cost, what_includes) VALUES
('Sanación Energética Grupal', 'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE.', 
 (SELECT id FROM facilitators WHERE name = 'María González'), 
 '2024-02-15 19:00:00+00', 'Online', true, 20, 250,
 ARRAY['Sesión de sanación energética de 90 minutos', 'Material de apoyo descargable', 'Grabación de la sesión (disponible 48h)', 'Seguimiento personalizado post-sesión', 'Certificado de participación']),

('Workshop: Expansión de Consciencia', 'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción.',
 (SELECT id FROM facilitators WHERE name = 'Carlos Mendoza'),
 '2024-02-18 15:00:00+00', 'Madrid, España', false, 15, 400,
 ARRAY['Workshop de 3 horas', 'Manual del participante', 'Meditaciones guiadas', 'Técnicas de expansión', 'Certificado de asistencia']),

('Sesión Individual de Sanación', 'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación.',
 (SELECT id FROM facilitators WHERE name = 'Ana Rodríguez'),
 '2024-02-20 17:30:00+00', 'Online', true, 1, 500,
 ARRAY['Sesión individual de 60 minutos', 'Diagnóstico energético personalizado', 'Plan de sanación específico', 'Seguimiento por 2 semanas', 'Grabación de la sesión'])
ON CONFLICT DO NOTHING;

-- Cursos
INSERT INTO courses (title, description, instructor_id, duration_weeks, level, token_cost, max_students, current_students, what_you_learn) VALUES
('Método ONE Nivel I', 'Inicia tu viaje de transformación con los fundamentos del Método ONE. Aprenderás técnicas básicas de sanación energética.',
 (SELECT id FROM facilitators WHERE name = 'María González'),
 8, 'Principiante', 800, 50, 245,
 ARRAY['Fundamentos de la anatomía energética', 'Técnicas de respiración para sanación', 'Identificación y liberación de bloqueos', 'Meditaciones guiadas especializadas', 'Protocolos de autosanación', 'Ética en la práctica energética']),

('Método ONE Nivel II', 'Profundiza en técnicas avanzadas del Método ONE. Explora sanación a distancia y trabajo con patrones kármicos.',
 (SELECT id FROM facilitators WHERE name = 'Carlos Mendoza'),
 12, 'Intermedio', 1200, 30, 156,
 ARRAY['Técnicas avanzadas de sanación remota', 'Trabajo profundo con el karma personal', 'Activación y desarrollo de capacidades psíquicas', 'Sanación transgeneracional', 'Canalización de energías superiores', 'Formación como facilitador certificado'])
ON CONFLICT DO NOTHING;

-- Módulos de cursos
INSERT INTO course_modules (course_id, title, description, duration_weeks, order_index) VALUES
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Fundamentos de la Sanación Energética', 'Introducción a los conceptos básicos de la energía y su aplicación en sanación.', 2, 1),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Técnicas de Respiración Consciente', 'Aprende técnicas de respiración para canalizar y dirigir la energía sanadora.', 2, 2),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Liberación de Bloqueos Emocionales', 'Identifica y libera patrones emocionales que limitan tu bienestar.', 2, 3),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Práctica Integrativa y Certificación', 'Integra todo lo aprendido y obtén tu certificación de Nivel I.', 2, 4),

((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Sanación a Distancia', 'Técnicas avanzadas para realizar sanación sin limitaciones físicas.', 3, 1),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Trabajo con Patrones Kármicos', 'Identifica y transforma patrones kármicos heredados y personales.', 3, 2),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Activación de Dones Espirituales', 'Despierta y desarrolla tus capacidades psíquicas naturales.', 3, 3),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Maestría y Certificación Avanzada', 'Conviértete en facilitador certificado del Método ONE.', 3, 4)
ON CONFLICT DO NOTHING;

-- Testimonios
INSERT INTO testimonials (name, role, company, content, rating, avatar_url, is_featured, is_approved) VALUES
('María González', 'Senior Developer', 'TechCorp', 'MY LEAP transformó completamente mi carrera. Los eventos de networking me conectaron con oportunidades increíbles.', 5, '/placeholder.svg?height=60&width=60', true, true),
('Carlos Rodríguez', 'Product Manager', 'InnovateLab', 'El sistema de tokens es genial. Participar en eventos me ha dado acceso a cursos premium fundamentales.', 5, '/placeholder.svg?height=60&width=60', true, true),
('Ana Martínez', 'UX Designer', 'DesignStudio', 'La comunidad es increíble. He encontrado mentores, colaboradores y amigos. Los workshops han elevado mi nivel.', 5, '/placeholder.svg?height=60&width=60', true, true),
('David López', 'Data Scientist', 'DataTech', 'Los cursos especializados en ciencia de datos son excepcionales. El contenido está siempre actualizado.', 5, '/placeholder.svg?height=60&width=60', true, true),
('Laura Sánchez', 'Marketing Director', 'GrowthCo', 'MY LEAP me ha dado las herramientas y conexiones necesarias para liderar equipos de marketing digital.', 5, '/placeholder.svg?height=60&width=60', true, true),
('Roberto Fernández', 'DevOps Engineer', 'CloudSystems', 'Las certificaciones que obtuve a través de MY LEAP me abrieron puertas que nunca pensé posibles.', 5, '/placeholder.svg?height=60&width=60', true, true)
ON CONFLICT DO NOTHING;

-- Video testimonios
INSERT INTO video_testimonials (name, title, description, duration, thumbnail_url, is_featured, is_approved) VALUES
('María González', 'Sanación de Dolor Crónico', 'Logré sanar 3 años de dolor de espalda con 3 sesiones con facilitadores LEAP', '3:45', '/placeholder.svg?height=200&width=300', true, true),
('Carlos Mendoza', 'Expansión de Consciencia', 'El Método ONE me ayudó a conectar con mi propósito de vida', '4:20', '/placeholder.svg?height=200&width=300', true, true),
('Ana Rodríguez', 'Sanación Emocional', 'Superé traumas familiares usando tokens LEAP para acceder a cursos especializados', '2:30', '/placeholder.svg?height=200&width=300', true, true),
('Roberto Silva', 'Transformación Energética', 'Mi energía vital se multiplicó después de los workshops de sanación', '5:15', '/placeholder.svg?height=200&width=300', true, true),
('Laura Martín', 'Despertar Espiritual', 'Encontré mi camino espiritual a través de las técnicas de Método ONE', '3:50', '/placeholder.svg?height=200&width=300', true, true),
('Diego Herrera', 'Sanación Física', 'Recuperé mi movilidad después de años de limitaciones físicas', '4:05', '/placeholder.svg?height=200&width=300', true, true)
ON CONFLICT DO NOTHING;

-- 7. MENSAJE DE CONFIRMACIÓN
DO $$
BEGIN
    RAISE NOTICE '🎉 ¡MY LEAP DATABASE CONFIGURADA EXITOSAMENTE!';
    RAISE NOTICE '✅ Tablas creadas: %, %, %, %, %, %, %, %, %, %', 
        'users', 'facilitators', 'events', 'courses', 'course_modules', 
        'user_events', 'user_courses', 'token_transactions', 'testimonials', 'video_testimonials';
    RAISE NOTICE '🔐 RLS habilitado y políticas configuradas';
    RAISE NOTICE '📊 Datos de prueba insertados';
    RAISE NOTICE '🚀 ¡Listo para usar!';
END $$;
