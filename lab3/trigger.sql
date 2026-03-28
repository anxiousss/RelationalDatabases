CREATE OR REPLACE FUNCTION trg_progress_calc_next_repetition()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.last_repetition IS NULL THEN
        NEW.last_repetition := NOW();
    END IF;
    NEW.next_repetition := NEW.last_repetition + (NEW.knowledge_level * INTERVAL '1 day');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER progress_before_insert_update
    BEFORE INSERT OR UPDATE OF knowledge_level, last_repetition ON progress
    FOR EACH ROW
    EXECUTE FUNCTION trg_progress_calc_next_repetition();

CREATE OR REPLACE FUNCTION trg_dict_limit_per_user()
RETURNS TRIGGER AS $$
DECLARE
    v_dict_count INTEGER;
    v_max_dicts CONSTANT INTEGER := 11;  
BEGIN
    SELECT COUNT(*) INTO v_dict_count
    FROM dicts
    WHERE user_id = NEW.user_id;

    IF v_dict_count >= v_max_dicts THEN
        RAISE EXCEPTION 'Пользователь % уже имеет максимальное количество словарей (%)', NEW.user_id, v_max_dicts;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dict_before_insert
    BEFORE INSERT ON dicts
    FOR EACH ROW
    EXECUTE FUNCTION trg_dict_limit_per_user();

CREATE OR REPLACE FUNCTION trg_word_check_topic()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.topic IS NULL OR NEW.topic = '' THEN
        RAISE EXCEPTION 'Тема слова не может быть пустой';
    END IF;

    IF NEW.topic NOT IN ('animals', 'food', 'colors', 'family', 'actions') THEN
        RAISE EXCEPTION 'Недопустимая тема "%". Разрешённые: animals, food, colors, family, actions', NEW.topic;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER word_before_insert_update
    BEFORE INSERT OR UPDATE OF topic ON words
    FOR EACH ROW
    EXECUTE FUNCTION trg_word_check_topic();

INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition)
VALUES (1, 3, 0, 0, NOW());  

INSERT INTO dicts (user_id, title, description, topic)
VALUES (2, 'Шестой словарь', 'Нарушает лимит', 'animals');

INSERT INTO words (key, value, topic) VALUES ('car', 'машина', 'transport');
