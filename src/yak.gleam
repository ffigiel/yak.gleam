import gleam/io
import gleam/int
import gleam/http/elli
import gleam/string
import gleam/pgo
import yak/web
import gleam/erlang/process

pub fn main() {
  let db = get_db_connection()
  let port = 3000
  let assert Ok(_) = elli.start(web.stack(db), on_port: port)
  io.println(string.concat(["Yak running on port ", int.to_string(port)]))
  process.sleep_forever()
}

fn get_db_connection() -> pgo.Connection {
  pgo.connect(pgo.Config(..pgo.default_config(), port: 5435))
}
