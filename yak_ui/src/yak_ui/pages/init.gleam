import lustre/effect
import gleam/http/response.{type Response}
import gleam/http
import gleam/string
import gleam/dynamic.{type Dynamic}
import gleam/result
import gleam/http/request
import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type AppEffect, type Page, Page}
import yak_common
import gleam/fetch
import gleam/javascript/promise.{type Promise}

pub fn page() -> Page(State, Action) {
  Page(init: init, update: update, view: view)
}

pub opaque type State {
  StateLoading
  StateError(String)
}

fn init() {
  let effect = {
    use dispatch <- effect.from
    fetch_app_context()
    |> promise.tap(fn(result) {
      result
      |> GotAppContext
      |> dispatch
    })
    Nil
  }
  #(StateLoading, core.PageEffect(effect))
}

fn fetch_app_context() -> Promise(Result(yak_common.AppContextResponse, String)) {
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
  let fetch_result: Promise(Result(Response(Dynamic), fetch.FetchError)) =
    fetch.raw_send_with_options(request, options)
    |> promise.map(fn(res) { result.map(res, fetch.from_fetch_response) })
    |> promise.await(fn(res) {
      case res {
        Ok(res) -> fetch.read_json_body(res)
        Error(e) -> promise.resolve(Error(e))
      }
    })
  fetch_result
  |> promise.map(fn(result: Result(Response(Dynamic), fetch.FetchError)) {
    result
    |> result.map_error(fn(e: fetch.FetchError) {
      case e {
        fetch.NetworkError(msg) -> "Network Error: " <> msg
        fetch.UnableToReadBody -> "Unable to read response body"
        fetch.InvalidJsonBody -> "Invalid JSON response"
      }
    })
    |> result.then(fn(response: Response(Dynamic)) {
      response.body
      |> yak_common.app_context_response_decoder()
      |> result.map_error(string.inspect)
    })
  })
}

pub opaque type Action {
  GotAppContext(Result(yak_common.AppContextResponse, String))
}

fn update(state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    GotAppContext(Ok(app_context)) -> {
      #(
        state,
        core.SharedEffect(core.GotAuthState(core.Authenticated(app_context))),
      )
    }
    GotAppContext(Error(msg)) -> {
      #(
        StateError(msg),
        core.SharedEffect(core.GotAuthState(core.AuthError(msg))),
      )
    }
  }
}

fn view(state: State) -> Element(Action) {
  case state {
    StateError(msg) -> html.p([], [element.text("Error: " <> msg)])
    _ -> html.p([], [element.text("Loading")])
  }
}
