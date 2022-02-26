import gleam/base

pub fn gen_request_id() -> String {
  strong_rand_bytes(8)
  |> base.url_encode64(False)
}

pub fn gen_session_id() -> BitString {
  strong_rand_bytes(32)
}

external fn strong_rand_bytes(n: Int) -> BitString =
  "crypto" "strong_rand_bytes"
