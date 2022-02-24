import gleam/io
import gleam/string
import gleam/http
import gleam/int
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}

pub fn log(service: Service(a, b)) -> Service(a, b) {
  fn(request) {
    let response = service(request)
    io.println(prepare_log_line(request, response))
    response
  }
}

fn prepare_log_line(request: Request(a), response: Response(b)) -> String {
  string.concat([
    request.method
    |> http.method_to_string
    |> string.uppercase,
    " ",
    int.to_string(response.status),
    " ",
    request.path,
  ])
}
