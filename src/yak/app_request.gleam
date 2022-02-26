import gleam/http/request.{Request}
import gleam/pgo
import yak/user.{User}
import yak/crypto

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
    request_id: crypto.gen_request_id(),
    user: user.Anonymous,
    http: request,
  )
}
