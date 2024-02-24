import gleam/fetch

pub fn fetch_error_to_string(e: fetch.FetchError) -> String {
  case e {
    fetch.NetworkError(msg) -> "Network Error: " <> msg
    fetch.UnableToReadBody -> "Unable to read response body"
    fetch.InvalidJsonBody -> "Invalid JSON response"
  }
}
