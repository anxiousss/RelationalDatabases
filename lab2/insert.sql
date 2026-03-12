TRUNCATE users, dicts, words, pairs, progress RESTART IDENTITY CASCADE;

INSERT INTO users (name, email)
SELECT 'User_' || i, 'user_' || i || '@example.com'
FROM generate_series(1, 1000) AS i;

WITH user_cnt AS (SELECT count(*) AS cnt FROM users)
INSERT INTO dicts (user_id, title, description)
SELECT
    1 + (i % (SELECT cnt FROM user_cnt)),
    'Dict_' || i,
    random_string(15)
FROM generate_series(1, 1000) AS i;

INSERT INTO words (key, value)
SELECT 'key_' || i, 'value_' || i
FROM generate_series(1, 5000) AS i;

INSERT INTO pairs (dict_id, word_id)
SELECT d.id, w.id
FROM dicts d
CROSS JOIN LATERAL (
    SELECT id FROM words ORDER BY random() LIMIT floor(random() * 21 + 5)::int
) w;

INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
SELECT
    id,
    floor(random() * 5 + 1)::int,
    floor(random() * 10)::int,
    floor(random() * 5)::int,
    now() - (random() * interval '30 days'),
    now() + (random() * interval '30 days')
FROM pairs;