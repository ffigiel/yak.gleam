import gleam/pgo
import gleam/result
import gleam/string
import gleam/dynamic.{Dynamic}
import yak/user.{User}

pub type DbError {
  NotFound
  MultipleRowsReturned
  QueryError(pgo.QueryError)
}

fn get_one(
  sql: String,
  pool: pgo.Connection,
  arguments: List(pgo.Value),
  decoder: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
) -> Result(a, DbError) {
  let sql = string.concat([sql, " limit 2"])
  case pgo.execute(sql, pool, arguments, decoder) {
    Ok(pgo.Returned(rows: [data], ..)) -> Ok(data)
    Ok(pgo.Returned(rows: [], ..)) -> Error(NotFound)
    Ok(pgo.Returned(rows: [_, _, ..], ..)) -> Error(MultipleRowsReturned)
    Error(error) -> Error(QueryError(error))
  }
}

// Users

pub fn get_user_by_email(
  db: pgo.Connection,
  email: String,
) -> Result(User, DbError) {
  let sql =
    "
    select
      pk, email, password_hash
    from users
    where
      email = $1
    "
  get_one(
    sql,
    db,
    [pgo.text(email)],
    dynamic.tuple3(dynamic.int, dynamic.string, dynamic.bit_string),
  )
  |> result.map(fn(data) {
    User(pk: data.0, email: data.1, password_hash: data.2)
  })
}

pub fn get_user_by_session_id(
  db: pgo.Connection,
  session_id: BitString,
) -> Result(User, DbError) {
  let sql =
    "
    select
      u.pk, u.email, u.password_hash
    from users u
    join sessions s on
      u.pk = s.user_pk
    where
      session_id = $1
    "
  get_one(
    sql,
    db,
    [pgo.bytea(session_id)],
    dynamic.tuple3(dynamic.int, dynamic.string, dynamic.bit_string),
  )
  |> result.map(fn(data) {
    User(pk: data.0, email: data.1, password_hash: data.2)
  })
}

// Sessions

pub fn create_session(
  db: pgo.Connection,
  user_pk: Int,
  session_id: BitString,
) -> Result(Nil, DbError) {
  let sql =
    "
    insert into sessions
      (user_pk, session_id)
    values
      ($1, $2)
    "
  pgo.execute(
    sql,
    db,
    [pgo.int(user_pk), pgo.bytea(session_id)],
    dynamic.dynamic,
  )
  |> result.replace(Nil)
  |> result.map_error(QueryError)
}

pub fn check_session_exists(
  db: pgo.Connection,
  session_id: BitString,
) -> Result(Nil, DbError) {
  let sql =
    "
    select 1
    from sessions
    where
      session_id = $1
    "
  get_one(sql, db, [pgo.bytea(session_id)], dynamic.dynamic)
  |> result.replace(Nil)
}

pub fn delete_session(
  db: pgo.Connection,
  session_id: BitString,
) -> Result(Nil, DbError) {
  let sql =
    "
    delete
    from sessions
    where
      session_id = $1
    "
  pgo.execute(sql, db, [pgo.bytea(session_id)], dynamic.dynamic)
  |> result.replace(Nil)
  |> result.map_error(QueryError)
}
