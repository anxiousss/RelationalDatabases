CREATE OR REPLACE FUNCTION update_progress(
    p_pair_id INTEGER,
    p_is_correct BOOLEAN
) RETURNS VOID AS $$
DECLARE
    v_current RECORD;
    v_new_level INTEGER;
    v_new_correct_in_a_row INTEGER;
    v_new_repetitions INTEGER;
BEGIN
    SELECT * INTO v_current FROM progress WHERE pair_id = p_pair_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Прогресс для пары с id % не найден', p_pair_id;
    END IF;

    IF v_current.knowledge_level NOT BETWEEN 1 AND 5 THEN
        RAISE EXCEPTION 'Некорректный уровень знаний: %', v_current.knowledge_level;
    END IF;

    IF p_is_correct THEN
        v_new_correct_in_a_row := v_current.correct_in_a_row + 1;
        IF v_new_correct_in_a_row >= 3 AND v_current.knowledge_level < 5 THEN
            v_new_level := v_current.knowledge_level + 1;
            v_new_correct_in_a_row := 0; 
        ELSE
            v_new_level := v_current.knowledge_level;
        END IF;
    ELSE
        v_new_correct_in_a_row := 0;
        v_new_level := GREATEST(1, v_current.knowledge_level - 1);
    END IF;

    v_new_repetitions := v_current.repetitions + 1;

    UPDATE progress
    SET knowledge_level   = v_new_level,
        repetitions       = v_new_repetitions,
        correct_in_a_row  = v_new_correct_in_a_row,
        last_repetition   = NOW(),
        next_repetition   = NOW() + (v_new_level * INTERVAL '1 day') 
    WHERE pair_id = p_pair_id;

    RAISE NOTICE 'Прогресс для пары % обновлён: новый уровень = %', p_pair_id, v_new_level;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION add_word_to_dict(
    p_dict_id INTEGER,
    p_key TEXT,
    p_value TEXT,
    p_topic TEXT
) RETURNS VOID AS $$
DECLARE
    v_word_id INTEGER;
    v_exists BOOLEAN;
    v_dict_topic TEXT;
BEGIN
    SELECT topic INTO v_dict_topic FROM dicts WHERE id = p_dict_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Словарь с id % не существует', p_dict_id;
    END IF;

    IF v_dict_topic IS NOT NULL AND v_dict_topic != p_topic THEN
        RAISE EXCEPTION 'Тема слова "%" не соответствует теме словаря "%"', p_topic, v_dict_topic;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pairs p
        JOIN words w ON w.id = p.word_id
        WHERE p.dict_id = p_dict_id
          AND w.key = p_key
          AND w.topic = p_topic
    ) INTO v_exists;

    IF v_exists THEN
        RAISE EXCEPTION 'Слово "%" (тема %) уже присутствует в словаре %', p_key, p_topic, p_dict_id;
    END IF;

    SELECT id INTO v_word_id
    FROM words
    WHERE key = p_key AND topic = p_topic;

    IF NOT FOUND THEN
        INSERT INTO words (key, value, topic)
        VALUES (p_key, p_value, p_topic)
        RETURNING id INTO v_word_id;
    END IF;

    -- Связываем слово со словарём
    INSERT INTO pairs (dict_id, word_id)
    VALUES (p_dict_id, v_word_id);

    RAISE NOTICE 'Слово "%" добавлено в словарь %', p_key, p_dict_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_user_stats(p_user_id INTEGER)
RETURNS TABLE(
    dicts_count BIGINT,
    total_words BIGINT,
    avg_knowledge_level NUMERIC,
    due_words_count BIGINT
) AS $$
DECLARE
    v_user_exists BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) INTO v_user_exists;
    IF NOT v_user_exists THEN
        RAISE EXCEPTION 'Пользователь с id % не найден', p_user_id;
    END IF;

    RETURN QUERY
    WITH user_dicts AS (
        SELECT id FROM dicts WHERE user_id = p_user_id
    ),
    user_pairs AS (
        SELECT p.id
        FROM pairs p
        JOIN user_dicts ud ON ud.id = p.dict_id
    ),
    user_progress AS (
        SELECT pr.*
        FROM progress pr
        JOIN user_pairs up ON up.id = pr.pair_id
    )
    SELECT
        (SELECT COUNT(*) FROM user_dicts) AS dicts_count,
        (SELECT COUNT(*) FROM user_pairs) AS total_words,
        (SELECT COALESCE(AVG(knowledge_level), 0) FROM user_progress) AS avg_knowledge_level,
        (SELECT COUNT(*) FROM user_progress WHERE next_repetition < NOW()) AS due_words_count;
END;
$$ LANGUAGE plpgsql;


SELECT add_word_to_dict(1, 'fox', 'лиса', 'animals');

SELECT update_progress(1, TRUE);

SELECT * FROM get_user_stats(1);