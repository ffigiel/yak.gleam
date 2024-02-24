import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type AppEffect, type Page, Page}
import yak_ui/api
import gleam/javascript/promise

pub const page = Page(init: init, update: update, view: view)

pub opaque type State {
  StateLoading
  StateError(String)
}

fn init(_shared) {
  let effect = {
    use dispatch <- effect.from
    api.fetch_app_context()
    |> promise.tap(fn(result) {
      GotAuthState(result)
      |> dispatch
    })
    Nil
  }
  #(StateLoading, core.PageEffect(effect))
}

pub opaque type Action {
  GotAuthState(core.AuthState)
}

fn update(_shared, state: State, action: Action) -> #(State, AppEffect(Action)) {
  case action {
    GotAuthState(auth_state) -> {
      let fx = core.SharedEffect(core.GotAuthState(auth_state))
      case auth_state {
        core.AuthError(msg) -> #(StateError(msg), fx)
        _ -> #(state, fx)
      }
    }
  }
}

fn view(_shared, state: State) -> Element(Action) {
  case state {
    StateError(msg) -> html.p([], [element.text("Error: " <> msg)])
    _ -> html.p([], [element.text("Loading")])
  }
}
