import gleam/dynamic.{type Dynamic}

@external(javascript, "/ffi.mjs", "preventDefaultOnEvent")
pub fn prevent_default_on_event(a: Dynamic) -> Nil

@external(javascript, "/ffi.mjs", "reloadPage")
pub fn reload_page() -> Nil
