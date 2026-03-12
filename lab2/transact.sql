SELECT u.id, u.name, COUNT(d.id) AS dict_count
FROM users u
LEFT JOIN dicts d ON u.id = d.user_id
GROUP BY u.id, u.name
ORDER BY dict_count DESC;

SELECT d.id, d.title, COUNT(p.word_id) AS words_count
FROM dicts d
LEFT JOIN pairs p ON d.id = p.dict_id
GROUP BY d.id, d.title
ORDER BY words_count DESC;

SELECT d.id, d.title, AVG(pr.knowledge_level) AS avg_knowledge
FROM dicts d
JOIN pairs p ON d.id = p.dict_id
JOIN progress pr ON p.id = pr.pair_id
GROUP BY d.id, d.title
ORDER BY avg_knowledge DESC;

SELECT u.id, u.name, SUM(pr.repetitions) AS total_repetitions
FROM users u
JOIN dicts d ON u.id = d.user_id
JOIN pairs p ON d.id = p.dict_id
JOIN progress pr ON p.id = pr.pair_id
GROUP BY u.id, u.name
ORDER BY total_repetitions DESC;