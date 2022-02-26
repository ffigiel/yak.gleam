import gleam/io
import gleam/string
import gleam/http
import gleam/int
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import gleam/base
import gleam/pgo

pub type RequestContext {
  RequestContext(
    db: pgo.Connection,
    body: BitString,
    request_id: String,
    user: User,
  )
}

fn new_request_context(
  request: Request(BitString),
  db: pgo.Connection,
) -> RequestContext {
  RequestContext(
    db: db,
    body: request.body,
    request_id: gen_request_id(),
    user: Anonymous,
  )
}

pub type User {
  Anonymous
}

pub fn request_context(
  service: Service(RequestContext, b),
  db: pgo.Connection,
) -> Service(BitString, b) {
  fn(request: Request(BitString)) {
    let req_ctx = new_request_context(request, db)
    let request = request.map(request, fn(_) { req_ctx })
    service(request)
  }
}

fn gen_request_id() -> String {
  strong_rand_bytes(8)
  |> base.url_encode64(False)
}

external fn strong_rand_bytes(n: Int) -> BitString =
  "crypto" "strong_rand_bytes"

pub fn log(service: Service(RequestContext, b)) -> Service(RequestContext, b) {
  fn(request: Request(RequestContext)) {
    let response = service(request)
    io.println(prepare_log_line(request, response))
    response
  }
}

fn prepare_log_line(
  request: Request(RequestContext),
  response: Response(b),
) -> String {
  string.concat([
    request.method
    |> http.method_to_string
    |> string.uppercase,
    " ",
    int.to_string(response.status),
    " ",
    request.path,
    " request_id=",
    request.body.request_id,
    " user=",
    user_to_string(request.body.user),
  ])
}

fn user_to_string(user: User) -> String {
  case user {
    Anonymous -> "anonymous"
  }
}
