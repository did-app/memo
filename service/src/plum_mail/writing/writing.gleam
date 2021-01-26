import gleam/dynamic
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/result

pub fn block_from_dynamic(raw) {
  assert Ok(block_type) = dynamic.field(raw, "type")
  assert Ok(block_type) = dynamic.string(block_type)
  case block_type {
    "paragraph" -> {
      assert Ok(spans) = dynamic.field(raw, "spans")
      assert Ok(spans) = dynamic.typed_list(spans, span_from_dynamic)
      Ok(Paragraph(spans))
    }
    "annotation" -> {
      assert Ok(blocks) = dynamic.field(raw, "blocks")
      assert Ok(blocks) = dynamic.typed_list(blocks, block_from_dynamic)
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
  assert Ok(span_type) = dynamic.field(raw, "type")
  assert Ok(span_type) = dynamic.string(span_type)
  case span_type {
    "text" -> {
      assert Ok(text) = dynamic.field(raw, "text")
      assert Ok(text) = dynamic.string(text)
      Ok(Text(text))
    }
    "link" -> {
      assert Ok(url) = dynamic.field(raw, "url")
      assert Ok(url) = dynamic.string(url)
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
  // TODO remove prompt
  Prompt(reference: Reference)
}

pub fn render(blocks) {
  list.map(blocks, render_block)
}

fn render_block(block) {
  case block {
    Paragraph(spans: spans) -> {
      let tuple(text, html) =
        spans
        |> list.map(render_span)
        |> list.zip()
      todo
    }
  }
}
