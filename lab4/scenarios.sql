SET enable_seqscan = off;
-- затем выполнить запрос

EXPLAIN ANALYZE
SELECT id, key, value, topic
FROM words
WHERE topic = 'animals'
  AND id BETWEEN 100000 AND 200000
  AND key LIKE '%dog%';


EXPLAIN ANALYZE
SELECT pair_id, knowledge_level, repetitions, last_repetition, next_repetition
FROM progress
WHERE next_repetition > now()
ORDER BY last_repetition ASC
LIMIT 1000;

EXPLAIN ANALYZE
SELECT pair_id, dict_id, knowledge_level, last_repetition
FROM pairs
JOIN progress ON pairs.id = progress.pair_id
WHERE dict_id BETWEEN 100 AND 200
  AND knowledge_level >= 3
ORDER BY last_repetition DESC
LIMIT 500;



EXPLAIN ANALYZE
SELECT id, key, value
FROM words
WHERE key LIKE '%dog%'     
   OR key LIKE 'cat%'       
   OR key LIKE '%_123';     


EXPLAIN ANALYZE
SELECT u.name, d.title AS dict_title, w.key, w.value, p.repetitions, p.knowledge_level
FROM users u
JOIN dicts d ON u.id = d.user_id
JOIN pairs pr ON d.id = pr.dict_id
JOIN words w ON pr.word_id = w.id
LEFT JOIN progress p ON pr.id = p.pair_id
WHERE u.id = 42;


EXPLAIN ANALYZE
SELECT id, key, value
FROM words
WHERE lower(key) = 'dog_1';