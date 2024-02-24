import lustre/effect
import gleam/http/response.{type Response}
import gleam/http
import gleam/string
import gleam/int
import gleam/dynamic.{type Dynamic}
import gleam/result
import gleam/http/request
import lustre/element.{type Element}
import lustre/element/html
import yak_ui/core.{type AppEffect, type Page, Page}
import yak_common
import gleam/fetch
import gleam/javascript/promise.{type Promise}

pub fn fetch_error_to_string(e: fetch.FetchError) -> String {
  case e {
    fetch.NetworkError(msg) -> "Network Error: " <> msg
    fetch.UnableToReadBody -> "Unable to read response body"
    fetch.InvalidJsonBody -> "Invalid JSON response"
  }
}
