import gleam/dynamic
import gleam/fetch
import gleam/io
import gleam/http
import gleam/http/request
import lustre/attribute
import lustre/effect
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import yak_common
import yak_ui/ffi
import yak_ui/core.{type AppEffect, type Page, Page}
import gleam/javascript/promise

pub fn page() -> Page(State, Action) {
  Page(init: init, update: update, view: view)
}

pub opaque type State {
  State(email: String, password: String)
}

fn init() {
  #(State(email: "", password: ""), core.PageEffect(effect.none()))
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
