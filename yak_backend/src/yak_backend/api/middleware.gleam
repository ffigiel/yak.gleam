import gleam/bit_builder.{BitBuilder}
import gleam/erlang
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/int
import gleam/io
import gleam/option
import gleam/pgo
import gleam/string
import yak_backend/api/app_request.{AppRequest}
import yak_backend/api/utils

type AppService =
  fn(AppRequest) -> Response(BitBuilder)

pub fn app_request(db: pgo.Connection) {
  fn(service) {
    fn(request: Request(BitString)) {
      let app_request = app_request.new(request, db)
      service(app_request)
    }
  }
}

pub fn request_id(service: AppService) -> AppService {
  fn(request: AppRequest) {
    service(request)
    |> response.prepend_header("x-request-id", request.request_id)
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
    case app_request.get_user(request.auth_info) {
      option.None -> "anonymous"
      option.Some(u) -> u.email
    },
  ])
}

pub fn rescue(service: AppService) -> AppService {
  fn(request: AppRequest) {
    let result = erlang.rescue(fn() { service(request) })
    case result {
      Ok(response) -> response
      Error(crash) -> {
        io.println(string.concat([
          "Unhandled Exception: ",
          string.inspect(crash),
        ]))
        utils.internal_server_error()
      }
    }
  }
}
