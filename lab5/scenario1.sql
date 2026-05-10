BEGIN;

-- Вставка словаря. Если уже существует (user_id, title) – ничего не делаем.
INSERT INTO dicts (user_id, title, description) 
VALUES (1, 'Фрукты', 'Слова на тему фруктов')
ON CONFLICT (user_id, title) DO NOTHING
RETURNING id;

-- Если словарь не создан (уже был), то прерываем транзакцию (или выходим).
-- Для простоты предполагаем, что создался, и получаем id. 
-- На практике нужно проверить возвращённое значение. 
-- Допустим, id = 10. Далее работаем с ним.

-- Вставка слова. Если (key, value) уже существует – игнорируем.
INSERT INTO words (key, value) 
VALUES ('apple', 'яблоко')
ON CONFLICT (key, value) DO NOTHING;

-- Получаем id слова (существующего или только что вставленного)
WITH w AS (
    SELECT id FROM words WHERE key = 'apple' AND value = 'яблоко'
)
INSERT INTO pairs (dict_id, word_id)
SELECT 10, id FROM w
ON CONFLICT (dict_id, word_id) DO NOTHING   -- если пара уже есть, игнорируем
RETURNING id;  -- допустим, pair_id = 100

-- Вставка прогресса, но только если пара действительно создалась
INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
SELECT 100, 0, 0, 0, NULL, NULL
WHERE EXISTS (SELECT 1 FROM pairs WHERE id = 100);

COMMIT;