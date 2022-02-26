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
import gleam/erlang
import gleam/bit_string
import gleam/bit_builder.{BitBuilder}

type AppService =
  fn(AppRequest) -> Response(BitBuilder)

pub fn app_request(
  service: AppService,
  db: pgo.Connection,
) -> Service(BitString, BitBuilder) {
  fn(request: Request(BitString)) {
    let app_request = app_request.new(request, db)
    service(app_request)
  }
}

pub fn log(service: AppService) -> AppService {
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

pub fn rescue(service: AppService) -> AppService {
  fn(request: AppRequest) {
    let result = erlang.rescue(fn() { service(request) })
    case result {
      Ok(response) -> response
      Error(crash) -> {
        io.debug(crash)
        let body =
          "Internal Server Error"
          |> bit_string.from_string
          |> bit_builder.from_bit_string
        response.new(500)
        |> response.set_body(body)
      }
    }
  }
}
