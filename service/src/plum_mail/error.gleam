pub type InvalidField {
  Missing
  CastFailure(help: String)
}

pub type Reason {
  BadRequest(detail: String)
  Unprocessable(field: String, failure: InvalidField)
  Unauthenticated
  Forbidden
  InternalServerError(detail: String)
}
