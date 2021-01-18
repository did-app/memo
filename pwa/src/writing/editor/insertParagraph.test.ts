import { expect } from "chai"

import type { Block, Paragraph, Annotation } from "../elements"
import type { Path } from "../path"
import type { Point } from "../point"
import { insertParagraph } from "./insertParagraph";

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
  expect(cursor).to.eql(P([1], 0))
})

test('accross lines', function () {
  const range = R(P([0], 2), P([2], 0))
  const [updated, cursor] = insertParagraph(paragraphs, range)
  expect(updated.length).to.eq(2)
  const [first, second] = updated as [Paragraph, Paragraph];
  expect(first.spans).to.eql([{ type: 'text', text: "ab" }])
  expect(second.spans).to.eql([{ type: 'text', text: "d" }])
  expect(cursor).to.eql(P([1], 0))
})

test('beginning of empty line is no op', function () {
  const range = R(P([1], 0))
  const [updated, cursor] = insertParagraph(paragraphs, range)
  expect(updated).to.eql(paragraphs)
  expect(cursor).to.eql(P([1], 0))
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
  expect(cursor).to.eql(P([0, 1], 0))
})

test('beginning of comment lifts annotation', function () {
  const range = R(P([0, 0], 0))
  const [updated, cursor] = insertParagraph(annotations, range)
  expect(updated.length).to.eq(3)
  const annotation = updated[0] as Annotation
  expect(annotation.blocks[0]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "" }] })
  expect(updated[1]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "abc" }] })
  expect(updated[2]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "d" }] })
  expect(cursor).to.eql(P([1], 0))
})

test('lifted lines, after the first, dont leave an empty line', function () {
  const blocks: Block[] = [
    {
      type: 'annotation', reference: null as any, blocks: [
        { type: "paragraph", spans: [{ type: "text", text: "abc" }] },
        { type: "paragraph", spans: [{ type: "text", text: "d" }] },
      ]
    },
  ]
  const range = R(P([0, 1], 0))
  const [updated, cursor] = insertParagraph(blocks, range)
  expect(updated.length).to.eq(2)
  const annotation = updated[0] as Annotation
  expect(annotation.blocks.length).to.eq(1)
  expect(annotation.blocks[0]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "abc" }] })
  expect(updated[1]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "d" }] })
  expect(cursor).to.eql(P([1], 0))

})
const emptyAnnotations: Block[] = [
  { type: 'annotation', reference: null as any, blocks: [{ type: "paragraph", spans: [{ type: "text", text: "" }] },] },
  { type: "paragraph", spans: [{ type: "text", text: "d" }] },
]

test('end of empty comment lifts from annotation', function () {
  const range = R(P([0, 0], 0))
  const [updated, cursor] = insertParagraph(emptyAnnotations, range)

  expect(updated.length).to.eq(3)
  const annotation = updated[0] as Annotation
  expect(annotation.blocks[0]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "" }] })
  expect(updated[1]).to.eql({ type: "paragraph", spans: [{ type: "text", text: "" }] })

  expect(updated[2]).to.eq(emptyAnnotations[1])
  expect(cursor).to.eql(P([1], 0))
})



// we don't do this because if multiple lines lifted what do we merge.
// test('empty lines are merged when lifted', function () {
//   const blocks: Block[] = [
//     {
//       type: 'annotation', reference: null as any, blocks: [
//         { type: "paragraph", spans: [{ type: "text", text: "abc" }] },
//         { type: "paragraph", spans: [{ type: "text", text: "" }] },
//       ]
//     },
//     { type: "paragraph", spans: [{ type: "text", text: "" }] },
//   ]
//   const range = R(P([0, 1], 0))
//   const [updated, cursor] = insertParagraph(blocks, range)

//   expect(updated.length).to.eq(2)
// })

test('empty lines are merged when inline', function () {
  const blocks: Block[] = [
    { type: "paragraph", spans: [{ type: "text", text: "" }] },
    { type: "paragraph", spans: [{ type: "text", text: "abc" }] },
    { type: "paragraph", spans: [{ type: "text", text: "" }] },
  ]
  const range = R(P([1], 3))
  const [updated, cursor] = insertParagraph(blocks, range)

  expect(updated.length).to.eq(3)
  expect(cursor).to.eql(P([2], 0))
})