import type { Block, Span } from "../elements"
import type { Range } from "../range"
import * as range_module from "../range"
import type { Point } from "../point"
import { arrayPopIndex } from "../tree"

const possible = RegExp("(https://[^\\s]+)\\s|([^\\.\\?]+\\?(\\s|$))\\s", "g")

export function insertText(blocks: Block[], range: Range, text: string): [Block[], Point] {
  let common = popCommon(range)
  if (common) {
    let [index, innerRange] = common
    let child = blocks[index]
    if (child && 'blocks' in child) {
      return insertText(child.blocks, innerRange, text)
    }
  }
  // blocks aren't necessarily paragraphs but because we have checked common when know splitting is the right thing to do.
  const [preBlocks, _slice, postBlocks] = extractBlocks(blocks, range)

  const [bumpedSpans, remainingBlocks] = popLine(postBlocks);
  blocks = appendSpans(preBlocks, { type: 'text', text: text }, bumpedSpans).concat(remainingBlocks)


  // Normalizing spans doesn't change length BUT pulling square brackets out to a link would
  return [blocks, range.anchor]
}

function appendSpans(blocks: Block[], joinSpan: Span, newSpans: Span[]): Block[] {
  const unmodifiedBlocks = blocks.slice(0, -1)
  const lastBlock = blocks[blocks.length - 1] || { type: 'paragraph', spans: [] };


  if ("spans" in lastBlock) {
    // const spans = normalizeSpans([...lastBlock.spans, ...newSpans])
    let preSpan = lastBlock.spans[lastBlock.spans.length - 1] || { type: 'text', text: "" }
    let postSpan = newSpans[0] || { type: "text", text: "" }
    let buffer = ""
    let pre = []
    if ('text' in preSpan) {
      buffer = preSpan.text
    } else {
      pre = [preSpan]
    }
    buffer += joinSpan.text
    let post = []
    if ('text' in postSpan) {
      buffer += postSpan.text
    } else {
      post = [postSpan]
    }
    let spans: Span[] = [{ type: 'text', text: buffer }]
    let found = Array.from(buffer.matchAll(possible))


    return [...unmodifiedBlocks, { ...lastBlock, spans }]
  } else {
    const innerBlocks = appendSpans(lastBlock.blocks, joinSpan, newSpans)
    return [...unmodifiedBlocks, { ...lastBlock, blocks: innerBlocks }]
  }
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




export function popLine(blocks: Block[]): [Span[], Block[]] {
  const [head, ...remainingBlocks] = blocks
  if (head === undefined) {
    return [[], []]
  }
  if ("spans" in head) {
    return [head.spans, remainingBlocks]
  } else {
    const [spans, innerBlocks] = popLine(head.blocks)
    if (innerBlocks.length !== 0) {
      return [spans, [{ ...head, blocks: innerBlocks }, ...remainingBlocks]]
    } else {
      return [spans, remainingBlocks]
    }
  }
}

export function extractBlocks(blocks: Block[], range: Range): [Block[], Block[], Block[]] {
  const [start, end] = range_module.edges(range)
  const [tempBlocks, postBlocks] = splitBlocks(blocks, end)
  const [preBlocks, slicedBlocks] = splitBlocks(tempBlocks, start)
  return [preBlocks, slicedBlocks, postBlocks]
}

function splitSpans(spans: Span[], offset: number): [Span[], Span[]] {
  const pre: Span[] = []
  // What do we do with an empty span? keep normalise might work.
  while (offset >= 0) {
    console.log(spans);

    let span = spans[0]
    if (span === undefined) {
      throw "no more spans"
    }
    spans = spans.slice(1)


    let length = spanLength(span)
    if (length >= offset) {
      // offset only changes if text exits, softbreak has length 0
      let preText = span.text.slice(0, offset)
      let postText = span.text.slice(offset)

      return [
        [...pre, { ...span, text: preText }],
        [{ ...span, text: postText }, ...spans]
      ]
    } else {
      pre.push(span)
      offset = offset - length
    }
  }
}

function splitBlocks(blocks: Block[], point: Point): [Block[], Block[]] {
  const unnested = unnest(point)
  if (!unnested) {
    throw "first should always exist in a path"
  }
  const [index, inner] = unnested

  const popped = arrayPopIndex(blocks, index);
  if (!popped) {
    throw "invalid point"
  }
  const [pre, block, post] = popped

  if ('blocks' in block) {
    const [preChildren, postChildren] = splitBlocks(block.blocks, inner)
    return [[...pre, { ...block, blocks: preChildren }], [{ ...block, blocks: postChildren }, ...post]]
  } else {
    const [preChildren, postChildren] = splitSpans(block.spans, inner.offset)
    return [[...pre, { ...block, spans: preChildren }], [{ ...block, spans: postChildren }, ...post]]

  }
  // block.spans

  // let preBlock: Block, postBlock: Block;
  // if (block.type === 'paragraph') {
  //   // NOTE Dragging down lines can get to a cursor that is outside a text block
  //   const [preSpans, postSpans] = splitSpans(block.spans, j || 0, offset)
  //   preBlock = { ...block, spans: preSpans }
  //   postBlock = { ...block, spans: postSpans }
  // } else {
  //   // Do we want to split annotations or only work inside?
  //   throw "TODO split bigger blocks"
  // }

  // return [[...pre, preBlock], [postBlock, ...post]]
}

function updateBlock(fragment: Doc, path: number[]): Doc
function updateBlock(fragment: Block, path: number[]): Block
function updateBlock(fragment: Doc | Block, path: number[]): Doc | Block {
  // if ('blocks' in ) {

  // } else {

  // }
  // const [index, ...rest] = path
  // if (index === undefined) {
  //   return fragment
  // } else {
  //   // let child = 
  //   // Can't de union a T
  //   if ('blocks' in fragment) {
  //     fragment.blocks[index]
  //   }
  //   // return child ? followPath(child, rest) : null
  //   if (child) {
  //     let pre = fragment.blocks.slice(0, index)
  //     let post = fragment.blocks.slice(index + 1)
  //     let blocks = [...pre, updateBlock(child, rest), ...post]
  //     return { ...fragment, blocks }
  //   } else {
  //     return fragment
  //   }
  // }
}


function followPath(fragment: Block, path: number[]): Block | null {
  const [index, ...rest] = path
  if (index === undefined) {
    return fragment
  } else {
    let child = 'blocks' in fragment && fragment.blocks[index]
    return child ? followPath(child, rest) : null
  }
}

function commonPath(range: Range, acc: number[] = []): [number[], Range] {
  const result = popCommon(range)
  if (result) {
    return commonPath(result[1], [...acc, result[0]])
  } else {
    return [acc, range]
  }
}

function popCommon(range: Range): [number, Range] | null {
  let { anchor, focus } = range
  const anchorResult = unnest(anchor);
  const focusResult = unnest(focus);
  if (anchorResult && focusResult && anchorResult[0] === focusResult[0]) {
    return [anchorResult[0], { anchor: anchorResult[1], focus: focusResult[1] }]
  } else {
    return null
  }
}

function unnest(point: Point): [number, Point] | null {
  const { path, offset } = point
  let [index, ...rest] = path
  if (index !== undefined) {
    return [index, { path: rest, offset }]
  } else {
    return null
  }
}
function spanLength(span: Span): number {
  if ('text' in span) {
    return span.text.length + 1
  } else {
    return 0
  }
}