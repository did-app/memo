import type { Block, Span } from "../elements"
import type { Range } from "../range"
import * as range_module from "../range"
import type { Point } from "../point"
import * as point_module from "../point"
import { arrayPopIndex, appendSpans, extractBlocks, popLine } from "../tree"

export function insertParagraph(blocks: Block[], range: Range): [Block[], Point] {
  const [start, end] = range_module.edges(range)
  // pop common and loop
  // splitAt
  const [preBlocks, _slice, postBlocks] = extractBlocks(blocks, range)
  const [bumpedSpans, remainingBlocks] = popLine(postBlocks);
  if (start.offset == 0) {
    // split will leave an empty one, which is fine
    // Will also exit list which is fine
    blocks = appendSpans(preBlocks, { type: 'text', text: "" }, bumpedSpans)
    return [blocks, start]
  } else {
    console.log(bumpedSpans, remainingBlocks.length);

    blocks = [...preBlocks, { type: 'paragraph', spans: bumpedSpans }, ...remainingBlocks]
    // throw "insert paragraph"
    // if start has offset zero move line to parent
    return [blocks, { path: [preBlocks.length], offset: 0 }]
  }
}

let blocks: Block[] = [
  { type: 'paragraph', spans: [{ type: 'text', text: "abc" }] }
]
let range: Range;
range = { anchor: { path: [0], offset: 1 }, focus: { path: [0], offset: 1 } }

console.log(...insertParagraph(blocks, range)[0], "result");
