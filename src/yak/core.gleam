import gleam/result
import yak/user
import gleam/crypto
import yak/app_request.{AppRequest}
import yak/db
import yak/shared

pub type LoginError {
  LoginUserLookupError(db.DbError)
  LoginCreateSessionError(db.DbError)
}

pub fn login(
  request: AppRequest,
  req: shared.LoginRequest,
) -> Result(#(user.User, BitString), LoginError) {
  db.get_user_by_email(request.db, req.email)
  |> result.map_error(LoginUserLookupError)
  |> result.then(fn(user) {
    let session_id = gen_session_id()
    db.create_session(request.db, user.pk, session_id)
    |> result.map_error(LoginCreateSessionError)
    |> result.map(fn(_) { #(user, session_id) })
  })
}

fn gen_session_id() -> BitString {
  crypto.strong_random_bytes(32)
}
