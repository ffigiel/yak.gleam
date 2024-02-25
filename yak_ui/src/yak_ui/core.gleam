import lustre/effect.{type Effect}
import yak_ui/ffi
import lustre/event
import lustre/element/html
import lustre/attribute.{type Attribute}
import gleam/option.{type Option}
import lustre/element.{type Element}
import yak_common

pub type Page(state, action) {
  Page(
    init: fn(SharedState) -> #(state, AppEffect(action)),
    update: fn(SharedState, state, action) -> #(state, AppEffect(action)),
    view: fn(SharedState, state) -> Element(action),
  )
}

pub type AppEffect(action) {
  PageEffect(Effect(action))
  SharedEffect(SharedAction)
  NoEffect
}

pub type SharedAction {
  GotAuthState(AuthState)
  LogoutClicked
  GotLogoutResponse(Result(Nil, String))
}

pub type SharedState {
  SharedState(auth: AuthState, logging_out: Bool, logout_error: Option(String))
}

pub type AuthState {
  AuthLoading
  AuthError(String)
  Authenticated(yak_common.AppContextResponse)
  Unauthenticated
}

pub type Route {
  InitRoute
  LoginRoute
  HomeRoute
}

pub fn layout(
  shared_state: SharedState,
  from_shared_action: fn(SharedAction) -> a,
  contents: List(Element(a)),
) -> Element(a) {
  case shared_state.auth {
    Authenticated(app_context) ->
      authenticated_layout(
        app_context,
        shared_state,
        from_shared_action,
        contents,
      )
    _ -> anonymous_layout(shared_state, from_shared_action, contents)
  }
}

fn anonymous_layout(
  shared_state: SharedState,
  from_shared_action: fn(SharedAction) -> a,
  contents: List(Element(a)),
) {
  html.div([], [
    html.nav([], [element.text("Welcome! Please log in")]),
    html.main([], contents),
  ])
}

fn authenticated_layout(
  app_context: yak_common.AppContextResponse,
  shared_state: SharedState,
  from_shared_action: fn(SharedAction) -> a,
  contents: List(Element(a)),
) {
  html.div([], [
    html.nav(
      [
        attribute.style([
          #("display", "flex"),
          #("align-items", "center"),
          #("gap", "1rem"),
        ]),
      ],
      [
        html.p([], [element.text("Welcome, " <> app_context.user.email)]),
        view_logout_form(shared_state)
          |> element.map(from_shared_action),
      ],
    ),
    html.main([], contents),
  ])
}

fn view_logout_form(state: SharedState) {
  html.form([handle_submit(LogoutClicked)], [
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
