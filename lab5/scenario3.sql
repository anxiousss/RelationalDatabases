BEGIN;

-- Проверяем, что в целевом словаре ещё нет такой пары
UPDATE pairs 
SET dict_id = 7 
WHERE id = 150 
  AND NOT EXISTS (
    SELECT 1 FROM pairs p2 
    WHERE p2.dict_id = 7 AND p2.word_id = (SELECT word_id FROM pairs WHERE id = 150)
  );

-- Если обновление затронуло строку, то обновляем прогресс
UPDATE progress 
SET next_repetition = NULL, knowledge_level = 0, repetitions = 0, correct_in_a_row = 0
WHERE pair_id = 150 AND EXISTS (SELECT 1 FROM pairs WHERE id = 150 AND dict_id = 7);

COMMIT;

BEGIN;

UPDATE pairs SET dict_id = 99 WHERE id = 150; -- ошибка foreign key
UPDATE progress ...;

ROLLBACK;



BEGIN;

-- Переносим словарь
UPDATE pairs SET dict_id = 7 WHERE id = 150
  AND NOT EXISTS (SELECT 1 FROM pairs WHERE dict_id = 7 AND word_id = (SELECT word_id FROM pairs WHERE id = 150));

SAVEPOINT sp_progress;

-- Ошибка: отрицательное значение repetitions
UPDATE progress SET repetitions = -5 WHERE pair_id = 150;

ROLLBACK TO SAVEPOINT sp_progress;

-- Правильное обновление прогресса
UPDATE progress 
SET next_repetition = NULL, knowledge_level = 0, repetitions = 0, correct_in_a_row = 0
WHERE pair_id = 150;

COMMIT;	