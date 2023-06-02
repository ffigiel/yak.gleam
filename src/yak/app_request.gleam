import gleam/base
import gleam/option.{Option}
import gleam/crypto
import gleam/http/request.{Request}
import gleam/pgo
import yak/user.{User}

pub type AppRequest {
  AppRequest(
    db: pgo.Connection,
    request_id: String,
    user: Option(User),
    http: Request(BitString),
  )
}

pub fn new(request: Request(BitString), db: pgo.Connection) -> AppRequest {
  AppRequest(
    db: db,
    request_id: gen_request_id(),
    user: option.None,
    http: request,
  )
}

fn gen_request_id() -> String {
  crypto.strong_random_bytes(8)
  |> base.url_encode64(False)
}
