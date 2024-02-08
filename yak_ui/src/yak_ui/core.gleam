import lustre/effect.{type Effect}
import lustre/element.{type Element}
import yak_common

pub type Page(state, action) {
  Page(
    init: fn() -> #(state, AppEffect(action)),
    update: fn(state, action) -> #(state, AppEffect(action)),
    view: fn(state) -> Element(action),
  )
}

pub type AppEffect(action) {
  PageEffect(Effect(action))
  SharedEffect(SharedAction)
}

pub type SharedAction {
  GotAuthState(AuthState)
}

pub type AuthState {
  AuthLoading
  AuthError(String)
  Authenticated(yak_common.AppContextResponse)
  Unauthenticated
}

pub type Route {
  InitRoute
  LoginRoute
  HomeRoute
}
