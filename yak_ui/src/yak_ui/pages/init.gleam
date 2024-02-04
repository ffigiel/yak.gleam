import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type Page, Page}

pub fn page() -> Page(State, Action) {
  Page(init: init, update: update, view: view)
}

pub opaque type State {
  State(loading: Bool)
}

fn init() {
  #(State(loading: True), effect.none())
}

pub opaque type Action {
  Todo
}

fn update(state: State, action: Action) -> #(State, Effect(Action)) {
  case action {
    Todo -> #(state, effect.none())
  }
}

fn view(_state: State) -> Element(Action) {
  html.p([], [element.text("Init")])
}
