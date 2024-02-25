import gleam/dynamic.{type Dynamic}
import gleam/fetch
import gleam/http
import gleam/http/request
import gleam/http/response.{type Response, Response}
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/string
import yak_common
import yak_ui/core

pub fn fetch_error_to_string(e: fetch.FetchError) -> String {
  case e {
    fetch.NetworkError(msg) -> "Network Error: " <> msg
    fetch.UnableToReadBody -> "Unable to read response body"
    fetch.InvalidJsonBody -> "Invalid JSON response"
  }
}

pub fn fetch_app_context() -> Promise(core.AuthState) {
  let request =
    request.new()
    |> request.set_method(http.Get)
    |> request.set_scheme(http.Https)
    |> request.set_host("api.yak.localhost:3000")
    |> request.set_path("app-context")
    |> fetch.to_fetch_request()
  let options =
    fetch.make_options()
    |> fetch.with_credentials(fetch.Include)
  fetch.raw_send_with_options(request, options)
  |> promise.await(fn(result) {
    case result.map(result, fetch.from_fetch_response) {
      Ok(Response(status: 200, ..) as response) ->
        fetch.read_json_body(response)
        |> handle_app_context
      Ok(Response(status: 401, ..)) -> promise.resolve(core.Unauthenticated)
      Ok(response) ->
        fetch.read_text_body(response)
        |> handle_unexpected_app_context
      Error(err) -> {
        fetch_error_to_string(err)
        |> core.AuthError
        |> promise.resolve
      }
    }
  })
}

fn handle_app_context(
  promise: Promise(Result(Response(Dynamic), fetch.FetchError)),
) -> Promise(core.AuthState) {
  promise.map(promise, fn(result) {
    result.map_error(result, fn(e) {
      fetch_error_to_string(e)
      |> core.AuthError
    })
    |> result.then(fn(response) {
      response.body
      |> yak_common.app_context_decoder()
      |> result.map_error(fn(e) {
        string.inspect(e)
        |> core.AuthError
      })
    })
    |> result.map(fn(app_context) { core.Authenticated(app_context) })
    |> result.unwrap_both
  })
}

fn handle_unexpected_app_context(
  promise: Promise(Result(Response(String), fetch.FetchError)),
) -> Promise(core.AuthState) {
  promise.map(promise, fn(result) {
    result.map(result, fn(response) {
      core.AuthError(
        "Unexpected server response ("
        <> int.to_string(response.status)
        <> "): "
        <> response.body,
      )
    })
    |> result.map_error(fn(e) {
      fetch_error_to_string(e)
      |> core.AuthError
    })
    |> result.unwrap_both
  })
}

pub fn send_login_request(
  request: yak_common.LoginRequest,
) -> Promise(Result(yak_common.AppContext, String)) {
  let body =
    request
    |> yak_common.login_request_to_json
  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Https)
    |> request.set_host("api.yak.localhost:3000")
    |> request.set_path("login")
    |> request.set_body(body)
    |> fetch.to_fetch_request()
  let options =
    fetch.make_options()
    |> fetch.with_credentials(fetch.Include)
  fetch.raw_send_with_options(request, options)
  |> promise.await(fn(result) {
    case result.map(result, fetch.from_fetch_response) {
      Ok(Response(status: 200, ..) as response) ->
        fetch.read_json_body(response)
        |> handle_login_response
      Ok(response) ->
        fetch.read_text_body(response)
        |> handle_unexpected_login_response
      Error(err) -> promise.resolve(Error(fetch_error_to_string(err)))
    }
  })
}

fn handle_login_response(
  promise: Promise(Result(Response(Dynamic), fetch.FetchError)),
) -> Promise(Result(yak_common.AppContext, String)) {
  promise.map(promise, fn(result) {
    result.map_error(result, fetch_error_to_string)
    |> result.then(fn(response) {
      response.body
      |> yak_common.app_context_decoder()
      |> result.map_error(string.inspect)
    })
  })
}

fn handle_unexpected_login_response(
  promise: Promise(Result(Response(String), fetch.FetchError)),
) -> Promise(Result(yak_common.AppContext, String)) {
  promise.map(promise, fn(result) {
    case result {
      Ok(response) ->
        Error(
          "Unexpected server response ("
          <> int.to_string(response.status)
          <> "): "
          <> response.body,
        )
      Error(err) -> Error(fetch_error_to_string(err))
    }
  })
}

pub fn send_logout_request() -> Promise(Result(Nil, String)) {
  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_scheme(http.Https)
    |> request.set_host("api.yak.localhost:3000")
    |> request.set_path("logout")
    |> fetch.to_fetch_request()
  let options =
    fetch.make_options()
    |> fetch.with_credentials(fetch.Include)
  fetch.raw_send_with_options(request, options)
  |> promise.map(fn(res) { result.map(res, fetch.from_fetch_response) })
  |> promise.await(fn(result) {
    case result {
      Ok(response) ->
        case response.status {
          200 -> promise.resolve(Ok(Nil))
          _ ->
            promise.resolve(Error(
              "Unexpected status code: " <> int.to_string(response.status),
            ))
        }
      Error(err) -> promise.resolve(Error(fetch_error_to_string(err)))
    }
  })
}
