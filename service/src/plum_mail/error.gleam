pub type InvalidField {
  Missing
  CastFailure(help: String)
  NotRecognised
}

pub type Reason {
  BadRequest(detail: String)
  Unprocessable(field: String, failure: InvalidField)
  Unauthenticated
  Forbidden
  InternalServerError(detail: String)
}
