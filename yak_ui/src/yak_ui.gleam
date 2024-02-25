import gleam/io
import gleam/javascript/promise
import yak_ui/core.{type AppEffect, type Route, type SharedAction}
import gleam/string
import gleam/option
import lustre
import lustre/effect.{type Effect}
import lustre/element
import yak_ui/pages/home
import yak_ui/pages/init
import yak_ui/pages/login
import yak_ui/api
import yak_ui/ffi

pub fn main() {
  let app = lustre.application(init_app, update, view)
  lustre.start(app, "[data-lustre-app]", Nil)
}

type State {
  State(page: PageState, shared: core.SharedState)
}

type PageState {
  InitState(init.State)
  LoginState(login.State)
  HomeState(home.State)
}

pub type PageAction {
  InitAction(init.Action)
  LoginAction(login.Action)
  HomeAction(home.Action)
}

fn set_page(state: State, route: Route) -> #(State, Effect(AppAction)) {
  case route {
    core.InitRoute -> {
      let #(page_state, page_effect) = init.page.init(state.shared)
      #(
        State(..state, page: InitState(page_state)),
        effect_from_app_effect(page_effect, InitAction),
      )
    }
    core.LoginRoute -> {
      let #(page_state, page_effect) = login.page.init(state.shared)
      #(
        State(..state, page: LoginState(page_state)),
        effect_from_app_effect(page_effect, LoginAction),
      )
    }
    core.HomeRoute -> {
      let #(page_state, page_effect) = home.page.init(state.shared)
      #(
        State(..state, page: HomeState(page_state)),
        effect_from_app_effect(page_effect, HomeAction),
      )
    }
  }
}

fn effect_from_app_effect(
  fx: AppEffect(action),
  page_action_ctor: fn(action) -> PageAction,
) -> Effect(AppAction) {
  case fx {
    core.PageEffect(fx) ->
      effect.map(fx, fn(a) { GotPageAction(page_action_ctor(a)) })
    core.SharedEffect(a) ->
      effect.from(fn(dispatch) { dispatch(GotSharedAction(a)) })
    core.NoEffect -> effect.none()
  }
}

fn init_app(_flags) {
  let shared =
    core.SharedState(
      auth: core.AuthLoading,
      logging_out: False,
      logout_error: option.None,
    )
  State(page: InitState(init.page.init(shared).0), shared: shared)
  |> set_page(core.InitRoute)
}

pub type AppAction {
  GotPageAction(PageAction)
  GotSharedAction(SharedAction)
  GotNavigation(Route)
}

fn update(state: State, action: AppAction) {
  case #(state.page, action) {
    #(page, GotPageAction(page_action)) -> {
      let #(page, effect) = update_page(state.shared, page, page_action)
      #(State(..state, page: page), effect)
    }
    #(_, GotSharedAction(shared_action)) -> {
      let #(new_shared_state, app_effect) =
        update_shared(state.shared, shared_action)
      #(State(..state, shared: new_shared_state), app_effect)
    }
    #(_, GotNavigation(route)) -> set_page(state, route)
  }
}

fn update_shared(
  state: core.SharedState,
  action: core.SharedAction,
) -> #(core.SharedState, Effect(AppAction)) {
  case action {
    core.GotAuthState(auth_state) -> {
      let effect = case auth_state {
        core.Authenticated(_) ->
          effect.from(fn(dispatch) { dispatch(GotNavigation(core.HomeRoute)) })
        core.Unauthenticated ->
          effect.from(fn(dispatch) { dispatch(GotNavigation(core.LoginRoute)) })
        // Other states are handled on the Init page
        _ -> effect.none()
      }
      #(core.SharedState(..state, auth: auth_state), effect)
    }
    core.LogoutClicked -> #(
      core.SharedState(..state, logging_out: True, logout_error: option.None),
      {
        use dispatch <- effect.from
        api.send_logout_request()
        |> promise.map(fn(result) {
          dispatch(GotSharedAction(core.GotLogoutResponse(result)))
        })
        Nil
      },
    )
    core.GotLogoutResponse(Ok(Nil)) -> #(state, {
      use _ <- effect.from
      ffi.reload_page()
      Nil
    })
    core.GotLogoutResponse(Error(msg)) -> #(
      core.SharedState(
        ..state,
        logging_out: False,
        logout_error: option.Some(msg),
      ),
      effect.none(),
    )
  }
}

fn update_page(shared: core.SharedState, page: PageState, action: PageAction) {
  case #(page, action) {
    #(InitState(s), InitAction(a)) -> {
      let #(new_page_state, page_effect) = init.page.update(shared, s, a)
      #(
        InitState(new_page_state),
        effect_from_app_effect(page_effect, InitAction),
      )
    }
    #(LoginState(s), LoginAction(a)) -> {
      let #(new_page_state, page_effect) = login.page.update(shared, s, a)
      #(
        LoginState(new_page_state),
        effect_from_app_effect(page_effect, LoginAction),
      )
    }
    #(HomeState(s), HomeAction(a)) -> {
      let #(new_page_state, page_effect) = home.page.update(shared, s, a)
      #(
        HomeState(new_page_state),
        effect_from_app_effect(page_effect, HomeAction),
      )
    }
    invalid -> {
      io.debug("Invalid state/action: " <> string.inspect(invalid))
      #(page, effect.none())
    }
  }
}

fn view(state: State) {
  case state.page {
    InitState(s) ->
      element.map(init.page.view(state.shared, s), fn(fx) {
        GotPageAction(InitAction(fx))
      })
    LoginState(s) ->
      element.map(login.page.view(state.shared, s), fn(fx) {
        GotPageAction(LoginAction(fx))
      })
    HomeState(s) ->
      element.map(home.page.view(state.shared, s), fn(fx) {
        GotPageAction(HomeAction(fx))
      })
  }
}
