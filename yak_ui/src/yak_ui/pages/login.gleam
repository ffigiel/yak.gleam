import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import gleam/option.{type Option}
import gleam/dynamic
import yak_common
import yak_ui/ffi
import yak_ui/core.{type AppEffect, type Page, Page}
import gleam/javascript/promise
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
  GotLoginResponse(Result(yak_common.AppContextResponse, String))
}

fn update(_shared, state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    GotEmail(value) -> #(State(..state, email: value), core.NoEffect)
    GotPassword(value) -> #(State(..state, password: value), core.NoEffect)
    SubmittedLoginForm -> #(
      State(..state, logging_in: True, login_error: option.None),
      core.PageEffect({
        use dispatch <- effect.from
        api.send_login_request(yak_common.LoginRequest(
          email: state.email,
          password: state.password,
        ))
        |> promise.map(fn(result) { dispatch(GotLoginResponse(result)) })
        Nil
      }),
    )
    GotLoginResponse(Ok(app_context)) -> #(
      state,
      core.SharedEffect(core.GotAuthState(core.Authenticated(app_context))),
    )
    GotLoginResponse(Error(msg)) -> #(
      State(..state, logging_in: False, login_error: option.Some(msg)),
      core.NoEffect,
    )
  }
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
