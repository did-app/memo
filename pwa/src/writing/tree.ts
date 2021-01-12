import type { Range } from "./range";
import * as range_module from "./range"
import type { Span, Block } from "./elements"
// import type { Point } from "./point"
import * as point_module from "./point"


export function arrayPopIndex<T>(items: T[], index: number): [T[], T, T[]] | null {
  const pre = items.slice(0, index);
  const post = items.slice(index + 1);
  const item = items[index];
  if (item !== undefined) {
    return [pre, item, post]
  } else {
    return null
  }
}
const possible = RegExp("(https://[^\\s]+)\\s|([^\\.\\?]+\\?(\\s|$))\\s", "g")

export function appendSpans(blocks: Block[], joinSpan: Span, newSpans: Span[]): Block[] {
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

// function splitText(text: string, offset: number): [string, string] {
//   const pre = text.slice(0, offset);
//   const post = text.slice(offset);
//   return [pre, post]
// }

// function splitSpans(spans: Span[], j: number, offset: number): [Span[], Span[]] {
//   const [pre, span, post] = arrayPopIndex(spans, j);
//   let preSpan: Span, postSpan: Span;
//   if (span.type === "text") {
//     const [preText, postText] = splitText(span.text, offset)
//     preSpan = { ...span, text: preText }
//     postSpan = { ...span, text: postText }
//   } else if (span.type === 'link') {
//     const [preText, postText] = splitText(span.title || span.url, offset)
//     preSpan = { ...span, title: preText }
//     postSpan = { ...span, title: postText }
//   } else {
//     preSpan = span
//     postSpan = span
//   }
//   return [[...pre, preSpan], [postSpan, ...post]]
// }
// function splitBlocks(blocks: Block[], { path, offset }: Point): [Block[], Block[]] {
//   const [i, j, ...none] = path
//   if (none.length !== 0) {
//     throw "extractBlocks only works in paragraphs for now"
//   }
//   if (!i) {
//     throw "i should always exist in a path"
//   }

//   const [pre, block, post] = arrayPopIndex(blocks, i);
//   let preBlock: Block, postBlock: Block;
//   if (block.type === 'paragraph') {
//     // NOTE Dragging down lines can get to a cursor that is outside a text block
//     const [preSpans, postSpans] = splitSpans(block.spans, j || 0, offset)
//     preBlock = { ...block, spans: preSpans }
//     postBlock = { ...block, spans: postSpans }
//   } else {
//     // Do we want to split annotations or only work inside?
//     throw "TODO split bigger blocks"
//   }

//   return [[...pre, preBlock], [postBlock, ...post]]
// }


// // TODO same as pop spans
export function summary(blocks: Block[]): Span[] {
  //   let first = blocks[0]
  //   if (!first) {
  //     return []
  //   }
  //   if (first.type === "paragraph") {
  //     let firstBreak = first.spans.findIndex(function (span: Span) {
  //       return span.type === "softbreak"
  //     })
  //     if (firstBreak === -1) {
  //       return first.spans
  //     } else {
  //       return first.spans.slice(0, firstBreak)
  //     }
  //   } else if (first.type === "annotation") {
  //     return summary(first.blocks)
  //   } else {
  return [{ type: "text", text: "TODO summary of nested" }]
  //   }
}

// function followPath(fragment: Block, path: number[]): Block | null {
//   const [index, ...rest] = path
//   if (index === undefined) {
//     return fragment
//   } else {
//     let child = 'blocks' in fragment && fragment.blocks[index]
//     return child ? followPath(child, rest) : null
//   }
// }
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
  throw "should get here"
}

function splitBlocks(blocks: Block[], point: Point): [Block[], Block[]] {
  const unnested = point_module.unnest(point)
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
}
function spanLength(span: Span): number {
  if ('text' in span) {
    return span.text.length + 1
  } else {
    return 0
  }
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