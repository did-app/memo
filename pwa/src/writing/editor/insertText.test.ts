import { expect } from "chai"

import type { Block, Paragraph, Annotation, Span } from "../elements"
import type { Path } from "../path"
import type { Point } from "../point"
import { insertText } from "./insertText";

const paragraphs: Block[] = [
  { type: "paragraph", spans: [{ type: "text", text: "abc" }] },
  { type: "paragraph", spans: [{ type: "text", text: "" }] },
  { type: "paragraph", spans: [{ type: "text", text: "d" }] },
]

function P(path: Path, offset: number) { return { path, offset } }
function R(anchor: Point, focus: Point | undefined = anchor) { return { anchor, focus } }

test('text in middle of text node', function () {
  const range = R(P([0], 1))
  const [updated, cursor] = insertText(paragraphs, range, "X")
  expect(updated.length).to.eq(3)
  const [first, ...rest] = updated as [Paragraph];
  expect(first.spans).to.eql([{ type: 'text', text: "aXbc" }])
  expect(rest).to.eql(paragraphs.slice(1))
  expect(cursor).to.eql(P([0], 2))
})

test('replace text in middle of text node', function () {
  const range = R(P([0], 1), P([0], 2))
  const [updated, cursor] = insertText(paragraphs, range, "XYZ")
  expect(updated.length).to.eq(3)
  const [first, ...rest] = updated as [Paragraph];
  expect(first.spans).to.eql([{ type: 'text', text: "aXYZc" }])
  expect(rest).to.eql(paragraphs.slice(1))
  expect(cursor).to.eql(P([0], 4))
})

const annotations: Block[] = [
  { type: 'annotation', reference: null as any, blocks: [{ type: "paragraph", spans: [{ type: "text", text: "abc" }] },] },
  { type: "paragraph", spans: [{ type: "text", text: "d" }] },
]

test('type comment in annotation', function () {
  const range = R(P([0, 0], 3))
  const [updated, cursor] = insertText(annotations, range, "X")
  expect(updated.length).to.eq(2)
  const annotation = updated[0] as Annotation
  expect(annotation.blocks[0]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "abcX" }] })
  expect(updated[1]).to.eq(annotations[1])
  expect(cursor).to.eql(P([0, 0], 4))
})

test('link discovery inline', function () {
  const line: Span[] = [{ type: 'text', text: "check http://example.co" }]
  const fragment: Block[] = [{ type: 'paragraph', spans: line }]
  const range = R(P([0, 0], 23))

  const [updated, cursor] = insertText(fragment, range, " ")
  expect(updated.length).to.eq(1)
  const [before, link, after] = (updated[0] as Paragraph).spans
  expect(before).to.eql({ type: 'text', text: "check " })
  expect(link).to.eql({ type: 'link', url: "http://example.co" })
  expect(after).to.eql({ type: 'text', text: " " })

})