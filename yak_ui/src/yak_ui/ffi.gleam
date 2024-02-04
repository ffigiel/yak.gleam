import gleam/dynamic.{type Dynamic}

@external(javascript, "/ffi.mjs", "preventDefaultOnEvent")
pub fn prevent_default_on_event(a: Dynamic) -> Nil
//
//@external(javascript, "/ffi.mjs", "apiRequest")
//fn api_request(path: String, body: String) -> Dynamic
