import lustre/effect.{type Effect}
import lustre/element.{type Element}
import yak_common

pub type Page(state, action) {
  Page(
    init: fn(SharedState) -> #(state, AppEffect(action)),
    update: fn(SharedState, state, action) -> #(state, AppEffect(action)),
    view: fn(SharedState, state) -> Element(action),
  )
}

pub type AppEffect(action) {
  PageEffect(Effect(action))
  SharedEffect(SharedAction)
  NoEffect
}

pub type SharedAction {
  GotAuthState(AuthState)
}

pub type SharedState {
  SharedState(auth: AuthState)
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
