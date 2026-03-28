CREATE OR REPLACE FUNCTION random_string(length integer) 
RETURNS text AS $$
DECLARE
  chars text[] := '{A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
  result text := '';
  i integer;
BEGIN
  FOR i IN 1..length LOOP
    result := result || chars[1 + (random() * (array_length(chars, 1) - 1))::int];
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE words ADD COLUMN IF NOT EXISTS topic text;
ALTER TABLE dicts ADD COLUMN IF NOT EXISTS topic text;

TRUNCATE users, dicts, words, pairs, progress RESTART IDENTITY CASCADE;

INSERT INTO users (name, email)
SELECT 'User_' || i, 'user_' || i || '@example.com'
FROM generate_series(1, 1000) AS i;

INSERT INTO words (key, value, topic) VALUES
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
('red', 'красный', 'colors'),
('green', 'зелёный', 'colors'),
('blue', 'синий', 'colors'),
('yellow', 'жёлтый', 'colors'),
('black', 'чёрный', 'colors'),
('white', 'белый', 'colors'),
('orange', 'оранжевый', 'colors'),
('purple', 'фиолетовый', 'colors'),
('pink', 'розовый', 'colors'),
('brown', 'коричневый', 'colors'),
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

WITH user_dict_counts AS (
    SELECT 
        id,
        floor(random() * 10 + 1)::int AS dicts_count
    FROM users
)
INSERT INTO dicts (user_id, title, description, topic)
SELECT
    u.id,
    'Dict_' || u.id || '_' || gs,
    'My dictionary',
    (ARRAY['animals','food','colors','family','actions'])[floor(random() * 5 + 1)]
FROM user_dict_counts u
CROSS JOIN generate_series(1, u.dicts_count) AS gs;

WITH dict_limits AS (
    SELECT id, topic, floor(random() * 21 + 5)::int AS lim
    FROM dicts
)
INSERT INTO pairs (dict_id, word_id)
SELECT d.id, w.id
FROM dict_limits d
CROSS JOIN LATERAL (
    SELECT id FROM words WHERE topic = d.topic ORDER BY random() LIMIT d.lim
) w;

INSERT INTO progress (pair_id, knowledge_level, repetitions, correct_in_a_row, last_repetition, next_repetition)
SELECT
    id,
    floor(random() * 5 + 1)::int,
    floor(random() * 10)::int,
    floor(random() * 5)::int,
    now() - (random() * interval '30 days'),
    now() + (random() * interval '30 days')
FROM pairs;