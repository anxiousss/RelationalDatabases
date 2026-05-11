BEGIN ISOLATION LEVEL SERIALIZABLE;
INSERT INTO dicts (user_id, title, description) 
VALUES (1, 'Города', 'Города мира')
ON CONFLICT (user_id, title) DO NOTHING;
-- Здесь не COMMIT, ждём