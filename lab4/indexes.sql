DROP INDEX IF EXISTS idx_words_topic_id;
CREATE INDEX idx_words_topic_id ON words(topic, id) INCLUDE (key, value);

DROP INDEX IF EXISTS idx_progress_next_last;
CREATE INDEX idx_progress_next_last ON progress(next_repetition, last_repetition);

--CREATE INDEX idx_progress_knowledge_last ON progress(knowledge_level, last_repetition);


DROP INDEX IF EXISTS idx_progress_pair_knowledge_last;
CREATE INDEX idx_progress_pair_knowledge_last ON progress(pair_id, knowledge_level, last_repetition);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
DROP INDEX IF exists idx_words_key_trgm;
CREATE INDEX idx_words_key_trgm ON words USING gin (key gin_trgm_ops);

DROP INDEX IF exists idx_pairs_dict_word;
CREATE INDEX idx_pairs_dict_word ON pairs(dict_id, word_id);

DROP INDEX IF exists idx_words_lower_key;
CREATE INDEX idx_words_lower_key ON words (lower(key));
