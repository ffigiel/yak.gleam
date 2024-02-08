import gleam/bytes_builder.{type BytesBuilder}
import gleam/bit_array
import gleam/http/response.{type Response}

pub fn unauthorized() -> Response(BytesBuilder) {
  string_response(401, "Unauthorized")
}

pub fn not_found() -> Response(BytesBuilder) {
  string_response(404, "Not Found")
}

pub fn internal_server_error() -> Response(BytesBuilder) {
  string_response(500, "Internal Server Error")
}

pub fn string_response(status_code: Int, body: String) -> Response(BytesBuilder) {
  response.new(status_code)
  |> response.set_body(
    body
    |> bit_array.from_string
    |> bytes_builder.from_bit_array,
  )
}
