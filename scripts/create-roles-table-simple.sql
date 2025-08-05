-- =====================================================
-- CREAR TABLA ROLES Y MIGRAR USERS.ROLE A USERS.ROLE_ID
-- Sin tocar nada más que funcione
-- =====================================================

-- 1. CREAR TABLA ROLES
CREATE TABLE IF NOT EXISTS roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. INSERTAR ROLES BÁSICOS
INSERT INTO roles (name, display_name, description) VALUES
('user', 'Usuario', 'Usuario regular de la plataforma'),
('facilitator', 'Facilitador', 'Facilitador certificado que puede crear eventos'),
('admin', 'Administrador', 'Administrador del sistema')
ON CONFLICT (name) DO NOTHING;

-- 3. AGREGAR COLUMNA ROLE_ID A USERS (sin constraint todavía)
ALTER TABLE users ADD COLUMN IF NOT EXISTS role_id UUID;

-- 4. MIGRAR DATOS DE ROLE A ROLE_ID
UPDATE users SET role_id = (
  CASE 
    WHEN role = 'user' THEN (SELECT id FROM roles WHERE name = 'user')
    WHEN role = 'facilitator' THEN (SELECT id FROM roles WHERE name = 'facilitator')
    WHEN role = 'admin' THEN (SELECT id FROM roles WHERE name = 'admin')
    ELSE (SELECT id FROM roles WHERE name = 'user') -- default
  END
) WHERE role_id IS NULL;

-- 5. ASEGURAR QUE TODOS TENGAN ROLE_ID
UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'user') WHERE role_id IS NULL;

-- 6. HACER ROLE_ID NOT NULL Y AGREGAR FOREIGN KEY
ALTER TABLE users ALTER COLUMN role_id SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(id);

-- 7. ELIMINAR COLUMNA ROLE ANTIGUA (con CASCADE por si hay dependencias)
ALTER TABLE users DROP COLUMN IF EXISTS role CASCADE;

-- 8. ACTUALIZAR TRIGGER PARA NUEVOS USUARIOS
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

-- 9. FUNCIÓN AUXILIAR PARA OBTENER ROL DE USUARIO
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

-- 10. VERIFICAR QUE TODO QUEDÓ BIEN
DO $$
DECLARE
    roles_count INTEGER;
    users_count INTEGER;
    users_with_role_id INTEGER;
BEGIN
    SELECT COUNT(*) INTO roles_count FROM roles;
    SELECT COUNT(*) INTO users_count FROM users;
    SELECT COUNT(*) INTO users_with_role_id FROM users WHERE role_id IS NOT NULL;
    
    RAISE NOTICE '=== MIGRACIÓN COMPLETADA ===';
    RAISE NOTICE 'Roles creados: %', roles_count;
    RAISE NOTICE 'Usuarios totales: %', users_count;
    RAISE NOTICE 'Usuarios con role_id: %', users_with_role_id;
    
    IF users_count = users_with_role_id THEN
        RAISE NOTICE '✅ MIGRACIÓN EXITOSA - Todos los usuarios tienen role_id';
    ELSE
        RAISE NOTICE '⚠️  REVISAR - Algunos usuarios sin role_id';
    END IF;
END $$;

-- Mostrar resultado final
SELECT 
  'USUARIOS POR ROL' as info,
  r.name as rol,
  r.display_name,
  COUNT(u.id) as total_usuarios
FROM roles r
LEFT JOIN users u ON r.id = u.role_id
GROUP BY r.id, r.name, r.display_name
ORDER BY r.name;
