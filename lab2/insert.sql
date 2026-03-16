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

TRUNCATE users, dicts, words, pairs, progress RESTART IDENTITY CASCADE;

INSERT INTO users (name, email)
SELECT 'User_' || i, 'user_' || i || '@example.com'
FROM generate_series(1, 1000) AS i;

WITH user_dict_counts AS (
    SELECT 
        id,
        floor(random() * 10 + 1)::int AS dicts_count
    FROM users
)
INSERT INTO dicts (user_id, title, description)
SELECT
    u.id,
    'Dict_' || u.id || '_' || gs,
    random_string(15) AS description
FROM user_dict_counts u
CROSS JOIN generate_series(1, u.dicts_count) AS gs;

INSERT INTO words (key, value)
SELECT 'key_' || i, 'value_' || i
FROM generate_series(1, 5000) AS i;

WITH dict_limits AS (
    SELECT id, floor(random() * 21 + 5)::int AS lim
    FROM dicts
)
INSERT INTO pairs (dict_id, word_id)
SELECT d.id, w.id
FROM dict_limits d
CROSS JOIN LATERAL (
    SELECT id FROM words ORDER BY random() LIMIT d.lim
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