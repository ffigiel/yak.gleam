import gleam/io
import gleam/string
import gleam/http
import gleam/int
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import gleam/base
import gleam/pgo
import yak/app_request.{AppRequest}
import yak/user

pub fn app_request(
  service: AppService(b),
  db: pgo.Connection,
) -> Service(BitString, b) {
  fn(request: Request(BitString)) {
    let app_request = app_request.new(request, db)
    service(app_request)
  }
}

type AppService(b) =
  fn(AppRequest) -> Response(b)

pub fn log(service: AppService(b)) -> AppService(b) {
  fn(request: AppRequest) {
    let response = service(request)
    io.println(prepare_log_line(request, response))
    response
  }
}

fn prepare_log_line(request: AppRequest, response: Response(b)) -> String {
  string.concat([
    request.http.method
    |> http.method_to_string
    |> string.uppercase,
    " ",
    int.to_string(response.status),
    " ",
    request.http.path,
    " request_id=",
    request.request_id,
    " user=",
    user.to_string(request.user),
  ])
}
