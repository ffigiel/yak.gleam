import gleam/bit_builder
import gleam/bit_string
import gleam/crypto
import gleam/http.{Get, Post}
import gleam/http/cors
import gleam/http/request
import gleam/http/response
import gleam/io
import gleam/pgo
import yak/app_request.{AppRequest}
import yak/db
import yak/middleware

pub fn stack(db: pgo.Connection) {
  // middlewares are executed from bottom to top
  service
  |> middleware.rescue
  |> middleware.log
  |> middleware.request_id
  |> middleware.app_request(db)
  |> cors.middleware(
    origins: ["http://localhost:3001"],
    methods: [Get, Post],
    headers: ["content-type"],
  )
}

fn service(request: AppRequest) {
  let path = request.path_segments(request.http)
  case request.http.method, path {
    Post, ["login"] -> login(request)
    _, _ -> not_found(request)
  }
}

fn login(request) {
  let session_id = gen_session_id()
  assert Ok(_) = db.create_session(request.db, 1, session_id)
  let body =
    "welcome"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(200)
  |> response.set_body(body)
}

fn gen_session_id() -> BitString {
  crypto.strong_random_bytes(32)
}

fn not_found(_request) {
  let body =
    "Not Found"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(404)
  |> response.set_body(body)
}
