import gleam/io
import gleam/int
import gleam/http/elli
import gleam/string
import yak/web
import gleam/erlang

pub fn main() {
  let port = 3000
  assert Ok(_) = elli.start(web.stack(), on_port: port)
  io.println(string.concat(["Yak running on port ", int.to_string(port)]))
  erlang.sleep_forever()
}
