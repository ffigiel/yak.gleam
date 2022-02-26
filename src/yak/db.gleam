import gleam/pgo

pub fn create_session(
  db: pgo.Connection,
  user_pk: Int,
  session_id: BitString,
) -> Result(pgo.Returned(Nil), pgo.QueryError) {
  let sql =
    "
    insert into sessions
      (user_pk, session_id)
    values
      ($1, $2)
    "
  pgo.execute(
    sql,
    db,
    [pgo.int(user_pk), pgo.bytea(session_id)],
    fn(_) { Ok(Nil) },
  )
}
