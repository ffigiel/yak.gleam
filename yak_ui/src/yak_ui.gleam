import gleam/io
import yak_ui/core.{
  type AppEffect, type Route, type SharedAction, NoEffect, PageEffect,
  SharedEffect,
}
import gleam/string
import lustre
import lustre/effect.{type Effect}
import lustre/element
import yak_ui/pages/home
import yak_ui/pages/init
import yak_ui/pages/login

pub fn main() {
  let app = lustre.application(init_app, update, view)
  lustre.start(app, "[data-lustre-app]", Nil)
}

type State {
  State(current_page: CurrentPage, auth_state: core.AuthState)
}

type CurrentPage {
  InitPage(init.State)
  LoginPage(login.State)
  HomePage(home.State)
}

pub type PageAction {
  InitAction(init.Action)
  LoginAction(login.Action)
  HomeAction(home.Action)
}

fn set_page(state: State, route: Route) -> #(State, Effect(AppAction)) {
  let #(current_page, page_effect) = case route {
    core.InitRoute -> {
      let page = init.page
      let #(page_state, page_effect) = page.init()
      #(InitPage(page_state), effect_from_app_effect(page_effect, InitAction))
    }
    core.LoginRoute -> {
      let page = login.page
      let #(page_state, page_effect) = page.init()
      #(LoginPage(page_state), effect_from_app_effect(page_effect, LoginAction))
    }
    core.HomeRoute -> {
      let page = home.page
      let #(page_state, page_effect) = page.init()
      #(HomePage(page_state), effect_from_app_effect(page_effect, HomeAction))
    }
  }
  #(State(..state, current_page: current_page), page_effect)
}

fn effect_from_app_effect(
  fx: AppEffect(action),
  page_action_ctor: fn(action) -> PageAction,
) -> Effect(AppAction) {
  case fx {
    PageEffect(fx) ->
      effect.map(fx, fn(a) { GotPageAction(page_action_ctor(a)) })
    SharedEffect(a) ->
      effect.from(fn(dispatch) { dispatch(GotSharedAction(a)) })
    NoEffect -> effect.none()
  }
}

fn init_app(_flags) {
  State(
    current_page: InitPage(init.page.init().0),
    auth_state: core.AuthLoading,
  )
  |> set_page(core.InitRoute)
}

pub type AppAction {
  GotPageAction(PageAction)
  GotSharedAction(SharedAction)
}

fn update(state: State, action: AppAction) {
  case #(state.current_page, action) {
    #(_, GotSharedAction(core.GotAuthState(auth_state))) -> {
      let state = State(..state, auth_state: auth_state)
      case auth_state {
        core.Authenticated(_) -> set_page(state, core.HomeRoute)
        core.Unauthenticated -> set_page(state, core.LoginRoute)
        // Other states are handled on the Init page
        _ -> #(state, effect.none())
      }
    }
    #(page, GotPageAction(page_action)) -> {
      let #(current_page, effect) = update_page(page, page_action)
      #(State(..state, current_page: current_page), effect)
    }
  }
}

fn update_page(current_state: CurrentPage, action: PageAction) {
  case #(current_state, action) {
    #(InitPage(s), InitAction(a)) -> {
      let #(new_page_state, page_effect) = init.page.update(s, a)
      #(
        InitPage(new_page_state),
        effect_from_app_effect(page_effect, InitAction),
      )
    }
    #(LoginPage(s), LoginAction(a)) -> {
      let #(new_page_state, page_effect) = login.page.update(s, a)
      #(
        LoginPage(new_page_state),
        effect_from_app_effect(page_effect, LoginAction),
      )
    }
    #(HomePage(s), HomeAction(a)) -> {
      let #(new_page_state, page_effect) = home.page.update(s, a)
      #(
        HomePage(new_page_state),
        effect_from_app_effect(page_effect, HomeAction),
      )
    }
    invalid -> {
      io.debug("Invalid state/action: " <> string.inspect(invalid))
      #(current_state, effect.none())
    }
  }
}

fn view(state: State) {
  case state.current_page {
    InitPage(s) ->
      element.map(init.page.view(s), fn(fx) { GotPageAction(InitAction(fx)) })
    LoginPage(s) ->
      element.map(login.page.view(s), fn(fx) { GotPageAction(LoginAction(fx)) })
    HomePage(s) ->
      element.map(home.page.view(s), fn(fx) { GotPageAction(HomeAction(fx)) })
  }
}
