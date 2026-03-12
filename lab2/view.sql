CREATE VIEW pair_details AS
SELECT
    p.id AS pair_id,
    d.id AS dict_id,
    d.title AS dict_title,
    u.id AS user_id,
    u.name AS user_name,
    w.id AS word_id,
    w.key AS word_key,
    w.value AS word_value,
    pr.knowledge_level,
    pr.repetitions,
    pr.correct_in_a_row,
    pr.last_repetition,
    pr.next_repetition
FROM pairs p
JOIN dicts d ON p.dict_id = d.id
JOIN users u ON d.user_id = u.id
JOIN words w ON p.word_id = w.id
LEFT JOIN progress pr ON p.id = pr.pair_id;

CREATE VIEW user_activity AS
SELECT
    u.id,
    u.name,
    u.email,
    COUNT(DISTINCT d.id) AS dicts_count,
    COUNT(DISTINCT p.word_id) AS unique_words_learned,
    SUM(pr.repetitions) AS total_repetitions,
    AVG(pr.knowledge_level) AS avg_knowledge_level
FROM users u
LEFT JOIN dicts d ON u.id = d.user_id
LEFT JOIN pairs p ON d.id = p.dict_id
LEFT JOIN progress pr ON p.id = pr.pair_id
GROUP BY u.id;

CREATE VIEW dict_stats AS
SELECT
    d.id,
    d.title,
    d.description,
    d.user_id,
    COUNT(DISTINCT p.word_id) AS words_count,
    AVG(pr.knowledge_level) AS avg_knowledge,
    SUM(pr.repetitions) AS total_repetitions,
    MAX(pr.correct_in_a_row) AS max_streak
FROM dicts d
LEFT JOIN pairs p ON d.id = p.dict_id
LEFT JOIN progress pr ON p.id = pr.pair_id
GROUP BY d.id;