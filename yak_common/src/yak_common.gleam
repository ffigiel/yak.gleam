import gleam/json.{type Json}
import gleam/dynamic.{type Decoder}
import gleam/option.{type Option}

pub type AppContextResponse {
  AppContextResponse(user: User)
}

pub type User {
  User(email: String)
}

pub fn app_context_response_from_json(
  string: String,
) -> Result(AppContextResponse, json.DecodeError) {
  json.decode(from: string, using: app_context_response_decoder())
}

pub fn app_context_response_decoder() -> Decoder(AppContextResponse) {
  dynamic.decode1(AppContextResponse, dynamic.field("user", user_decoder()))
}

fn user_decoder() -> Decoder(User) {
  dynamic.decode1(User, dynamic.field("email", dynamic.string))
}

pub fn app_context_response_to_json(obj: AppContextResponse) -> String {
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

pub type LoginResponse {
  LoginResponse(email: String)
}

pub fn login_response_from_json(
  string: String,
) -> Result(LoginResponse, json.DecodeError) {
  let decoder =
    dynamic.decode1(LoginResponse, dynamic.field("email", dynamic.string))
  json.decode(from: string, using: decoder)
}

pub fn login_response_to_json(obj: LoginResponse) -> String {
  json.object([#("email", json.string(obj.email))])
  |> json.to_string
}
