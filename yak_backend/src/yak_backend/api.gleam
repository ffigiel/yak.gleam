import gleam/bit_array
import gleam/http.{Get, Post}
import gleam/http/cors
import gleam/http/cookie
import gleam/http/request
import gleam/http/response
import gleam/option.{None, Some}
import gleam/io
import gleam/pgo
import gleam/result
import gleam/string
import gleam/bytes_builder
import yak_backend/api/app_request.{type AppRequest}
import yak_backend/api/middleware
import yak_backend/api/utils
import yak_backend/core
import yak_backend/db
import yak_common

pub fn stack(db: pgo.Connection) {
  // middlewares are executed from bottom to top
  service
  |> middleware.rescue
  |> middleware.log
  |> middleware.request_id
  |> middleware.app_request(db)
  |> cors_middleware()
}

fn cors_middleware() {
  cors.config()
  |> cors.allow_origins(["https://yak.localhost:3000"])
  |> cors.allow_methods([Get, Post])
  |> cors.allow_headers(["Content-Type", "Set-Cookie"])
  |> cors.allow_credentials(True)
  |> cors.to_middleware(bytes_builder.new())
}

fn service(request: AppRequest) {
  let path = request.path_segments(request.http)
  case path, request.http.method {
    ["app-context"], Get -> app_context(request)
    ["login"], Post -> login(request)
    ["logout"], Post -> logout(request)
    _, _ -> not_found(request)
  }
}

fn app_context(request: AppRequest) {
  case request.auth_info {
    Some(auth_info) ->
      yak_common.AppContext(user: yak_common.User(email: auth_info.user.email))
      |> yak_common.app_context_to_json
      |> utils.string_response(200, _)
    None -> utils.unauthorized()
  }
}

fn login(request: AppRequest) {
  request.http.body
  |> bit_array.to_string
  |> result.unwrap("")
  |> yak_common.login_request_from_json
  |> result.map_error(fn(error) {
    // TODO nicer message for parsing erorrs
    utils.string_response(400, string.inspect(error))
  })
  |> result.map(fn(req) {
    case core.login(request.db, req) {
      Ok(#(user, session_id)) -> {
        yak_common.AppContext(user: yak_common.User(email: user.email))
        |> yak_common.app_context_to_json
        |> utils.string_response(200, _)
        |> response.prepend_header(
          "Set-Cookie",
          make_session_cookie(session_id),
        )
      }
      Error(core.LoginUserLookupError(db.NotFound)) -> {
        utils.string_response(400, "User not found")
      }
      Error(error) -> {
        io.println(
          string.concat(["Internal Server Error: ", string.inspect(error)]),
        )
        utils.internal_server_error()
      }
    }
  })
  |> result.unwrap_both
}

fn make_session_cookie(session_id: BitArray) -> String {
  cookie.set_header(
    "session_id",
    bit_array.base64_url_encode(session_id, False),
    cookie.Attributes(
      // Expire the cookie in two weeks
      max_age: option.Some(2 * 7 * 24 * 60 * 60),
      domain: option.None,
      path: option.None,
      secure: True,
      http_only: True,
      same_site: option.Some(cookie.None),
    ),
  )
}

fn not_found(_request) {
  utils.not_found()
}

fn logout(request: AppRequest) {
  request.auth_info
  |> option.to_result(utils.string_response(400, "You are not logged in."))
  |> result.map(fn(auth_info) {
    case core.logout(request.db, auth_info.session_id) {
      Ok(_) -> {
        utils.string_response(200, "")
      }
      Error(core.LogoutSessionNotFoundError) -> {
        utils.string_response(400, "You are not logged in.")
      }
      Error(error) -> {
        io.println(
          string.concat(["Internal Server Error: ", string.inspect(error)]),
        )
        utils.internal_server_error()
      }
    }
  })
  |> result.unwrap_both
}
