import type { Block, Span } from "../elements"
import type { Range } from "../range"
import * as range_module from "../range"
import type { Point } from "../point"
import * as point_module from "../point"
import { appendSpans, extractBlocks, popLine } from "../tree"
import { arrayPopIndex } from "../tree"

export function insertText(blocks: Block[], range: Range, text: string): [Block[], Point] {
  let common = range_module.popCommon(range)
  if (common) {
    let [index, innerRange] = common
    let [pre, child, post] = arrayPopIndex(blocks, index)
    if (child && 'blocks' in child) {
      const [updated, innerCursor] = insertText(child.blocks, innerRange, text)
      child = { ...child, blocks: updated }
      const cursor = point_module.nest(index, innerCursor)
      return [[...pre, child, ...post], cursor]
    }
  }
  // blocks aren't necessarily paragraphs but because we have checked common when know splitting is the right thing to do.
  const [preBlocks, _slice, postBlocks] = extractBlocks(blocks, range)

  const [bumpedSpans, remainingBlocks] = popLine(postBlocks);
  blocks = appendSpans(preBlocks, { type: 'text', text: text }, bumpedSpans).concat(remainingBlocks)
  console.log(blocks, "BLOCKs");

  const [start] = range_module.edges(range)
  const cursor = { ...start, offset: start.offset + text.length }
  // Normalizing spans doesn't change length BUT pulling square brackets out to a link would
  return [blocks, cursor]
}

function normalizeSpans(spans: Span[]): Span[] {
  const output = []
  let current = spans[0]
  let next = spans[1]
  spans = spans.slice(2)
  if (current === undefined) {
    return []
  }
  while (next) {
    if ('text' in current && 'text' in next) {
      current = { ...current, text: current.text + next.text }
    } else {
      output.push(current)
      current = next
    }
    next = spans[0]
    spans = spans.slice(1)
  }
  output.push(current)
  return output
}
