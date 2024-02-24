import gleam/dynamic
import gleam/fetch
import gleam/int
import gleam/result
import gleam/http
import gleam/http/request
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import gleam/option.{type Option}
import yak_common
import yak_ui/ffi
import yak_ui/core.{type AppEffect, type Page, Page}
import gleam/javascript/promise.{type Promise}
import yak_ui/api

pub const page = Page(init: init, update: update, view: view)

pub opaque type State {
  State(
    email: String,
    password: String,
    logging_in: Bool,
    login_error: Option(String),
  )
}

fn init(_shared) {
  #(
    State(email: "", password: "", logging_in: False, login_error: option.None),
    core.NoEffect,
  )
}

pub opaque type Action {
  GotEmail(value: String)
  GotPassword(value: String)
  SubmittedLoginForm
  GotLoginResponse(Result(Nil, String))
}

fn update(_shared, state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    GotEmail(value) -> #(State(..state, email: value), core.NoEffect)
    GotPassword(value) -> #(State(..state, password: value), core.NoEffect)
    SubmittedLoginForm -> #(
      State(..state, logging_in: True, login_error: option.None),
      core.PageEffect({
        use dispatch <- effect.from
        send_login_request(yak_common.LoginRequest(
          email: state.email,
          password: state.password,
        ))
        |> promise.map(fn(result) { dispatch(GotLoginResponse(result)) })
        Nil
      }),
    )
    GotLoginResponse(Ok(Nil)) -> #(
      state,
      core.PageEffect({
        use _ <- effect.from
        ffi.reload_page()
        Nil
      }),
    )
    GotLoginResponse(Error(msg)) -> #(
      State(..state, logging_in: False, login_error: option.Some(msg)),
      core.NoEffect,
    )
  }
}

fn send_login_request(
  request: yak_common.LoginRequest,
) -> Promise(Result(Nil, String)) {
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

fn view(_shared, state: State) -> Element(Action) {
  html.div([], [view_login_form(state)])
}

fn view_login_form(state: State) {
  html.form([handle_submit(SubmittedLoginForm)], [
    html.p([], [
      html.label([], [
        html.span([], [element.text("Email")]),
        html.input([
          event.on_input(GotEmail),
          attribute.value(dynamic.from(state.email)),
          attribute.type_("email"),
        ]),
      ]),
    ]),
    html.p([], [
      html.label([], [
        html.span([], [element.text("Password")]),
        html.input([
          event.on_input(GotPassword),
          attribute.value(dynamic.from(state.password)),
          attribute.type_("password"),
        ]),
      ]),
    ]),
    html.div([], [
      html.div([], [
        html.button([attribute.disabled(state.logging_in)], [
          element.text("Submit"),
        ]),
      ]),
      case state.login_error {
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
