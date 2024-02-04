import lustre/effect.{type Effect}
import lustre/element.{type Element}

pub type Page(state, action) {
  Page(
    init: fn() -> #(state, Effect(action)),
    update: fn(state, action) -> #(state, Effect(action)),
    view: fn(state) -> Element(action),
  )
}
