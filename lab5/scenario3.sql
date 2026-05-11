/*CREATE OR REPLACE PROCEDURE move_pair_safe(
    p_pair_id INTEGER,
    p_new_dict_id INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_word_id INTEGER;
    v_conflict BOOLEAN;
BEGIN
    RAISE NOTICE '=== Начало процедуры: перенос пары id=% в словарь id=% ===', p_pair_id, p_new_dict_id;

    SELECT word_id INTO v_word_id FROM pairs WHERE id = p_pair_id;
    IF NOT FOUND THEN
        RAISE NOTICE 'Ошибка: пара с id=% не найдена', p_pair_id;
        ROLLBACK;
        RETURN;
    END IF;
    RAISE NOTICE 'word_id пары = %', v_word_id;

    SELECT EXISTS(
        SELECT 1 FROM pairs WHERE dict_id = p_new_dict_id AND word_id = v_word_id
    ) INTO v_conflict;
    
    IF v_conflict THEN
        RAISE NOTICE 'Конфликт: пара (dict_id=%, word_id=%) уже существует. Перенос отменён.', p_new_dict_id, v_word_id;
        -- Можно просто завершить без изменений
        RETURN;
    END IF;

    UPDATE pairs 
    SET dict_id = p_new_dict_id 
    WHERE id = p_pair_id;
    RAISE NOTICE 'Поле dict_id пары % обновлено на %', p_pair_id, p_new_dict_id;

    UPDATE progress 
    SET next_repetition = NULL, knowledge_level = 0, repetitions = 0, correct_in_a_row = 0
    WHERE pair_id = p_pair_id;
    RAISE NOTICE 'Прогресс для пары % сброшен', p_pair_id;

    COMMIT;
    RAISE NOTICE '=== Транзакция успешно зафиксирована ===';
END;
$$;

CALL move_pair_safe(2, 7);*/


/*CREATE OR REPLACE PROCEDURE move_pair_wrong(p_pair_id INTEGER, p_new_dict_id INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE '=== Попытка перенести пару % в словарь % ===', p_pair_id, p_new_dict_id;
    
    UPDATE pairs SET dict_id = p_new_dict_id WHERE id = p_pair_id;
    RAISE NOTICE 'Поле dict_id обновлено (возможно, несуществующий dict_id=%)', p_new_dict_id;
   
    UPDATE progress 
    SET next_repetition = NULL, knowledge_level = 0, repetitions = 0, correct_in_a_row = 0
    WHERE pair_id = p_pair_id;
    
    COMMIT;
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Ошибка внешнего ключа! Транзакция будет откатана.';
        ROLLBACK;
        RAISE NOTICE 'Транзакция откачена. Изменения не применены.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Неожиданная ошибка: %', SQLERRM;
        ROLLBACK;
END;
$$;

CALL move_pair_wrong(150, 99);*/


BEGIN;

SAVEPOINT sp_progress;

UPDATE progress SET repetitions = -5 WHERE pair_id = 150;

ROLLBACK TO SAVEPOINT sp_progress;

UPDATE progress 
SET next_repetition = NULL, knowledge_level = 0, repetitions = 0, correct_in_a_row = 0
WHERE pair_id = 150;

COMMIT;