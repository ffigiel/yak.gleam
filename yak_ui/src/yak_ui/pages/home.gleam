import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type AppEffect, type Page, Page}

pub const page = Page(init: init, update: update, view: view)

pub opaque type State {
  State
}

fn init(_shared) {
  #(State, core.NoEffect)
}

pub opaque type Action {
  Todo
}

fn update(_shared, state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    Todo -> #(state, core.NoEffect)
  }
}

fn view(shared: core.SharedState, _state: State) -> Element(Action) {
  let assert core.Authenticated(auth) = shared.auth
  html.p([], [element.text("Welcome, " <> auth.user.email)])
}
