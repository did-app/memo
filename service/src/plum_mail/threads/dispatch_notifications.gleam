import gleam/atom
import gleam/dynamic.{Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/http
import gleam/json
import gleam/pgo
import gleam_uuid
import postmark/client as postmark
import plum_mail/config.{Config}
import plum_mail/run_sql
import plum_mail/authentication
import perimeter/email_address.{EmailAddress}
import plum_mail/identifier.{Identifier}

pub fn load() {
  let sql =
    // Bit weird to call an email address a topic but it is the analogue for a thread
    "
  WITH participants AS (
    SELECT lower_identifier_id AS identifier_id, recipient.email_address, thread_id, contact.email_address AS contact, NULL as group_name, CAST(NULL AS uuid) AS group_id
    FROM pairs
    JOIN identifiers AS recipient ON lower_identifier_id = recipient.id
    JOIN identifiers AS contact ON upper_identifier_id = contact.id
    WHERE recipient.group_id IS NULL
    
    UNION ALL
    
    SELECT upper_identifier_id AS identifier_id, recipient.email_address, thread_id, contact.email_address AS contact, NULL as group_name, CAST(NULL AS uuid) AS group_id
    FROM pairs
    JOIN identifiers AS recipient ON upper_identifier_id = recipient.id
    JOIN identifiers AS contact ON lower_identifier_id = contact.id
    WHERE recipient.group_id IS NULL
    
    UNION ALL

    SELECT invitations.identifier_id, recipient.email_address, groups.thread_id, NULL, groups.name AS group_name, groups.id AS group_id
    FROM invitations
    JOIN identifiers AS recipient ON recipient.id = invitations.identifier_id
    JOIN groups ON groups.id = invitations.group_id 
  )
  SELECT 
    participants.identifier_id, 
    participants.email_address,
    participants.thread_id,
    memos.content,
    memos.position,
    participants.contact,
    participants.group_name,
    participants.group_id,
    authors.email_address,
    authors.name
  FROM memos
  JOIN participants ON participants.thread_id = memos.thread_id
  LEFT JOIN memo_notifications AS notifications
    ON notifications.thread_id = memos.thread_id
    AND notifications.position = memos.position
    AND notifications.recipient_id = participants.identifier_id
  LEFT JOIN identifiers AS authors ON authors.id = memos.authored_by
  WHERE notifications IS NULL
  AND participants.email_address <> 'peter@sendmemo.app'
  AND participants.email_address <> 'richard@sendmemo.app'
  AND participants.identifier_id <> memos.authored_by
  ORDER BY memos.inserted_at ASC
  "
  try rows = run_sql.execute(sql, [])
  assert Ok(deliveries) =
    list.try_map(
      rows,
      fn(row) {
        try recipient_id = dynamic.element(row, 0)
        try recipient_id = dynamic.bit_string(recipient_id)
        let recipient_id = run_sql.binary_to_uuid4(recipient_id)
        try recipient_email_address = dynamic.element(row, 1)
        try recipient_email_address = dynamic.string(recipient_email_address)
        try recipient_email_address =
          email_address.validate(recipient_email_address)
          |> result.map_error(fn(_) { todo })
        try thread_id = dynamic.element(row, 2)
        try thread_id = dynamic.bit_string(thread_id)
        let thread_id = run_sql.binary_to_uuid4(thread_id)

        try content = dynamic.element(row, 3)
        let content = dynamic.typed_list(content, block_from_dynamic)
        try position = dynamic.element(row, 4)
        try position = dynamic.int(position)

        try contact = dynamic.element(row, 5)
        try contact = run_sql.dynamic_option(contact, dynamic.string)
        let contact =
          option.map(
            contact,
            fn(contact) {
              // This is easiest handled by an input.required/optional that works for rows returned from pgo
              assert Ok(contact) = email_address.validate(contact)
              contact
            },
          )

        try group_name = dynamic.element(row, 6)
        try group_name = run_sql.dynamic_option(group_name, dynamic.string)
        try group_id = dynamic.element(row, 7)
        try group_id = run_sql.dynamic_option(group_id, dynamic.bit_string)
        let group_id =
          option.map(group_id, fn(id) { run_sql.binary_to_uuid4(id) })

        try author_email = dynamic.element(row, 8)
        try author_email = dynamic.string(author_email)

        try author_name = dynamic.element(row, 9)
        try author_name = run_sql.dynamic_option(author_name, dynamic.string)

        let author =
          option.map(
            author_name,
            fn(name) { string.concat([name, " <", author_email, ">"]) },
          )
          |> option.unwrap(author_email)

        tuple(
          recipient_id,
          recipient_email_address,
          contact,
          thread_id,
          content,
          position,
          group_name,
          group_id,
          author,
        )
        |> Ok
      },
    )
  Ok(deliveries)
}

pub fn run() {
  try config =
    config.from_env()
    |> result.map_error(config.to_report)

  try outstanding = load()
  list.each(outstanding, dispatch_to_identifier(_, config))
  |> Ok
}

fn block_from_dynamic(raw) {
  try block_type = dynamic.field(raw, "type")
  try block_type = dynamic.string(block_type)
  case block_type {
    "paragraph" -> {
      try spans = dynamic.field(raw, "spans")
      try spans = dynamic.typed_list(spans, span_from_dynamic)
      Ok(Paragraph(spans))
    }
    "annotation" -> {
      try blocks = dynamic.field(raw, "blocks")
      try blocks = dynamic.typed_list(blocks, block_from_dynamic)
      let reference = RangeReference
      Ok(Annotation(reference, blocks))
    }
    "prompt" -> {
      let reference = RangeReference
      Ok(Prompt(reference))
    }
  }
}

fn span_from_dynamic(raw) {
  try span_type = dynamic.field(raw, "type")
  try span_type = dynamic.string(span_type)
  case span_type {
    "text" -> {
      try text = dynamic.field(raw, "text")
      try text = dynamic.string(text)
      Ok(Text(text))
    }
    "link" -> {
      try url = dynamic.field(raw, "url")
      try url = dynamic.string(url)
      let title =
        dynamic.field(raw, "title")
        |> result.then(dynamic.string)
        |> option.from_result()
      Ok(Link(title, url))
    }
    "softbreak" -> Ok(Softbreak)
  }
}

pub type Reference {
  SectionReference(note_index: Int, block_index: Int)
  RangeReference
}

pub type Span {
  Text(text: String)
  Link(title: Option(String), url: String)
  Softbreak
}

pub type Block {
  Paragraph(spans: List(Span))
  Annotation(reference: Reference, blocks: List(Block))
  Prompt(reference: Reference)
}

fn block_to_text(block) {
  case block {
    Paragraph(spans) ->
      string.join(
        list.map(
          spans,
          fn(span) {
            case span {
              Text(text) -> text
              Link(title, url) -> option.unwrap(title, url)
              Softbreak -> "\r\n"
            }
          },
        ),
        "",
      )
    Annotation(blocks: [first, .._], ..) -> block_to_text(first)
    Annotation(..) -> ""
    Prompt(..) -> ""
  }
}

fn dispatch_to_identifier(record, config) {
  let Config(
    postmark_api_token: postmark_api_token,
    client_origin: client_origin,
    ..,
  ) = config
  let tuple(
    recipient_id,
    recipient_email_address,
    contact,
    thread_id,
    content,
    position,
    group_name,
    group_id,
    author,
  ) = record

  let preview = case content {
    Ok([first, .._]) -> Some(block_to_text(first))
    _ -> None
  }

  let tuple(topic, path) = case contact, group_name, group_id {
    Some(email_address), None, None -> tuple(
      string.concat([email_address.value, " sent you a memo"]),
      email_address.to_path(email_address),
    )
    None, Some(name), Some(group_id) -> tuple(
      string.concat(["New memo in ", name]),
      string.concat(["/groups/", gleam_uuid.to_string(group_id)]),
    )
  }
  // contact link needs to handle adding position because it will be in a hash fragment.
  try authentication_url = contact_link(client_origin, path, recipient_id)

  let to = recipient_email_address.value
  let from = "memo <memo@sendmemo.app>"

  io.debug(preview)
  let template_alias = "memo-notification"
  let template_model =
    json.object([
      tuple("authentication_url", json.string(authentication_url)),
      tuple("email_address", json.string(author)),
      tuple("content_preview", json.nullable(preview, json.string)),
    ])
  try response =
    postmark.send_email_with_template(
      from,
      to,
      template_alias,
      template_model,
      postmark_api_token,
    )
  case response {
    Ok(Nil) -> {
      try _ = record_sent(thread_id, position, recipient_id)
      Ok(Nil)
    }
    // why was that, handle case of bad email addresses
    Error(postmark.Failure(retry: True)) -> Ok(Nil)
    Error(postmark.Failure(retry: False)) -> {
      try _ = record_failed(thread_id, position, recipient_id)
      Ok(Nil)
    }
  }
}

fn contact_link(origin, path, recipient_id) {
  try code = authentication.generate_link_token(recipient_id)
  [origin, path, "#code=", code]
  |> string.join("")
  |> Ok
}

pub fn record_result(thread_id, position, recipient_id, success) {
  let sql =
    "
    INSERT INTO memo_notifications (thread_id, position, recipient_id, success)
    VALUES ($1, $2, $3, $4)
    RETURNING *
    "
  let args = [
    run_sql.uuid(thread_id),
    pgo.int(position),
    run_sql.uuid(recipient_id),
    pgo.bool(success),
  ]
  run_sql.execute(sql, args)
}

pub fn record_sent(thread_id, position, recipient_id) {
  record_result(thread_id, position, recipient_id, True)
}

pub fn record_failed(thread_id, position, recipient_id) {
  record_result(thread_id, position, recipient_id, False)
}
