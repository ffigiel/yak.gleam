import gleam/dynamic.{Dynamic}
import gleam/fetch
import gleam/http
import gleam/http/request
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import yak_common

pub fn main() {
  let app = lustre.application(init_state, update, view)
  lustre.start(app, "[data-lustre-app]", Nil)
}

type State {
  State(email: String, password: String)
}

fn init_state(_flags) {
  #(State(email: "", password: ""), effect.none())
}

pub type Action {
  GotEmail(value: String)
  GotPassword(value: String)
  SubmittedForm
  Todo
}

fn update(state: State, action: Action) {
  case action {
    GotEmail(value) -> #(State(..state, email: value), effect.none())
    GotPassword(value) -> #(State(..state, password: value), effect.none())
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
        fetch.send(request)
        dispatch(Todo)
      },
    )
    Todo -> #(state, effect.none())
  }
}

fn view(state: State) {
  html.form(
    [handle_submit(SubmittedForm)],
    [
      html.p(
        [],
        [
          html.label(
            [],
            [
              html.span([], [element.text("Email")]),
              html.input([
                event.on_input(GotEmail),
                attribute.value(dynamic.from(state.email)),
                attribute.type_("email"),
              ]),
            ],
          ),
        ],
      ),
      html.p(
        [],
        [
          html.label(
            [],
            [
              html.span([], [element.text("Password")]),
              html.input([
                event.on_input(GotPassword),
                attribute.value(dynamic.from(state.password)),
                attribute.type_("password"),
              ]),
            ],
          ),
        ],
      ),
      html.p([], [html.button([], [element.text("Submit")])]),
    ],
  )
}

fn handle_submit(msg) -> attribute.Attribute(a) {
  event.on(
    "submit",
    fn(event) {
      prevent_default_on_event(event)
      Ok(msg)
    },
  )
}

@external(javascript, "/ffi.mjs", "preventDefaultOnEvent")
fn prevent_default_on_event(a: Dynamic) -> Nil
