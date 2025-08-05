-- 1. La función get_upcoming_events() filtra por status = 'active'
-- Solo muestra eventos activos y futuros
SELECT * FROM get_upcoming_events(); -- Solo eventos 'active'

-- 2. Las políticas RLS también filtran por status
-- "Anyone can view active events" ON events FOR SELECT USING (status = 'active');

-- 3. Ejemplo de cómo cambiar el status de un evento
UPDATE events 
SET status = 'completed' 
WHERE event_date < NOW() - INTERVAL '1 day'; -- Eventos que ya pasaron

-- 4. Ejemplo de cancelar un evento
UPDATE events 
SET status = 'cancelled' 
WHERE title = 'Nombre del evento a cancelar';

-- 5. Ver todos los eventos por status
SELECT 
  status,
  COUNT(*) as cantidad,
  STRING_AGG(title, ', ') as eventos
FROM events 
GROUP BY status;

-- 6. Función para cambiar automáticamente eventos pasados a 'completed'
CREATE OR REPLACE FUNCTION update_event_status()
RETURNS void AS $$
BEGIN
  -- Marcar como completados los eventos que ya pasaron
  UPDATE events 
  SET status = 'completed' 
  WHERE status = 'active' 
    AND event_date < NOW() - INTERVAL '2 hours'; -- 2 horas después del evento
    
  RAISE NOTICE 'Eventos actualizados a completed: %', 
    (SELECT COUNT(*) FROM events WHERE status = 'completed');
END;
$$ LANGUAGE plpgsql;

-- Ejecutar la función
SELECT update_event_status();
