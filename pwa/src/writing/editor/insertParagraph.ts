import type { Block, Span } from "../elements"
import type { Range } from "../range"
import * as range_module from "../range"
import type { Point } from "../point"
import * as point_module from "../point"
import { arrayPopIndex, appendSpans, extractBlocks, popLine, lineLength, comprehendText } from "../tree"

function insertAndLift(blocks: Block[], range: Range): [Block[], Block[], Point] {
  let common = range_module.popCommon(range)
  if (common !== null) {
    let [index, innerRange] = common
    let [pre, child, post] = arrayPopIndex(blocks, index)
    if (child && 'blocks' in child) {
      const [updated, lifted, innerCursor] = insertAndLift(child.blocks, innerRange)

      child = { ...child, blocks: updated }
      let cursor: Point
      if (lifted.length === 0) {
        cursor = point_module.nest(pre.length, innerCursor)
      } else {
        cursor = point_module.nest(pre.length + 1, innerCursor)
      }
      return [[...pre, child, ...lifted, ...post], [], cursor]
    }
  }

  const [start, end] = range_module.edges(range)
  let [preBlocks, _slice, postBlocks] = extractBlocks(blocks, range)
  preBlocks = comprehendLast(preBlocks)

  const [bumpedSpans, remainingBlocks] = popLine(postBlocks);
  // paragraph might be better called a line if in lists

  const newBlock: Block = { type: 'paragraph', spans: bumpedSpans }
  let afterBlocks: Block[];
  // Merge empty lines after the linebreak
  const firstRemaining = remainingBlocks[0]

  if (firstRemaining && 'spans' in firstRemaining && lineLength(firstRemaining.spans) === 0 && lineLength(bumpedSpans) === 0) {
    afterBlocks = [newBlock, ...remainingBlocks.slice(1)]
  } else {
    afterBlocks = [newBlock, ...remainingBlocks]
  }

  if (start.offset == 0) {
    // Will also exit list which is fine
    // Don't leve an empty line when exiting lists, annotations
    if (preBlocks.length > 1) {
      return [preBlocks.slice(0, -1), afterBlocks, { path: [], offset: 0 }]
    } else {
      return [preBlocks, afterBlocks, { path: [], offset: 0 }]
    }
  } else {

    blocks = [...preBlocks, ...afterBlocks]
    // throw "insert paragraph"
    // if start has offset zero move line to parent
    return [blocks, [], { path: [preBlocks.length], offset: 0 }]
  }

}

export function insertParagraph(blocks: Block[], range: Range): [Block[], Point] {
  const [updated, lifted, cursor] = insertAndLift(blocks, range)

  if (lifted.length === 0) {
    return [updated, cursor]
  } else {
    return [[...updated, ...lifted], point_module.nest(updated.length, cursor)]
  }
}


function comprehendLast(blocks: Block[]): Block[] {
  let lastBlock = blocks[blocks.length - 1]
  if (!lastBlock || !('spans' in lastBlock)) {
    return blocks
  }
  let spans = lastBlock.spans
  let lastSpan = spans[spans.length - 1]
  if (!lastSpan || !('text' in lastSpan)) {
    return blocks
  }
  // This space is a bit of a hack, because we don't want the regex matching on end of line in normal serches

  // spans = spans.slice(0, -1).concat(comprehendText(lastSpan.text, RegExp("(https?://[^\\s]+)\\s", "g")))
  spans = spans.slice(0, -1).concat(comprehendText(lastSpan.text, /(https?:\/\/[^\s]+)$/g))

  lastBlock = { ...lastBlock, spans }
  return blocks.slice(0, -1).concat(lastBlock)
}