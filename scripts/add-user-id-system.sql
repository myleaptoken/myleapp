-- Agregar campo user_id único a la tabla users
ALTER TABLE users ADD COLUMN IF NOT EXISTS user_id TEXT UNIQUE;

-- Crear índice para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email_search ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_full_name_search ON users(full_name);

-- Función para generar user_id único
CREATE OR REPLACE FUNCTION generate_user_id()
RETURNS TEXT AS $$
DECLARE
    new_id TEXT;
    id_exists BOOLEAN;
BEGIN
    LOOP
        -- Generar ID en formato USR + 5 dígitos
        new_id := 'USR' || LPAD(FLOOR(RANDOM() * 99999 + 1)::TEXT, 5, '0');
        
        -- Verificar si ya existe
        SELECT EXISTS(SELECT 1 FROM users WHERE user_id = new_id) INTO id_exists;
        
        -- Si no existe, salir del loop
        IF NOT id_exists THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Generar user_id para usuarios existentes que no lo tengan
UPDATE users 
SET user_id = generate_user_id()
WHERE user_id IS NULL;

-- Trigger para auto-generar user_id en nuevos usuarios
CREATE OR REPLACE FUNCTION auto_generate_user_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id := generate_user_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_generate_user_id ON users;
CREATE TRIGGER trigger_auto_generate_user_id
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_user_id();

-- Función para buscar usuarios
CREATE OR REPLACE FUNCTION search_users(search_term TEXT)
RETURNS TABLE (
    id UUID,
    email TEXT,
    full_name TEXT,
    user_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email,
        u.full_name,
        u.user_id
    FROM users u
    WHERE 
        u.id != auth.uid() AND -- Excluir al usuario actual
        (
            u.email ILIKE '%' || search_term || '%' OR
            u.full_name ILIKE '%' || search_term || '%' OR
            u.user_id ILIKE '%' || search_term || '%'
        )
    ORDER BY 
        CASE 
            WHEN u.email = search_term THEN 1
            WHEN u.user_id = search_term THEN 2
            WHEN u.email ILIKE search_term || '%' THEN 3
            WHEN u.user_id ILIKE search_term || '%' THEN 4
            ELSE 5
        END,
        u.full_name
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dar permisos para que los usuarios puedan buscar otros usuarios
DROP POLICY IF EXISTS "Users can search other users" ON users;
CREATE POLICY "Users can search other users"
ON users FOR SELECT
TO authenticated
USING (true);

-- Asegurar que la función sea accesible
GRANT EXECUTE ON FUNCTION search_users(TEXT) TO authenticated;
