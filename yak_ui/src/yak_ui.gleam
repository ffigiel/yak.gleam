import gleam/io
import lustre
import lustre/effect
import lustre/element
import yak_ui/pages/login
import yak_ui/pages/init
import yak_ui/core

pub fn main() {
  let app = lustre.application(init_state, update, view)
  lustre.start(app, "[data-lustre-app]", Nil)
}

type State {
  State(current_page: CurrentPage, shared_state: Nil)
}

type CurrentPage {
  InitPage(init.State, core.Page(init.State, init.Action))
  LoginPage(login.State, core.Page(login.State, login.Action))
}

fn init_state(_flags) {
  let page = init.page()
  let #(page_state, page_effect) = page.init()
  #(
    State(current_page: InitPage(page_state, page), shared_state: Nil),
    effect.map(page_effect, fn(fx) { PageAction(InitAction(fx)) }),
  )
}

pub type Action {
  PageAction(PageAction)
  Todo
}

pub type PageAction {
  InitAction(init.Action)
  LoginAction(login.Action)
}

fn update(state: State, action: Action) {
  case #(state.current_page, action) {
    #(InitPage(s, p), PageAction(InitAction(a))) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        State(..state, current_page: InitPage(new_page_state, p)),
        effect.map(page_effect, fn(fx) { PageAction(InitAction(fx)) }),
      )
    }
    #(InitPage(_, _), _) -> {
      io.debug("Incompatible state")
      #(state, effect.none())
    }
    #(LoginPage(s, p), PageAction(LoginAction(a))) -> {
      let #(new_page_state, page_effect) = p.update(s, a)
      #(
        State(..state, current_page: LoginPage(new_page_state, p)),
        effect.map(page_effect, fn(fx) { PageAction(LoginAction(fx)) }),
      )
    }
    #(LoginPage(_, _), _) -> {
      io.debug("Incompatible state")
      #(state, effect.none())
    }
  }
}

fn view(state: State) {
  case state.current_page {
    InitPage(s, p) ->
      element.map(p.view(s), fn(fx) { PageAction(InitAction(fx)) })
    LoginPage(s, p) ->
      element.map(p.view(s), fn(fx) { PageAction(LoginAction(fx)) })
  }
}
