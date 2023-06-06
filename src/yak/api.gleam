import gleam/base
import gleam/bit_string
import gleam/http.{Get, Post}
import gleam/http/cors
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/pgo
import gleam/result
import gleam/string
import yak/api/app_request.{AppRequest}
import yak/api/middleware
import yak/api/utils
import yak/core
import yak/db
import yak/shared

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
    utils.string_response(400, string.inspect(error))
  })
  |> result.map(fn(req) {
    case core.login(request.db, req) {
      Ok(#(user, session_id)) -> {
        utils.string_response(200, string.concat(["welcome, ", user.email]))
        |> response.prepend_header(
          "set-cookie",
          make_session_cookie(session_id),
        )
      }
      Error(core.LoginUserLookupError(db.NotFound)) -> {
        utils.string_response(400, "User not found")
      }
      Error(error) -> {
        io.println(string.concat([
          "Internal Server Error: ",
          string.inspect(error),
        ]))
        utils.internal_server_error()
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
  utils.not_found()
}
