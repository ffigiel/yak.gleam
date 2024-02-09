import gleam/dynamic
import gleam/fetch
import gleam/io
import gleam/http
import gleam/http/request
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import yak_common
import yak_ui/ffi
import yak_ui/core.{type AppEffect, type Page, Page}
import gleam/javascript/promise

pub fn page() -> Page(State, Action) {
  Page(init: init, update: update, view: view)
}

pub opaque type State {
  State(email: String, password: String)
}

fn init() {
  #(State(email: "", password: ""), core.NoEffect)
}

pub opaque type Action {
  GotEmail(value: String)
  GotPassword(value: String)
  SubmittedForm
  SubmittedLogoutForm
  Todo
}

fn update(state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    GotEmail(value) -> #(State(..state, email: value), core.NoEffect)
    GotPassword(value) -> #(State(..state, password: value), core.NoEffect)
    SubmittedForm -> #(
      state,
      {
        use dispatch <- effect.from
        let body =
          yak_common.LoginRequest(email: state.email, password: state.password)
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
        let response =
          request
          |> fetch.raw_send_with_options(options)
          |> promise.try_await(fn(resp) {
            promise.resolve(Ok(fetch.from_fetch_response(resp)))
          })
        io.debug(response)
        dispatch(Todo)
      }
      |> core.PageEffect,
    )
    SubmittedLogoutForm -> #(
      state,
      {
        use dispatch <- effect.from
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
        let response =
          request
          |> fetch.raw_send_with_options(options)
          |> promise.try_await(fn(resp) {
            promise.resolve(Ok(fetch.from_fetch_response(resp)))
          })
        io.debug(response)
        dispatch(Todo)
      }
      |> core.PageEffect,
    )
    Todo -> #(state, core.NoEffect)
  }
}

fn view(state: State) -> Element(Action) {
  html.div([], [view_logout_form(state), view_login_form(state)])
}

fn view_logout_form(_state: State) {
  html.form([handle_submit(SubmittedLogoutForm)], [
    html.p([], [html.button([], [element.text("Logout")])]),
  ])
}

fn view_login_form(state: State) {
  html.form([handle_submit(SubmittedForm)], [
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
    html.p([], [html.button([], [element.text("Submit")])]),
  ])
}

fn handle_submit(msg) -> attribute.Attribute(a) {
  event.on("submit", fn(event) {
    ffi.prevent_default_on_event(event)
    Ok(msg)
  })
}
