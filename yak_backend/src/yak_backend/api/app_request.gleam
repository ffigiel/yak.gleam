import gleam/bit_array
import gleam/io
import gleam/string
import gleam/http/cookie
import gleam/list
import gleam/result
import gleam/option.{type Option}
import gleam/crypto
import gleam/http/request.{type Request}
import gleam/pgo
import yak_backend/user.{type User}
import yak_backend/db

pub type AppRequest {
  AppRequest(
    db: pgo.Connection,
    request_id: String,
    auth_info: Option(AuthInfo),
    http: Request(BitArray),
  )
}

pub type AuthInfo {
  AuthInfo(user: User, session_id: BitArray)
}

pub fn new(request: Request(BitArray), db: pgo.Connection) -> AppRequest {
  let request_id = gen_request_id()
  let auth_info =
    fetch_requst_user(request, db)
    |> option.from_result
  AppRequest(
    db: db,
    request_id: request_id,
    auth_info: auth_info,
    http: request,
  )
}

pub fn get_user(auth_info: Option(AuthInfo)) -> Option(User) {
  auth_info
  |> option.map(fn(auth_info) { auth_info.user })
}

fn gen_request_id() -> String {
  crypto.strong_random_bytes(8)
  |> bit_array.base64_url_encode(False)
}

fn fetch_requst_user(
  request: Request(_),
  db: pgo.Connection,
) -> Result(AuthInfo, Nil) {
  use raw_cookies <- result.try(request.get_header(request, "cookie"))
  let cookies = cookie.parse(raw_cookies)
  use session_id <- result.try(find_session_id_in_cookies(cookies))
  db.get_user_by_session_id(db, session_id)
  |> result.map_error(fn(err) {
    let log_level = case err {
      db.NotFound -> "Warning"
      _ -> "Error"
    }
    io.println(
      string.concat([log_level, ": error fetching user: ", string.inspect(err)]),
    )
  })
  |> result.map(fn(user) { AuthInfo(user, session_id) })
}

fn find_session_id_in_cookies(
  cookies: List(#(String, String)),
) -> Result(BitArray, Nil) {
  list.find(cookies, fn(item) { item.0 == "session_id" })
  |> result.try(fn(item) {
    item.1
    |> bit_array.base64_url_decode
    |> result.map_error(fn(_) { Nil })
  })
}
