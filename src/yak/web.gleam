import yak/middleware
import gleam/bit_string
import gleam/bit_builder
import gleam/http/request
import gleam/http/response
import gleam/http.{Post}
import gleam/pgo
import gleam/io
import yak/app_request.{AppRequest}
import yak/crypto
import yak/db

pub fn stack(db: pgo.Connection) {
  // middlewares are executed from bottom to top
  service
  |> middleware.rescue
  |> middleware.log
  |> middleware.app_request(db)
}

fn service(request: AppRequest) {
  let path = request.path_segments(request.http)
  case request.http.method, path {
    Post, ["login"] -> login(request)
    _, _ -> not_found(request)
  }
}

fn login(request) {
  let session_id = crypto.gen_session_id()
  assert Ok(_) = db.create_session(request.db, 1, session_id)
  let body =
    "welcome"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(200)
  |> response.set_body(body)
}

fn not_found(_request) {
  let body =
    "Not Found"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(404)
  |> response.set_body(body)
}
