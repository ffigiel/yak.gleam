import gleam/json.{type Json}
import gleam/dynamic.{type Decoder}

pub type AppContext {
  AppContext(user: User)
}

pub type User {
  User(email: String)
}

pub fn app_context_from_json(
  string: String,
) -> Result(AppContext, json.DecodeError) {
  json.decode(from: string, using: app_context_decoder())
}

pub fn app_context_decoder() -> Decoder(AppContext) {
  dynamic.decode1(AppContext, dynamic.field("user", user_decoder()))
}

fn user_decoder() -> Decoder(User) {
  dynamic.decode1(User, dynamic.field("email", dynamic.string))
}

pub fn app_context_to_json(obj: AppContext) -> String {
  json.object([#("user", user_to_json(obj.user))])
  |> json.to_string
}

fn user_to_json(obj: User) -> Json {
  json.object([#("email", json.string(obj.email))])
}

pub type LoginRequest {
  LoginRequest(email: String, password: String)
}

pub fn login_request_from_json(
  string: String,
) -> Result(LoginRequest, json.DecodeError) {
  let decoder =
    dynamic.decode2(
      LoginRequest,
      dynamic.field("email", dynamic.string),
      dynamic.field("password", dynamic.string),
    )
  json.decode(from: string, using: decoder)
}

pub fn login_request_to_json(obj: LoginRequest) -> String {
  json.object([
    #("email", json.string(obj.email)),
    #("password", json.string(obj.password)),
  ])
  |> json.to_string
}
