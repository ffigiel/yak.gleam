import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type AppEffect, type Page, Page}

pub fn page() -> Page(State, Action) {
  Page(init: init, update: update, view: view)
}

pub opaque type State {
  State
}

fn init() {
  #(State, core.PageEffect(effect.none()))
}

pub opaque type Action {
  Todo
}

fn update(state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    Todo -> #(state, core.PageEffect(effect.none()))
  }
}

fn view(state: State) -> Element(Action) {
  html.p([], [element.text("Welcome, user")])
}
