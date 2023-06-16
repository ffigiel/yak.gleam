import gleam/crypto
import gleam/pgo
import gleam/result
import yak/db
import yak/shared
import yak/user

pub type LoginError {
  LoginUserLookupError(db.DbError)
  LoginCreateSessionError(db.DbError)
}

pub fn login(
  db: pgo.Connection,
  req: shared.LoginRequest,
) -> Result(#(user.User, BitString), LoginError) {
  db.get_user_by_email(db, req.email)
  |> result.map_error(LoginUserLookupError)
  |> result.then(fn(user) {
    let session_id = gen_session_id()
    db.create_session(db, user.pk, session_id)
    |> result.map_error(LoginCreateSessionError)
    |> result.map(fn(_) { #(user, session_id) })
  })
}

fn gen_session_id() -> BitString {
  crypto.strong_random_bytes(32)
}

pub type LogoutError {
  LogoutSessionNotFoundError
  LogoutSessionLookupError(db.DbError)
  LogoutDeleteSessionError(db.DbError)
}

pub fn logout(
  db: pgo.Connection,
  session_id: BitString,
) -> Result(Nil, LogoutError) {
  db.check_session_exists(db, session_id)
  |> result.map_error(fn(err) {
    case err {
      db.NotFound -> LogoutSessionNotFoundError
      err -> LogoutDeleteSessionError(err)
    }
  })
  |> result.then(fn(_) {
    db.delete_session(db, session_id)
    |> result.map_error(LogoutDeleteSessionError)
  })
}
