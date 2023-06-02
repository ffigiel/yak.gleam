import gleam/pgo
import gleam/dynamic
import yak/user.{User}

pub type DbError {
  NotFound
  MultipleRowsReturned(Int)
  QueryError(pgo.QueryError)
}

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
  let result =
    pgo.execute(
      sql,
      db,
      [pgo.text(email)],
      dynamic.tuple3(dynamic.int, dynamic.string, dynamic.bit_string),
    )
  case result {
    Ok(returned) -> {
      case returned.rows {
        [] -> Error(NotFound)
        [_, _, ..] -> Error(MultipleRowsReturned(returned.count))
        [data] -> {
          let user = User(pk: data.0, email: data.1, password_hash: data.2)
          Ok(user)
        }
      }
    }
    Error(err) -> Error(QueryError(err))
  }
}

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
  let result =
    pgo.execute(
      sql,
      db,
      [pgo.int(user_pk), pgo.bytea(session_id)],
      dynamic.dynamic,
    )
  case result {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(QueryError(err))
  }
}
