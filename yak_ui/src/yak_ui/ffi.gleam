import gleam/dynamic.{type Dynamic}

@external(javascript, "/ffi.mjs", "preventDefaultOnEvent")
pub fn prevent_default_on_event(a: Dynamic) -> Nil
