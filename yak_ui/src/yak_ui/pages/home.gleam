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
  SharedAction(core.SharedAction)
}

fn update(_shared, state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    SharedAction(a) -> #(state, core.SharedEffect(a))
  }
}

fn view(shared: core.SharedState, _state: State) -> Element(Action) {
  core.layout(shared, SharedAction, [html.h1([], [element.text("Home page")])])
}
