create table if not exists users (
    id SERIAL primary key,
    name text,
    email text
);

create table if not exists dicts (
    id SERIAL primary key,
    user_id INTEGER not null,
    title text,
    description text,
    foreign key (user_id) references users(id)
        on delete cascade
        on update cascade
);

create table if not exists words (
    id SERIAL primary key,
    key text,
    value text
);

create table if not exists pairs (
    id SERIAL primary key,
    dict_id INTEGER not null,
    word_id INTEGER not null,
    foreign key (dict_id) references dicts(id)
        on delete cascade
        on update cascade,
    foreign key (word_id) references words(id)
        on delete cascade
        on update cascade,
    CONSTRAINT unique_pairs UNIQUE (dict_id, word_id)  
);

create table if not exists progress (
    user_id INTEGER not null,
    pair_id INTEGER not null,
    knowledge_level INTEGER,          
    repetitions INTEGER,
    correct_in_a_row INTEGER,
    last_repetition timestamp,
    next_repetition timestamp,
    foreign key (user_id) references users(id)
        on delete cascade
        on update cascade,
    foreign key (pair_id) references pairs(id)
        on delete cascade
        on update cascade
);