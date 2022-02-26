import yak/middleware
import gleam/bit_string
import gleam/bit_builder
import gleam/http/service
import gleam/http/request
import gleam/http/response
import gleam/http.{Get}

pub fn stack() {
  // middlewares are executed from bottom to top
  service
  |> service.map_response_body(bit_builder.from_bit_string)
  |> middleware.log
  |> middleware.request_context
}

fn service(request) {
  let path = request.path_segments(request)
  case request.method, path {
    Get, [] -> hello(request)
    _, _ -> not_found(request)
  }
}

fn hello(request) {
  let body =
    "Hello world"
    |> bit_string.from_string
  response.new(200)
  |> response.set_body(body)
}

fn not_found(request) {
  let body =
    "Not Found"
    |> bit_string.from_string
  response.new(404)
  |> response.set_body(body)
}
