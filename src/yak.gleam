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
  start_server(db, port)
  io.println(string.concat(["✅ Yak running on port ", int.to_string(port)]))
  process.sleep_forever()
}

fn start_server(db: pgo.Connection, port: Int) -> Nil {
  case elli.start(web.stack(db), on_port: port) {
    Ok(_) -> Nil
    Error(_) -> {
      io.println("⚠️ Failed to start the server, retrying")
      process.sleep(1000)
      start_server(db, port)
    }
  }
}

fn get_db_connection() -> pgo.Connection {
  pgo.connect(pgo.Config(..pgo.default_config(), port: 5435))
}
