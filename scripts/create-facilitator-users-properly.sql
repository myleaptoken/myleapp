-- Script alternativo: Crear usuarios facilitadores de la manera correcta
-- Solo ejecutar este script si quieres crear usuarios reales para los facilitadores

-- IMPORTANTE: Este script crea usuarios en auth.users primero, luego en users
-- Solo ejecutar si realmente quieres crear estos usuarios

-- 1. Insertar usuarios en auth.users primero (esto normalmente lo hace Supabase Auth)
-- NOTA: En producción, los usuarios se crean a través del sistema de autenticación
-- Este es solo para desarrollo/testing

-- 2. Crear función para conectar facilitadores existentes con usuarios cuando se registren
CREATE OR REPLACE FUNCTION connect_facilitator_to_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Si el email del nuevo usuario coincide con un facilitador, conectarlos
  UPDATE facilitators 
  SET user_id = NEW.id
  WHERE email = NEW.email 
    AND user_id IS NULL;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Crear trigger para conectar automáticamente
DROP TRIGGER IF EXISTS on_user_created_connect_facilitator ON users;
CREATE TRIGGER on_user_created_connect_facilitator
  AFTER INSERT ON users
  FOR EACH ROW EXECUTE FUNCTION connect_facilitator_to_user();

-- Mensaje
DO $$
BEGIN
    RAISE NOTICE '✅ Sistema preparado para conectar facilitadores con usuarios';
    RAISE NOTICE '🔗 Cuando un usuario se registre con email de facilitador, se conectarán automáticamente';
END $$;
