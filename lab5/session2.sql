BEGIN ISOLATION LEVEL SERIALIZABLE;
INSERT INTO dicts (user_id, title, description) 
VALUES (1, 'Города', 'Столицы')
ON CONFLICT (user_id, title) DO NOTHING;
COMMIT; -- или ROLLBACK