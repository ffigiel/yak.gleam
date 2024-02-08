import gleam/io
import gleam/option.{type Option, None, Some}
import lustre
import lustre/effect.{type Effect}
import lustre/element
import yak_ui/pages/login
import yak_ui/pages/home
import yak_common
import yak_ui/pages/init
import yak_ui/core.{type AppEffect, type SharedAction, PageEffect, SharedEffect}

pub fn main() {
  let app = lustre.application(init_state, update, view)
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

fn init_state(_flags) {
  let page = init.page()
  let #(page_state, page_effect) = page.init()
  #(
    State(current_page: InitPage(page_state, page), app_context: None),
    effect_from_app_effect(page_effect, InitAction),
  )
}

pub type AppAction {
  GotPageAction(PageAction)
  GotSharedAction(SharedAction)
}

pub type PageAction {
  InitAction(init.Action)
  LoginAction(login.Action)
  HomeAction(home.Action)
}

fn update(state: State, action: AppAction) {
  case #(state.current_page, action) {
    #(_, GotSharedAction(core.GotAppContext(ctx))) -> {
      let state = State(..state, app_context: Some(ctx))
      case ctx.user {
        Some(_) -> {
          let page = home.page()
          let #(page_state, page_effect) = page.init()
          #(
            State(..state, current_page: HomePage(page_state, page)),
            effect_from_app_effect(page_effect, HomeAction),
          )
        }
        None -> {
          let page = init.page()
          let #(page_state, page_effect) = page.init()
          #(
            State(..state, current_page: InitPage(page_state, page)),
            effect_from_app_effect(page_effect, InitAction),
          )
        }
      }
    }
    #(InitPage(s, p), GotPageAction(InitAction(a))) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        State(..state, current_page: InitPage(new_page_state, p)),
        effect_from_app_effect(page_effect, InitAction),
      )
    }
    #(InitPage(_, _), GotPageAction(_)) -> {
      io.debug("Incompatible state")
      #(state, effect.none())
    }
    #(LoginPage(s, p), GotPageAction(LoginAction(a))) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        State(..state, current_page: LoginPage(new_page_state, p)),
        effect_from_app_effect(page_effect, LoginAction),
      )
    }
    #(LoginPage(_, _), _) -> {
      io.debug("Incompatible state")
      #(state, effect.none())
    }
    #(HomePage(s, p), GotPageAction(HomeAction(a))) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        State(..state, current_page: HomePage(new_page_state, p)),
        effect_from_app_effect(page_effect, HomeAction),
      )
    }
    #(HomePage(_, _), _) -> {
      io.debug("Incompatible state")
      #(state, effect.none())
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
