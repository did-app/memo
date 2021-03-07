pub type QueryFailure {
  Timeout
  InvalidSyntax
}
// // Input errors from external service are coder errors
// pub fn to_report(failure) {
//   case failure {
//     Timeout -> Report(ServiceUnavaile, "Database Query timed out")
//     SyntaxError -> Report(ProgramError, "Invalid Syntax in Database Query")
//     Constraint -> Report(Unprocessable)
//   }
// }
