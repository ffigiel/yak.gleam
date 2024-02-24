import lustre/element.{type Element}
import yak_ui/ffi
import lustre/event
import gleam/result
import gleam/io
import gleam/int
import gleam/string
import gleam/javascript/promise.{type Promise}
import gleam/fetch
import gleam/http
import gleam/http/request
import lustre/effect
import lustre/element/html
import lustre/attribute
import gleam/option.{type Option}
import yak_ui/core.{type AppEffect, type Page, Page}
import yak_ui/api

pub const page = Page(init: init, update: update, view: view)

pub opaque type State {
  State(logging_out: Bool, logout_error: Option(String))
}

fn init(_shared) {
  #(State(logging_out: False, logout_error: option.None), core.NoEffect)
}

pub opaque type Action {
  SubmittedLogoutForm
  GotLogoutResponse(Result(Nil, String))
}

fn update(_shared, state: State, action: Action) -> #(State, AppEffect(Action)) {
  io.debug(action)
  case action {
    SubmittedLogoutForm -> #(
      state,
      core.PageEffect({
        use dispatch <- effect.from
        send_logout_request()
        |> promise.map(fn(result) { dispatch(GotLogoutResponse(result)) })
        Nil
      }),
    )
    GotLogoutResponse(Ok(Nil)) -> #(
      State(..state, logging_out: False),
      core.PageEffect({
        use _ <- effect.from
        ffi.reload_page()
        Nil
      }),
    )
    GotLogoutResponse(Error(err)) -> #(
      State(..state, logging_out: False, logout_error: option.Some(err)),
      core.PageEffect({
        use _ <- effect.from
        io.debug(err)
        Nil
      }),
    )
  }
}

fn send_logout_request() -> Promise(Result(Nil, String)) {
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
      Error(err) -> promise.resolve(Error(api.fetch_error_to_string(err)))
    }
  })
}

fn view(shared: core.SharedState, state: State) -> Element(Action) {
  let assert core.Authenticated(auth) = shared.auth
  html.div([], [
    html.p([], [element.text("Welcome, " <> auth.user.email)]),
    view_logout_form(state),
  ])
}

fn view_logout_form(state: State) {
  html.form([handle_submit(SubmittedLogoutForm)], [
    html.div([], [
      html.div([], [
        html.button([attribute.disabled(state.logging_out)], [
          element.text("Logout"),
        ]),
      ]),
      case state.logout_error {
        option.Some(msg) -> html.span([], [element.text(msg)])
        option.None -> element.none()
      },
    ]),
  ])
}

fn handle_submit(msg) -> attribute.Attribute(a) {
  event.on("submit", fn(event) {
    ffi.prevent_default_on_event(event)
    Ok(msg)
  })
}
