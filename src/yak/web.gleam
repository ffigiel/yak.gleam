import gleam/bit_builder
import gleam/io
import gleam/int
import gleam/string
import gleam/bit_string
import gleam/result
import gleam/crypto
import gleam/http.{Get, Post}
import gleam/http/cors
import gleam/http/request
import gleam/http/response
import gleam/pgo
import yak/app_request.{AppRequest}
import yak/db
import yak/shared
import yak/middleware
import gleam/base

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

fn login(request: AppRequest) {
  let parsed_request =
    request.http.body
    |> bit_string.to_string
    |> result.unwrap("")
    |> shared.login_request_from_json
  // TODO avoid nesting by refactoring this to `use` syntax
  case parsed_request {
    Ok(req) -> {
      case db.get_user_by_email(request.db, req.email) {
        Ok(user) -> {
          let session_id = gen_session_id()
          let assert Ok(_) = db.create_session(request.db, user.pk, session_id)
          let body =
            string.concat(["welcome, ", user.email])
            |> bit_string.from_string
            |> bit_builder.from_bit_string
          response.new(200)
          |> response.prepend_header(
            "set-cookie",
            make_session_cookie(session_id),
          )
          |> response.set_body(body)
        }
        Error(db.NotFound) -> {
          let body =
            "User not found"
            |> bit_string.from_string
            |> bit_builder.from_bit_string
          response.new(400)
          |> response.set_body(body)
        }
        Error(error) -> {
          io.println(string.concat([
            "Internal Server Error: ",
            string.inspect(error),
          ]))
          panic
        }
      }
    }
    Error(error) -> {
      // TODO nicer error message
      let body =
        string.inspect(error)
        |> bit_string.from_string
        |> bit_builder.from_bit_string
      response.new(400)
      |> response.set_body(body)
    }
  }
}

fn gen_session_id() -> BitString {
  crypto.strong_random_bytes(32)
}

fn make_session_cookie(session_id: BitString) -> String {
  let parts = [
    string.concat(["session_id=", base.url_encode64(session_id, False)]),
    "Secure",
    "HttpOnly",
    // Expire the cookie in two weeks
    string.concat(["Max-Age=", int.to_string(2 * 7 * 24 * 60 * 60)]),
  ]
  string.join(parts, "; ")
}

fn not_found(_request) {
  let body =
    "Not Found"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(404)
  |> response.set_body(body)
}
