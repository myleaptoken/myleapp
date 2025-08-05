-- Insert sample facilitators
INSERT INTO facilitators (name, email, bio, avatar_url, rating, specialties, years_experience) VALUES
('María González', 'maria@myleap.com', 'Experta en sanación energética con más de 10 años de experiencia en Método ONE.', '/placeholder.svg?height=60&width=60', 4.9, ARRAY['Sanación Energética', 'Liberación Emocional', 'Chakras'], 10),
('Carlos Mendoza', 'carlos@myleap.com', 'Facilitador certificado especializado en expansión de consciencia y técnicas avanzadas.', '/placeholder.svg?height=60&width=60', 4.8, ARRAY['Expansión de Consciencia', 'Meditación', 'Sanación Remota'], 8),
('Ana Rodríguez', 'ana@myleap.com', 'Terapeuta holística con enfoque en sanación individual y transformación personal.', '/placeholder.svg?height=60&width=60', 4.9, ARRAY['Sanación Individual', 'Terapia Holística', 'Transformación Personal'], 12);

-- Insert sample events
INSERT INTO events (title, description, facilitator_id, event_date, location, is_online, max_attendees, token_cost, what_includes) VALUES
('Sanación Energética Grupal', 'Una sesión profunda de sanación energética donde trabajaremos con técnicas avanzadas del Método ONE. Exploraremos bloqueos energéticos, liberaremos patrones limitantes y activaremos tu potencial de sanación natural.', 
 (SELECT id FROM facilitators WHERE name = 'María González'), 
 '2024-02-15 19:00:00+00', 'Online', true, 20, 250,
 ARRAY['Sesión de sanación energética de 90 minutos', 'Material de apoyo descargable', 'Grabación de la sesión (disponible 48h)', 'Seguimiento personalizado post-sesión', 'Certificado de participación']),

('Workshop: Expansión de Consciencia', 'Workshop intensivo para expandir tu consciencia y conectar con niveles superiores de percepción usando técnicas del Método ONE.',
 (SELECT id FROM facilitators WHERE name = 'Carlos Mendoza'),
 '2024-02-18 15:00:00+00', 'Madrid, España', false, 15, 400,
 ARRAY['Workshop de 3 horas', 'Manual del participante', 'Meditaciones guiadas', 'Técnicas de expansión', 'Certificado de asistencia']),

('Sesión Individual de Sanación', 'Sesión personalizada uno a uno para trabajar aspectos específicos de tu proceso de sanación.',
 (SELECT id FROM facilitators WHERE name = 'Ana Rodríguez'),
 '2024-02-20 17:30:00+00', 'Online', true, 1, 500,
 ARRAY['Sesión individual de 60 minutos', 'Diagnóstico energético personalizado', 'Plan de sanación específico', 'Seguimiento por 2 semanas', 'Grabación de la sesión']);

-- Insert sample courses
INSERT INTO courses (title, description, instructor_id, duration_weeks, level, token_cost, max_students, what_you_learn) VALUES
('Método ONE Nivel I', 'Inicia tu viaje de transformación con los fundamentos del Método ONE. Aprenderás técnicas básicas de sanación energética, meditación consciente y liberación de bloqueos emocionales.',
 (SELECT id FROM facilitators WHERE name = 'María González'),
 8, 'Principiante', 800, 50,
 ARRAY['Fundamentos de la anatomía energética', 'Técnicas de respiración para sanación', 'Identificación y liberación de bloqueos', 'Meditaciones guiadas especializadas', 'Protocolos de autosanación', 'Ética en la práctica energética']),

('Método ONE Nivel II', 'Profundiza en técnicas avanzadas del Método ONE. Explora sanación a distancia, trabajo con patrones kármicos y activación de dones espirituales.',
 (SELECT id FROM facilitators WHERE name = 'Carlos Mendoza'),
 12, 'Intermedio', 1200, 30,
 ARRAY['Técnicas avanzadas de sanación remota', 'Trabajo profundo con el karma personal', 'Activación y desarrollo de capacidades psíquicas', 'Sanación transgeneracional', 'Canalización de energías superiores', 'Formación como facilitador certificado']);

-- Insert course modules for Método ONE Nivel I
INSERT INTO course_modules (course_id, title, description, duration_weeks, order_index) VALUES
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Fundamentos de la Sanación Energética', 'Introducción a los conceptos básicos de la energía y su aplicación en sanación.', 2, 1),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Técnicas de Respiración Consciente', 'Aprende técnicas de respiración para canalizar y dirigir la energía sanadora.', 2, 2),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Liberación de Bloqueos Emocionales', 'Identifica y libera patrones emocionales que limitan tu bienestar.', 2, 3),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel I'), 'Práctica Integrativa y Certificación', 'Integra todo lo aprendido y obtén tu certificación de Nivel I.', 2, 4);

-- Insert course modules for Método ONE Nivel II
INSERT INTO course_modules (course_id, title, description, duration_weeks, order_index) VALUES
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Sanación a Distancia', 'Técnicas avanzadas para realizar sanación sin limitaciones físicas.', 3, 1),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Trabajo con Patrones Kármicos', 'Identifica y transforma patrones kármicos heredados y personales.', 3, 2),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Activación de Dones Espirituales', 'Despierta y desarrolla tus capacidades psíquicas naturales.', 3, 3),
((SELECT id FROM courses WHERE title = 'Método ONE Nivel II'), 'Maestría y Certificación Avanzada', 'Conviértete en facilitador certificado del Método ONE.', 3, 4);

-- Insert sample testimonials
INSERT INTO testimonials (name, role, company, content, rating, avatar_url, is_featured, is_approved) VALUES
('María González', 'Senior Developer', 'TechCorp', 'MY LEAP transformó completamente mi carrera. Los eventos de networking me conectaron con oportunidades increíbles y los cursos me dieron las habilidades que necesitaba para ascender.', 5, '/placeholder.svg?height=60&width=60', true, true),
('Carlos Rodríguez', 'Product Manager', 'InnovateLab', 'El sistema de tokens es genial. Participar en eventos me ha dado acceso a cursos premium que han sido fundamentales para mi desarrollo profesional. ¡Altamente recomendado!', 5, '/placeholder.svg?height=60&width=60', true, true),
('Ana Martínez', 'UX Designer', 'DesignStudio', 'La comunidad es increíble. He encontrado mentores, colaboradores y amigos. Los workshops han elevado mi nivel de diseño a otro nivel completamente.', 5, '/placeholder.svg?height=60&width=60', true, true);

-- Insert sample video testimonials
INSERT INTO video_testimonials (name, title, description, duration, thumbnail_url, is_featured, is_approved) VALUES
('María González', 'Sanación de Dolor Crónico', 'Logré 3 años de dolor de espalda con 3 sesiones con facilitadores LEAP', '3:45', '/placeholder.svg?height=200&width=300', true, true),
('Carlos Mendoza', 'Expansión de Consciencia', 'El Método ONE me ayudó a conectar con mi propósito de vida', '4:20', '/placeholder.svg?height=200&width=300', true, true),
('Ana Rodríguez', 'Sanación Emocional', 'Superé traumas familiares usando tokens LEAP para acceder a cursos NFT', '2:30', '/placeholder.svg?height=200&width=300', true, true);
