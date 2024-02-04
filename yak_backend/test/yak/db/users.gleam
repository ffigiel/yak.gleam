import gleam/pgo
import yak_backend/user.{User}
import yak_backend/db
import gleeunit/should

fn get_test_db() -> pgo.Connection {
  pgo.connect(pgo.Config(..pgo.default_config(), port: 5435, database: "test"))
}

pub fn get_user_by_email_test() {
  let db = get_test_db()
  db.get_user_by_email(db, "user@example.com")
  |> should.equal(
    Ok(User(pk: 1, email: "user@example.com", password_hash: <<>>)),
  )
}

pub fn get_user_by_email_case_insensitive_test() {
  let db = get_test_db()
  db.get_user_by_email(db, "User@Example.COM")
  |> should.equal(
    Ok(User(pk: 1, email: "user@example.com", password_hash: <<>>)),
  )
}

pub fn get_user_by_email_not_found_test() {
  let db = get_test_db()
  db.get_user_by_email(db, "invalid")
  |> should.equal(Error(db.NotFound))
}
