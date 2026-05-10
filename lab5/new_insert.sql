-- 1. Очистка (как у вас)
TRUNCATE users, dicts, words, pairs, progress RESTART IDENTITY CASCADE;

-- 2. Слова с темами (реальные слова)
INSERT INTO words (key, value, topic) VALUES
-- animals
('dog', 'собака', 'animals'),
('cat', 'кошка', 'animals'),
('bird', 'птица', 'animals'),
('fish', 'рыба', 'animals'),
('lion', 'лев', 'animals'),
('tiger', 'тигр', 'animals'),
('elephant', 'слон', 'animals'),
('monkey', 'обезьяна', 'animals'),
('snake', 'змея', 'animals'),
('rabbit', 'кролик', 'animals'),
-- food
('apple', 'яблоко', 'food'),
('banana', 'банан', 'food'),
('bread', 'хлеб', 'food'),
('milk', 'молоко', 'food'),
('cheese', 'сыр', 'food'),
('meat', 'мясо', 'food'),
('egg', 'яйцо', 'food'),
('potato', 'картофель', 'food'),
('tomato', 'помидор', 'food'),
('cucumber', 'огурец', 'food'),
('orange', 'апельсин', 'food'),
-- colors
('red', 'красный', 'colors'),
('green', 'зелёный', 'colors'),
('blue', 'синий', 'colors'),
('yellow', 'жёлтый', 'colors'),
('black', 'чёрный', 'colors'),
('white', 'белый', 'colors'),
('orange_color', 'оранжевый', 'colors'),
('purple', 'фиолетовый', 'colors'),
('pink', 'розовый', 'colors'),
('brown', 'коричневый', 'colors'),
-- family
('mother', 'мать', 'family'),
('father', 'отец', 'family'),
('sister', 'сестра', 'family'),
('brother', 'брат', 'family'),
('grandmother', 'бабушка', 'family'),
('grandfather', 'дедушка', 'family'),
('aunt', 'тётя', 'family'),
('uncle', 'дядя', 'family'),
('wife', 'жена', 'family'),
('husband', 'муж', 'family'),
-- actions
('run', 'бежать', 'actions'),
('walk', 'идти', 'actions'),
('eat', 'есть', 'actions'),
('drink', 'пить', 'actions'),
('sleep', 'спать', 'actions'),
('read', 'читать', 'actions'),
('write', 'писать', 'actions'),
('speak', 'говорить', 'actions'),
('listen', 'слушать', 'actions'),
('watch', 'смотреть', 'actions');

-- 3. Пользователи (реалистичные имена)
INSERT INTO users (name, email) VALUES
('Анна Иванова', 'anna.i@example.com'),
('Петр Смирнов', 'petr.s@example.com'),
('Елена Козлова', 'elena.k@example.com'),
('Дмитрий Попов', 'dmitry.p@example.com'),
('Ольга Соколова', 'olga.s@example.com');

-- 4. Словари (каждый пользователь создаёт словари по разным темам)
INSERT INTO dicts (user_id, title, description, topic) VALUES
-- Пользователь 1 (Анна)
(1, 'Животные (начальный)', 'Базовые названия животных', 'animals'),
(1, 'Еда и напитки', 'Всё о еде', 'food'),
-- Пользователь 2 (Петр)
(2, 'Цвета и оттенки', 'Учим цвета на английском', 'colors'),
(2, 'Семья и родственники', 'Слова по теме семьи', 'family'),
(2, 'Глаголы движения', 'Активные глаголы', 'actions'),
-- Пользователь 3 (Елена)
(3, 'Моя семья', 'Семейные отношения', 'family'),
(3, 'Фрукты и овощи', 'Полезная еда', 'food'),
(3, 'Действия в офисе', 'Глаголы для работы', 'actions'),
-- Пользователь 4 (Дмитрий)
(4, 'Дикие животные', 'Животные саванны и леса', 'animals'),
(4, 'Цветовой круг', 'Основные цвета', 'colors'),
-- Пользователь 5 (Ольга)
(5, 'Активный отдых', 'Глаголы для спорта и прогулок', 'actions'),
(5, 'Домашние питомцы', 'Животные-компаньоны', 'animals');

-- 5. Связи "словарь – слово" (только слова, соответствующие теме словаря)
DO $$
DECLARE
    d RECORD;
    w RECORD;
BEGIN
    FOR d IN SELECT id, topic FROM dicts LOOP
        FOR w IN SELECT id FROM words WHERE topic = d.topic LOOP
            INSERT INTO pairs (dict_id, word_id) VALUES (d.id, w.id);
        END LOOP;
    END LOOP;
END $$;

-- 6. Прогресс (реалистичный: уровень знаний, интервалы повторений)
-- Правила: knowledge_level от 0 до 4 (0 – выучено плохо, 4 – отлично)
-- next_repetition вычисляется по принципу: чем выше уровень, тем больше интервал
DO $$
DECLARE
    p RECORD;
    days_interval INT;
    lvl INT;
    last_date TIMESTAMP;
    correct INT;
    reps INT;
BEGIN
    FOR p IN SELECT id FROM pairs LOOP
        -- Случайный уровень знаний (склоняемся к среднему)
        lvl := floor(random() * 5)::int; -- 0..4
        -- Количество правильных подряд (не больше уровня+1)
        correct := floor(random() * (lvl + 2))::int;
        -- Количество повторений (не меньше уровня)
        reps := lvl + floor(random() * 3)::int;
        -- Дата последнего повторения: от 1 до 60 дней назад
        last_date := now() - (random() * interval '60 days');
        -- Вычисляем следующий интервал по простой формуле:
        -- если уровень 0 -> интервал 1 день, 1 -> 3 дня, 2 -> 7 дней, 3 -> 14 дней, 4 -> 30 дней
        days_interval := CASE lvl
            WHEN 0 THEN 1
            WHEN 1 THEN 3
            WHEN 2 THEN 7
            WHEN 3 THEN 14
            WHEN 4 THEN 30
        END;
        INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
        VALUES (p.id, lvl, reps, correct, last_date, last_date + (days_interval || ' days')::interval);
    END LOOP;
END $$;