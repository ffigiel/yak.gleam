import gleam/http/request.{Request}
import gleam/base
import gleam/pgo
import yak/user.{User}

pub type AppRequest {
  AppRequest(
    db: pgo.Connection,
    request_id: String,
    user: User,
    http: Request(BitString),
  )
}

pub fn new(request: Request(BitString), db: pgo.Connection) -> AppRequest {
  AppRequest(
    db: db,
    request_id: gen_request_id(),
    user: user.Anonymous,
    http: request,
  )
}

fn gen_request_id() -> String {
  strong_rand_bytes(8)
  |> base.url_encode64(False)
}

external fn strong_rand_bytes(n: Int) -> BitString =
  "crypto" "strong_rand_bytes"
