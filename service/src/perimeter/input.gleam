import gleam/atom
import gleam/bit_string
import gleam/dynamic
import gleam/list
import gleam/map
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import gleam/http.{Request}
import gleam/json
import gleam_uuid
import perimeter/scrub.{RejectedInput, Report, ServiceError}

pub type Invalid {
  NotProvided(key: String)
  CastFailure(key: String, to: String)
}

pub fn to_report(reason, field_type) {
  case reason {
    NotProvided(key) ->
      Report(
        RejectedInput,
        string.concat(["Missing ", field_type]),
        string.concat([field_type, " '", key, "' is required"]),
      )
    CastFailure(key, to) ->
      Report(
        RejectedInput,
        string.concat(["Invalid ", field_type]),
        string.concat([field_type, " '", key, "' is not a valid ", to]),
      )
  }
}

pub fn to_service_report(reason, field_type) {
  case reason {
    NotProvided(key) ->
      Report(
        ServiceError,
        "Invalid response from service",
        string.concat([field_type, " '", key, "' is required"]),
      )
    CastFailure(key, to) ->
      Report(
        ServiceError,
        "Invalid response from service",
        string.concat([field_type, " '", key, "' is not a valid ", to]),
      )
  }
}
