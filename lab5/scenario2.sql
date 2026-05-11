/*DO $$
DECLARE
    pair_id_var INTEGER;
BEGIN
    RAISE NOTICE 'Начало транзакции: вставка пары и прогресса';

    INSERT INTO pairs (dict_id, word_id)
    VALUES (5, (SELECT id FROM words WHERE key='apple' AND value='яблоко'))
    ON CONFLICT (dict_id, word_id) DO NOTHING
    RETURNING id INTO pair_id_var;

    IF pair_id_var IS NOT NULL THEN
        RAISE NOTICE 'Пара вставлена, pair_id = %', pair_id_var;
        INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
        VALUES (pair_id_var, 0, 0, 0, NULL, NULL);
        RAISE NOTICE 'Прогресс для пары % успешно добавлен', pair_id_var;
    ELSE
        RAISE NOTICE 'Пара уже существовала, вставка прогресса пропущена';
    END IF;

    COMMIT;
    RAISE NOTICE 'Транзакция зафиксирована';
END $$;*/


/*DO $$
BEGIN
    RAISE NOTICE 'Транзакция: попытка вставить пару с несуществующим dict_id=999';
    
    INSERT INTO pairs (dict_id, word_id) VALUES (999, 10);
    
    -- Сюда выполнение не дойдёт, т.к. произойдёт ошибка FOREIGN KEY
    INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
    VALUES (9999, 0, 0, 0, NULL, NULL);
    
    COMMIT;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Ошибка внешнего ключа! Транзакция будет откатана.';
        ROLLBACK;
        RAISE NOTICE 'Транзакция откачена.';
END $$;*/

CREATE OR REPLACE PROCEDURE add_pair_with_progress(
    p_dict_id INTEGER,
    p_word_key TEXT,
    p_word_value TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    pair_id_var INTEGER;
BEGIN
    RAISE NOTICE 'Начало процедуры: dict_id=%, word=(%,%)', p_dict_id, p_word_key, p_word_value;

    INSERT INTO pairs (dict_id, word_id)
    VALUES (p_dict_id, (SELECT id FROM words WHERE key = p_word_key AND value = p_word_value))
    ON CONFLICT (dict_id, word_id) DO NOTHING
    RETURNING id INTO pair_id_var;

    IF pair_id_var IS NOT NULL THEN
        RAISE NOTICE 'Пара вставлена, pair_id = %', pair_id_var;
        INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
        VALUES (pair_id_var, 0, 0, 0, NULL, NULL);
        RAISE NOTICE 'Прогресс добавлен';
    ELSE
        RAISE NOTICE 'Пара уже существует, прогресс не добавлен';
    END IF;

    COMMIT;
    RAISE NOTICE 'Транзакция зафиксирована';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка: %', SQLERRM;
        ROLLBACK;
        RAISE NOTICE 'Транзакция откачена';
END;
$$;

CALL add_pair_with_progress(5, 'apple', 'яблоко');