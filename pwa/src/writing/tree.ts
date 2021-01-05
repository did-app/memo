import * as Range from "./range.js";
import type { Span, Block } from "./elements"
import type { Point } from "./point"

function arrayPopIndex(items: any[], index: number) {
  const pre = items.slice(0, index);
  const post = items.slice(index + 1);
  const item = items[index];
  return [pre, item, post]
}

function splitText(text: string, offset: number) {
  const pre = text.slice(0, offset);
  const post = text.slice(offset);
  return [pre, post]
}
function splitSpans(spans: Span[], j: number, offset: number) {
  const [pre, span, post] = arrayPopIndex(spans, j);
  const [preText, postText] = splitText(span.text, offset)
  return [
    [...pre, { ...span, text: preText }],
    [{ ...span, text: postText }, ...post]
  ]
}
function splitBlocks(blocks: Block[], { path, offset }: Point) {
  const [i, j, ...none] = path
  if (none.length !== 0) {
    throw "extractBlocks only works in paragraphs for now"
  }
  const [pre, paragraph, post] = arrayPopIndex(blocks, i);
  const [preSpans, postSpans] = splitSpans(paragraph.spans, j, offset)
  return [
    [...pre, { ...paragraph, spans: preSpans }],
    [{ ...paragraph, spans: postSpans }, ...post]
  ]
}

export function extractBlocks(blocks: Block[], range: Range.Range) {
  const [start, end] = Range.edges(range);
  const [tempBlocks, postBlocks] = splitBlocks(blocks, end)
  const [preBlocks, slicedBlocks] = splitBlocks(tempBlocks, start)
  return [preBlocks, slicedBlocks, postBlocks]
}

export function summary(blocks: Block[]): Span[] {
  let first: Block = blocks[0]
  // TODO non empty list types
  if (!first) {
    return []
  }
  if (first.type === "paragraph") {
    let firstBreak = first.spans.findIndex(function (span: Span) {
      return span.type === "softbreak"
    })
    if (firstBreak === -1) {
      return first.spans
    } else {
      return first.spans.slice(0, firstBreak)
    }
  } else if (first.type === "annotation") {
    return summary(first.blocks)
  } else {
    return [{ type: "text", text: "TODO summary of nested" }]
  }
}