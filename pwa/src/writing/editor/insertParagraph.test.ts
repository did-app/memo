import { expect } from "chai"

import type { Block, Paragraph, Annotation } from "../elements"
import type { Path } from "../path"
import type { Point } from "../point"
import { } from "jest";
import { insertParagraph } from "./insertParagraph";
import { text } from "svelte/internal";

const paragraphs: Block[] = [
  { type: "paragraph", spans: [{ type: "text", text: "abc" }] },
  { type: "paragraph", spans: [{ type: "text", text: "" }] },
  { type: "paragraph", spans: [{ type: "text", text: "d" }] },
]

function P(path: Path, offset: number) { return { path, offset } }
function R(anchor: Point, focus: Point | undefined = anchor) { return { anchor, focus } }

test('in middle of text node', function () {
  const range = R(P([0], 1))
  const [updated, cursor] = insertParagraph(paragraphs, range)
  expect(updated.length).to.eq(4)
  const [first, second, ...rest] = updated as [Paragraph, Paragraph];
  expect(first.spans).to.eql([{ type: 'text', text: "a" }])
  expect(second.spans).to.eql([{ type: 'text', text: "bc" }])
  expect(rest).to.eql(paragraphs.slice(1))
})

test('accross lines', function () {
  const range = R(P([0], 2), P([2], 0))
  const [updated, cursor] = insertParagraph(paragraphs, range)
  expect(updated.length).to.eq(2)
  const [first, second] = updated as [Paragraph, Paragraph];
  expect(first.spans).to.eql([{ type: 'text', text: "ab" }])
  expect(second.spans).to.eql([{ type: 'text', text: "d" }])
})

test('beginning of empty line is no op', function () {
  const range = R(P([1], 0))
  const [updated, cursor] = insertParagraph(paragraphs, range)
  expect(updated).to.eql(paragraphs)
})

const annotations: Block[] = [
  { type: 'annotation', reference: null as any, blocks: [{ type: "paragraph", spans: [{ type: "text", text: "abc" }] },] },
  { type: "paragraph", spans: [{ type: "text", text: "d" }] },
]

test('end of comment stays in annotation', function () {
  const range = R(P([0, 0], 3))
  const [updated, cursor] = insertParagraph(annotations, range)
  expect(updated.length).to.eq(2)
  const annotation = updated[0] as Annotation
  expect(annotation.blocks[0]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "abc" }] })
  expect(annotation.blocks[1]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "" }] })
  expect(updated[1]).to.eq(annotations[1])
})

test('beginning of comment leaves annotation', function () {
  const range = R(P([0, 0], 0))
  const [updated, cursor] = insertParagraph(annotations, range)
  expect(updated.length).to.eq(3)
  const annotation = updated[0] as Annotation
  expect(annotation.blocks[0]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "" }] })
  expect(updated[1]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "abc" }] })
  expect(updated[2]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "d" }] })
})