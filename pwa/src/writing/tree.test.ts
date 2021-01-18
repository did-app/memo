import { expect } from "chai"
import type { Path } from "./path"
import type { Point } from "./point"

import type { Span } from "./elements"
import { splitSpans } from "./tree"

function P(path: Path, offset: number) { return { path, offset } }
function R(anchor: Point, focus: Point | undefined = anchor) { return { anchor, focus } }

const lineWithLink: Span[] = [{ type: 'text', text: "ab " }, { type: 'link', url: "https://example.com" }, { type: 'text', text: " cd" }]
//  a b | | c
// 0 1 2 3 4 5

test("split line with link", function () {
  let parts: [Span[], Span[]]
  parts = splitSpans(lineWithLink, 0)
  expect(parts[0]).to.eql([{ type: 'text', text: "" }])
  expect(parts[1]).to.eql(lineWithLink)

  parts = splitSpans(lineWithLink, 1)
  expect(parts[0]).to.eql([{ type: 'text', text: "a" }])
  expect(parts[1]).to.eql([{ type: 'text', text: "b " }, ...lineWithLink.slice(1)])

  parts = splitSpans(lineWithLink, 3)
  expect(parts[0]).to.eql(lineWithLink.slice(0, 1))
  expect(parts[1]).to.eql([{ type: 'text', text: "" }, ...lineWithLink.slice(1)])

  parts = splitSpans(lineWithLink, 4)
  expect(parts[0]).to.eql(lineWithLink.slice(0, 2))
  expect(parts[1]).to.eql(lineWithLink.slice(2))

  parts = splitSpans(lineWithLink, 5)
  expect(parts[0]).to.eql([...lineWithLink.slice(0, 2), { type: 'text', text: " " }])
  expect(parts[1]).to.eql([{ type: 'text', text: "cd" }])

  parts = splitSpans(lineWithLink, 7)
  expect(parts[0]).to.eql(lineWithLink)
  expect(parts[1]).to.eql([{ type: 'text', text: "" }])
})
