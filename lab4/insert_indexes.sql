BEGIN;

DROP TABLE IF EXISTS words_with_idx CASCADE;
DROP TABLE IF EXISTS words_no_idx CASCADE;


CREATE TABLE words_with_idx (
    id SERIAL,
    key text NOT NULL,
    value text NOT NULL,
    topic text
);
ALTER TABLE words_with_idx ADD CONSTRAINT pk_words_with_idx PRIMARY KEY (id);
ALTER TABLE words_with_idx ADD CONSTRAINT unique_key_temp UNIQUE (key, value);
CREATE INDEX idx_words_topic_id_temp ON words_with_idx (topic, id) INCLUDE (key, value);
CREATE INDEX idx_words_key_trgm_temp ON words_with_idx USING gin (key gin_trgm_ops);
CREATE INDEX idx_words_lower_key_temp ON words_with_idx (lower(key));


CREATE TABLE words_no_idx (
    id SERIAL,
    key text,
    value text,
    topic text
);

WITH base_words AS (
    SELECT * FROM (
        VALUES
        ('dog','собака','animals'),
        ('cat','кошка','animals'),
        ('bird','птица','animals'),
        ('fish','рыба','animals'),
        ('lion','лев','animals'),
        ('tiger','тигр','animals'),
        ('elephant','слон','animals'),
        ('monkey','обезьяна','animals'),
        ('snake','змея','animals'),
        ('rabbit','кролик','animals'),
        ('apple','яблоко','food'),
        ('banana','банан','food'),
        ('bread','хлеб','food'),
        ('milk','молоко','food'),
        ('cheese','сыр','food'),
        ('meat','мясо','food'),
        ('egg','яйцо','food'),
        ('potato','картофель','food'),
        ('tomato','помидор','food'),
        ('cucumber','огурец','food'),
        ('orange','апельсин','food'),
        ('red','красный','colors'),
        ('green','зелёный','colors'),
        ('blue','синий','colors'),
        ('yellow','жёлтый','colors'),
        ('black','чёрный','colors'),
        ('white','белый','colors'),
        ('orange_color','оранжевый','colors'),
        ('purple','фиолетовый','colors'),
        ('pink','розовый','colors'),
        ('brown','коричневый','colors'),
        ('mother','мать','family'),
        ('father','отец','family'),
        ('sister','сестра','family'),
        ('brother','брат','family'),
        ('grandmother','бабушка','family'),
        ('grandfather','дедушка','family'),
        ('aunt','тётя','family'),
        ('uncle','дядя','family'),
        ('wife','жена','family'),
        ('husband','муж','family'),
        ('run','бежать','actions'),
        ('walk','идти','actions'),
        ('eat','есть','actions'),
        ('drink','пить','actions'),
        ('sleep','спать','actions'),
        ('read','читать','actions'),
        ('write','писать','actions'),
        ('speak','говорить','actions'),
        ('listen','слушать','actions'),
        ('watch','смотреть','actions')
    ) AS t(key, value, topic)
)
INSERT INTO words_with_idx (key, value, topic)
SELECT base.key || '_' || i, base.value || '_' || i, base.topic
FROM generate_series(1, 20000) AS i
CROSS JOIN base_words base;

INSERT INTO words_no_idx (key, value, topic)
SELECT key, value, topic FROM words_with_idx;


EXPLAIN (ANALYZE, BUFFERS) UPDATE words_with_idx SET value = 'updated_idx' WHERE key = 'dog_1';
EXPLAIN (ANALYZE, BUFFERS) UPDATE words_with_idx SET value = 'batch_idx' WHERE topic = 'animals';
EXPLAIN (ANALYZE, BUFFERS) UPDATE words_with_idx SET value = 'all_' || id;
EXPLAIN (ANALYZE, BUFFERS) 
INSERT INTO words_with_idx (key, value, topic)
SELECT 'new_ins_' || i, 'new_val_' || i, 'animals'
FROM generate_series(1, 10000) i
ON CONFLICT (key, value) DO NOTHING;
DELETE FROM words_with_idx WHERE key = 'unique_conflict_key';
EXPLAIN (ANALYZE, BUFFERS) 
INSERT INTO words_with_idx (key, value, topic)
VALUES ('unique_conflict_key', 'unique_val', 'animals')
ON CONFLICT (key, value) DO UPDATE SET value = EXCLUDED.value;


EXPLAIN (ANALYZE, BUFFERS) UPDATE words_no_idx SET value = 'updated_no_idx' WHERE key = 'dog_1';
EXPLAIN (ANALYZE, BUFFERS) UPDATE words_no_idx SET value = 'batch_no_idx' WHERE topic = 'animals';
EXPLAIN (ANALYZE, BUFFERS) UPDATE words_no_idx SET value = 'all_' || id;
EXPLAIN (ANALYZE, BUFFERS) 
INSERT INTO words_no_idx (key, value, topic)
SELECT 'new_no_' || i, 'new_val_no_' || i, 'animals'
FROM generate_series(1, 10000) i;
EXPLAIN (ANALYZE, BUFFERS) 
INSERT INTO words_no_idx (key, value, topic)
VALUES ('simple_insert_test', 'simple_val', 'animals');


EXPLAIN (ANALYZE, BUFFERS) UPDATE progress SET knowledge_level = 5 WHERE pair_id = 100000;

ROLLBACK;