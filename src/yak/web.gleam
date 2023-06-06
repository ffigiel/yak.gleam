import gleam/bit_builder.{BitBuilder}
import gleam/io
import gleam/int
import gleam/string
import gleam/bit_string
import gleam/result
import gleam/http.{Get, Post}
import gleam/http/cors
import gleam/http/request
import gleam/http/response.{Response}
import gleam/pgo
import yak/app_request.{AppRequest}
import yak/db
import yak/shared
import yak/middleware
import yak/core
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
  request.http.body
  |> bit_string.to_string
  |> result.unwrap("")
  |> shared.login_request_from_json
  |> result.map_error(fn(error) {
    // TODO nicer message for parsing erorrs
    let body =
      string.inspect(error)
      |> bit_string.from_string
      |> bit_builder.from_bit_string
    response.new(400)
    |> response.set_body(body)
  })
  |> result.then(fn(req) {
    case core.login(request, req) {
      Ok(#(user, session_id)) -> {
        string_response(200, string.concat(["welcome, ", user.email]))
        |> response.prepend_header(
          "set-cookie",
          make_session_cookie(session_id),
        )
        |> Ok
      }
      Error(core.LoginUserLookupError(db.NotFound)) -> {
        string_response(400, "User not found")
        |> Error
      }
      Error(error) -> {
        io.println(string.concat([
          "Internal Server Error: ",
          string.inspect(error),
        ]))
        string_response(500, "Internal Server Error")
        |> Error
      }
    }
  })
  |> result.unwrap_both
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
  string_response(404, "Not Found")
}

fn string_response(status_code: Int, body: String) -> Response(BitBuilder) {
  response.new(status_code)
  |> response.set_body(
    body
    |> bit_string.from_string
    |> bit_builder.from_bit_string,
  )
}
