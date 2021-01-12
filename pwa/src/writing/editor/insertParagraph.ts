import type { Block, Span } from "../elements"
import type { Range } from "../range"
import * as range_module from "../range"
import type { Point } from "../point"
import * as point_module from "../point"
import { arrayPopIndex, appendSpans, extractBlocks, popLine } from "../tree"

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
  const [preBlocks, _slice, postBlocks] = extractBlocks(blocks, range)
  const [bumpedSpans, remainingBlocks] = popLine(postBlocks);
  // paragraph might be better called a line if in lists

  const newBlock: Block = { type: 'paragraph', spans: bumpedSpans }
  if (start.offset == 0) {
    // split will leave an empty one, which is fine
    // Will also exit list which is fine
    return [preBlocks, [newBlock, ...remainingBlocks], { path: [], offset: 0 }]
  } else {

    blocks = [...preBlocks, newBlock, ...remainingBlocks]
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
    return [[...updated.slice(0, -1), ...lifted], point_module.nest(updated.length - 1, cursor)]
  }
}

