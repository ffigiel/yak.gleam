drop table if exists sessions;
drop table if exists users;

create table users
    ( pk bigserial primary key
    , created_on timestamp with time zone not null default now()
    , email text not null
    );

insert into
    users(email)
values
    ('user@example.com');

create table sessions
    ( pk bigserial primary key
    , created_on timestamp with time zone not null default now()
    , expires_on timestamp with time zone not null default now() + interval '5 days'
    , user_pk bigint not null references users(pk)
    , session_id bytea not null
    );
