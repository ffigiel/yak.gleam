import yak/middleware
import gleam/bit_string
import gleam/bit_builder
import gleam/http/request
import gleam/http/response
import gleam/http.{Get}
import gleam/pgo
import yak/app_request.{AppRequest}

pub fn stack(db: pgo.Connection) {
  // middlewares are executed from bottom to top
  service
  |> middleware.log
  |> middleware.app_request(db)
}

fn service(request: AppRequest) {
  let path = request.path_segments(request.http)
  case request.http.method, path {
    Get, [] -> hello(request)
    _, _ -> not_found(request)
  }
}

fn hello(request) {
  let body =
    "Hello world"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(200)
  |> response.set_body(body)
}

fn not_found(_request) {
  let body =
    "Not Found"
    |> bit_string.from_string
    |> bit_builder.from_bit_string
  response.new(404)
  |> response.set_body(body)
}
