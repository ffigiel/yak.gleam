import gleam/json
import gleam/dynamic

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
