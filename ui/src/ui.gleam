import gleam/dynamic.{Dynamic}
import gleam/fetch
import gleam/http
import gleam/http/request
import lustre
import lustre/attribute
import lustre/cmd
import lustre/element
import lustre/event
import yak/shared

pub fn main() {
  let app = lustre.application(#(init_state(), cmd.none()), update, render)
  lustre.start(app, "#app")
}

type State {
  State(email: String, password: String)
}

fn init_state() {
  State(email: "", password: "")
}

pub type Action {
  GotEmail(value: String)
  GotPassword(value: String)
  SubmittedForm
  Todo
}

fn update(state: State, action: Action) {
  case action {
    GotEmail(value) -> #(State(..state, email: value), cmd.none())
    GotPassword(value) -> #(State(..state, password: value), cmd.none())
    SubmittedForm -> #(
      state,
      {
        use dispatch <- cmd.from
        let body =
          shared.LoginRequest(email: state.email, password: state.password)
          |> shared.login_request_to_json
        let request =
          request.new()
          |> request.set_method(http.Post)
          |> request.set_scheme(http.Http)
          |> request.set_host("localhost:3000")
          |> request.set_path("login")
          |> request.set_body(body)
        fetch.send(request)
        dispatch(Todo)
      },
    )
    Todo -> #(state, cmd.none())
  }
}

fn render(state: State) {
  element.form(
    [handle_submit(SubmittedForm)],
    [
      element.p(
        [],
        [
          element.label(
            [],
            [
              element.span([], [element.text("Email")]),
              element.input([
                event.on_input(GotEmail),
                attribute.value(dynamic.from(state.email)),
                attribute.type_("email"),
              ]),
            ],
          ),
        ],
      ),
      element.p(
        [],
        [
          element.label(
            [],
            [
              element.span([], [element.text("Password")]),
              element.input([
                event.on_input(GotPassword),
                attribute.value(dynamic.from(state.password)),
                attribute.type_("password"),
              ]),
            ],
          ),
        ],
      ),
      element.p([], [element.button([], [element.text("Submit")])]),
    ],
  )
}

fn handle_submit(a) -> attribute.Attribute(a) {
  use event, dispatch <- event.on("submit")
  prevent_default_on_event(event)
  dispatch(a)
}

external fn prevent_default_on_event(Dynamic) -> Nil =
  "" "preventDefaultOnEvent"
