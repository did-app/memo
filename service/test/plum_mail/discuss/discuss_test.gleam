
// import gleam/result
// import gleam/string
// import plum_mail/discuss/discuss.{topic_to_string, validate_topic}
// import gleam/should
// pub fn topic_validation_test() {
//   validate_topic("My new topic")
//   |> result.map(topic_to_string)
//   |> should.equal(Ok("My new topic"))
//   validate_topic("My new topic?")
//   |> result.map(topic_to_string)
//   |> should.equal(Ok("My new topic?"))
//   validate_topic("My new topic!")
//   |> result.map(topic_to_string)
//   |> should.equal(Ok("My new topic!"))
//   validate_topic("My-new,topic.")
//   |> result.map(topic_to_string)
//   |> should.equal(Ok("My-new,topic."))
//   validate_topic("  My-new,topic.  ")
//   |> result.map(topic_to_string)
//   |> should.equal(Ok("My-new,topic."))
//   validate_topic("")
//   |> result.map(topic_to_string)
//   |> should.equal(Error(Nil))
//   // Too short
//   validate_topic("t")
//   |> result.map(topic_to_string)
//   |> should.equal(Error(Nil))
//   // Too long
//   validate_topic(string.repeat("a", 101))
//   |> result.map(topic_to_string)
//   |> should.equal(Error(Nil))
//   validate_topic("my@email.example")
//   |> result.map(topic_to_string)
//   |> should.equal(Error(Nil))
// }
