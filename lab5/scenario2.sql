BEGIN;

-- Вставка пары, игнорируя дубликаты
INSERT INTO pairs (dict_id, word_id)
VALUES (5, (SELECT id FROM words WHERE key='apple' AND value='яблоко'))
ON CONFLICT (dict_id, word_id) DO NOTHING
RETURNING id INTO pair_id_var;

-- Вставка прогресса только если пара действительно добавлена (pair_id не NULL)
IF pair_id_var IS NOT NULL THEN
    INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
    VALUES (pair_id_var, 0, 0, 0, NULL, NULL);
END IF;

COMMIT;

/*BEGIN;

INSERT INTO pairs (dict_id, word_id) VALUES (999, 10);  -- внешний ключ нарушен
INSERT INTO progress ...; -- не выполнится

ROLLBACK;*/


/*BEGIN;

INSERT INTO pairs (dict_id, word_id)
VALUES (5, (SELECT id FROM words WHERE key='apple' AND value='яблоко'))
ON CONFLICT (dict_id, word_id) DO NOTHING
RETURNING id INTO pair_id_var; -- pair_id = 201

SAVEPOINT sp_progress;

-- Ошибочная вставка: pair_id несуществующий (например, 9999)
INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
VALUES (9999, 0, 0, 0, NULL, NULL); -- ошибка foreign key

ROLLBACK TO SAVEPOINT sp_progress;

-- Корректная вставка
INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
VALUES (pair_id_var, 0, 0, 0, NULL, NULL);

COMMIT;*/