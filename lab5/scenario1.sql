/*DO $$
DECLARE
    new_word_id INTEGER;
    new_pair_id INTEGER;
    new_progress_id INTEGER; 
BEGIN
    -- ВСТАВКА СЛОВА (если отсутствует)
    INSERT INTO words (key, value, topic)
    VALUES ('horse', 'лошадь', 'animals')
    ON CONFLICT (key, value) DO NOTHING
    RETURNING id INTO new_word_id;

    IF new_word_id IS NULL THEN
        SELECT id INTO new_word_id
        FROM words
        WHERE key = 'horse' AND value = 'лошадь';
    END IF;

    RAISE NOTICE 'Слово (word_id): %', new_word_id;

    INSERT INTO pairs (dict_id, word_id)
    VALUES (1, new_word_id)
    ON CONFLICT (dict_id, word_id) DO NOTHING
    RETURNING id INTO new_pair_id;

    IF new_pair_id IS NULL THEN
        RAISE NOTICE 'Пара уже существует, получение существующего pair_id...';
        SELECT id INTO new_pair_id
        FROM pairs
        WHERE dict_id = 1 AND word_id = new_word_id;
    END IF;

    RAISE NOTICE 'Пара (pair_id): %', new_pair_id;

    INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
    VALUES (new_pair_id, 0, 0, 0, NOW(), NOW() + INTERVAL '1 day')
    ON CONFLICT (pair_id) DO NOTHING;

    RAISE NOTICE 'Прогресс для pair_id % добавлен (если не существовал)', new_pair_id;

    COMMIT;
    RAISE NOTICE 'Транзакция успешно зафиксирована.';
END;
$$;*/




/*BEGIN;

INSERT INTO words (key, value, topic) VALUES ('horse', 'лошадь', 'animals')
ON CONFLICT DO NOTHING;

INSERT INTO pairs (dict_id, word_id) 
VALUES (1, (SELECT id FROM words WHERE key = 'horse' AND value = 'лошадь'));

INSERT INTO pairs (dict_id, word_id) 
VALUES (1, (SELECT id FROM words WHERE key = 'horse' AND value = 'лошадь'));

COMMIT;*/

BEGIN;

INSERT INTO words (key, value, topic) VALUES ('horse', 'лошадь', 'animals') ON CONFLICT DO NOTHING;
INSERT INTO pairs (dict_id, word_id) VALUES (1, (SELECT id FROM words WHERE key = 'horse' AND value = 'лошадь'));
INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
SELECT id, 0, 0, 0, NOW(), NOW() + INTERVAL '1 day'
FROM pairs WHERE dict_id = 1 AND word_id = (SELECT id FROM words WHERE key = 'horse' AND value = 'лошадь');

SAVEPOINT before_second_word;

INSERT INTO words (key, value, topic) VALUES ('mouse', 'мышь', 'animals') ON CONFLICT DO NOTHING;
INSERT INTO pairs (dict_id, word_id) VALUES (1, (SELECT id FROM words WHERE key = 'mouse' AND value = 'мышь'));
INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
SELECT id, 0, 0, 0, NOW(), NOW() + INTERVAL '1 day'
FROM pairs WHERE dict_id = 1 AND word_id = (SELECT id FROM words WHERE key = 'mouse' AND value = 'мышь');

ROLLBACK TO SAVEPOINT before_second_word;

COMMIT;