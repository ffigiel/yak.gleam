import lustre/effect
import gleam/http/response.{type Response}
import gleam/http
import gleam/string
import gleam/int
import gleam/dynamic.{type Dynamic}
import gleam/result
import gleam/http/request
import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type AppEffect, type Page, Page}
import yak_common
import gleam/fetch
import gleam/javascript/promise.{type Promise}

pub const page = Page(init: init, update: update, view: view)

pub opaque type State {
  StateLoading
  StateError(String)
}

fn init() {
  let effect = {
    use dispatch <- effect.from
    fetch_app_context()
    |> promise.tap(fn(result) {
      GotAuthState(result)
      |> dispatch
    })
    Nil
  }
  #(StateLoading, core.PageEffect(effect))
}

fn fetch_app_context() -> Promise(core.AuthState) {
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
  |> promise.map(fn(res) { result.map(res, fetch.from_fetch_response) })
  |> promise.await(fn(res) {
    case res {
      Ok(res) ->
        case res.status {
          200 ->
            fetch.read_json_body(res)
            |> handle_app_context_response
          401 -> promise.resolve(core.Unauthenticated)
          _ ->
            fetch.read_text_body(res)
            |> handle_unexpected_response
        }
      Error(e) -> {
        from_fetch_error_to_string(e)
        |> core.AuthError
        |> promise.resolve
      }
    }
  })
}

fn handle_app_context_response(
  promise: Promise(Result(Response(Dynamic), fetch.FetchError)),
) -> Promise(core.AuthState) {
  promise.map(promise, fn(result) {
    result.map_error(result, fn(e) {
      from_fetch_error_to_string(e)
      |> core.AuthError
    })
    |> result.then(fn(response) {
      response.body
      |> yak_common.app_context_response_decoder()
      |> result.map_error(fn(e) {
        string.inspect(e)
        |> core.AuthError
      })
    })
    |> result.map(fn(app_context) { core.Authenticated(app_context) })
    |> result.unwrap_both
  })
}

fn handle_unexpected_response(
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
      from_fetch_error_to_string(e)
      |> core.AuthError
    })
    |> result.unwrap_both
  })
}

fn from_fetch_error_to_string(e: fetch.FetchError) -> String {
  case e {
    fetch.NetworkError(msg) -> "Network Error: " <> msg
    fetch.UnableToReadBody -> "Unable to read response body"
    fetch.InvalidJsonBody -> "Invalid JSON response"
  }
}

pub opaque type Action {
  GotAuthState(core.AuthState)
}

fn update(state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    GotAuthState(auth_state) -> {
      let fx = core.SharedEffect(core.GotAuthState(auth_state))
      case auth_state {
        core.AuthError(msg) -> #(StateError(msg), fx)
        _ -> #(state, fx)
      }
    }
  }
}

fn view(state: State) -> Element(Action) {
  case state {
    StateError(msg) -> html.p([], [element.text("Error: " <> msg)])
    _ -> html.p([], [element.text("Loading")])
  }
}
