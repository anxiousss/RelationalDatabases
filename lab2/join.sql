SELECT d.id, d.title, u.email
FROM dicts d
JOIN users u ON d.user_id = u.id;

SELECT d.title AS dict_title, w.key, w.value
FROM pairs p
JOIN dicts d ON p.dict_id = d.id
JOIN words w ON p.word_id = w.id;

SELECT d.title AS dict_title, w.key AS word_key
FROM dicts d
FULL JOIN pairs p ON d.id = p.dict_id
FULL JOIN words w ON p.word_id = w.id
LIMIT 20;