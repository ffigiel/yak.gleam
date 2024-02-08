import gleam/io
import yak_ui/core.{
  type AppEffect, type Route, type SharedAction, PageEffect, SharedEffect,
}
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre
import lustre/effect.{type Effect}
import lustre/element
import yak_common
import yak_ui/pages/home
import yak_ui/pages/init
import yak_ui/pages/login

pub fn main() {
  let app = lustre.application(init_app, update, view)
  lustre.start(app, "[data-lustre-app]", Nil)
}

type State {
  State(
    current_page: CurrentPage,
    app_context: Option(yak_common.AppContextResponse),
  )
}

type CurrentPage {
  InitPage(init.State, core.Page(init.State, init.Action))
  LoginPage(login.State, core.Page(login.State, login.Action))
  HomePage(home.State, core.Page(home.State, home.Action))
}

pub type PageAction {
  InitAction(init.Action)
  LoginAction(login.Action)
  HomeAction(home.Action)
}

fn set_page(state: State, route: Route) -> #(State, Effect(AppAction)) {
  let #(current_page, page_effect) = case route {
    core.InitRoute -> {
      let page = init.page()
      let #(page_state, page_effect) = page.init()
      #(
        InitPage(page_state, page),
        effect_from_app_effect(page_effect, InitAction),
      )
    }
    core.LoginRoute -> {
      let page = login.page()
      let #(page_state, page_effect) = page.init()
      #(
        LoginPage(page_state, page),
        effect_from_app_effect(page_effect, LoginAction),
      )
    }
    core.HomeRoute -> {
      let page = home.page()
      let #(page_state, page_effect) = page.init()
      #(
        HomePage(page_state, page),
        effect_from_app_effect(page_effect, HomeAction),
      )
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
  }
}

fn init_app(_flags) {
  let page = init.page()
  State(current_page: InitPage(page.init().0, page), app_context: None)
  |> set_page(core.InitRoute)
}

pub type AppAction {
  GotPageAction(PageAction)
  GotSharedAction(SharedAction)
}

fn update(state: State, action: AppAction) {
  case #(state.current_page, action) {
    #(_, GotSharedAction(core.GotAppContext(ctx))) -> {
      let state = State(..state, app_context: Some(ctx))
      case ctx.user {
        _ ->
          state
          |> set_page(core.HomeRoute)

        _ ->
          state
          |> set_page(core.LoginRoute)
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
    #(InitPage(s, p), InitAction(a)) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        InitPage(new_page_state, p),
        effect_from_app_effect(page_effect, InitAction),
      )
    }
    #(LoginPage(s, p), LoginAction(a)) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        LoginPage(new_page_state, p),
        effect_from_app_effect(page_effect, LoginAction),
      )
    }
    #(HomePage(s, p), HomeAction(a)) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        HomePage(new_page_state, p),
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
    InitPage(s, p) ->
      element.map(p.view(s), fn(fx) { GotPageAction(InitAction(fx)) })
    LoginPage(s, p) ->
      element.map(p.view(s), fn(fx) { GotPageAction(LoginAction(fx)) })
    HomePage(s, p) ->
      element.map(p.view(s), fn(fx) { GotPageAction(HomeAction(fx)) })
  }
}
