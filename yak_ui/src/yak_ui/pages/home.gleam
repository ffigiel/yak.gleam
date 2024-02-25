import lustre/element.{type Element}
import yak_ui/ffi
import lustre/event
import gleam/result
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/fetch
import gleam/http
import gleam/http/request
import lustre/effect
import lustre/element/html
import lustre/attribute
import gleam/option.{type Option}
import yak_ui/core.{type AppEffect, type Page, Page}
import yak_ui/api

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

fn view(shared: core.SharedState, state: State) -> Element(Action) {
  let assert core.Authenticated(auth) = shared.auth
  core.layout(shared, SharedAction, [html.h1([], [element.text("Home page")])])
}
