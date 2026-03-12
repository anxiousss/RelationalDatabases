INSERT INTO users (name, email)
VALUES ('Иван Петров', 'ivan@example.com');


INSERT INTO dicts (user_id, title)
VALUES (1, 'Мой словарь')
RETURNING id;


UPDATE users
SET email = 'new_email@example.com'
WHERE id = 1;


DELETE FROM dicts
WHERE id = 100;

