
// import gleam/io
// import gleam/int
// import gleam/http
// import plum_mail/web/router.{handle}
// import plum_mail/support
// import gleam/should
// pub fn bouncing_email_test() {
//   let request =
//     http.default_req()
//     |> http.set_method(http.Post)
//     |> http.set_path("/inbound")
//     |> http.prepend_req_header("content-type", "application/json")
//     |> http.set_req_body(<<
//       "{
//   \"FromName\": \"Postmarkapp Support\",
//   \"From\": \"support@postmarkapp.com\",
//   \"FromFull\": {
//     \"Email\": \"support@postmarkapp.com\",
//     \"Name\": \"Postmarkapp Support\",
//     \"MailboxHash\": \"\"
//   },
//   \"To\": \"\\\"Peter\\\" <peter@sendmemo.app>\",
//   \"ToFull\": [
//     {
//       \"Email\": \"peter@sendmemo.app\",
//       \"Name\": \"Peter\",
//       \"MailboxHash\": \"\"
//     }
//   ],
//   \"StrippedTextReply\": \"This is the reply text\"
// }":utf8,
//     >>)
//   let response = handle(request, support.test_config())
//   io.debug(response)
//   should.equal(response.status, 200)
// }
// pub fn conversation_reply_test() {
//   assert Ok(identifier) = support.generate_personal_identifier("example.test")
//   assert Ok(topic) = discuss.validate_topic("Test topic")
//   assert Ok(conversation) = start_conversation.execute(topic, identifier.id)
//   let request =
//     http.default_req()
//     |> http.set_method(http.Post)
//     |> http.set_path("/inbound")
//     |> http.prepend_req_header("content-type", "application/json")
//     |> http.set_req_body(<<
//       "{
//   \"From\": \"":utf8,
//       identifier.email_address.value:utf8,
//       "\",
//   \"FromFull\": {
//     \"Email\": \"support@postmarkapp.com\",
//     \"Name\": \"Postmarkapp Support\",
//     \"MailboxHash\": \"\"
//   },
//   \"To\": \"\\\"Peter\\\" <peter@sendmemo.app>\",
//   \"ToFull\": [
//     {
//       \"Email\": \"c+":utf8,
//       int.to_string(conversation.id):utf8,
//       "@reply.sendmemo.app\",
//       \"Name\": \"\",
//       \"MailboxHash\": \"":utf8,
//       int.to_string(conversation.id):utf8,
//       "\"
//     }
//   ],
//   \"StrippedTextReply\": \"This is the reply text\"
// }":utf8,
//     >>)
//   let response = handle(request, support.test_config())
//   //
//   should.equal(response.status, 200)
//   assert Ok([message]) = discuss.load_messages(conversation.id)
//   message.counter
//   |> should.equal(1)
//   message.content
//   |> should.equal("This is the reply text")
//   message.author
//   |> should.equal(identifier)
// }
