import gleam/bit_builder.{BitBuilder}
import gleam/bit_string
import gleam/http/response.{Response}

pub fn not_found() -> Response(BitBuilder) {
  string_response(404, "Not Found")
}

pub fn internal_server_error() -> Response(BitBuilder) {
  string_response(500, "Internal Server Error")
}

pub fn string_response(status_code: Int, body: String) -> Response(BitBuilder) {
  response.new(status_code)
  |> response.set_body(
    body
    |> bit_string.from_string
    |> bit_builder.from_bit_string,
  )
}
