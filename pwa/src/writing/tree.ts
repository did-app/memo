import type { Range } from "./range";
import * as range_module from "./range"
import type { Span, Block } from "./elements"
import type { Point } from "./point"
import * as point_module from "./point"


export function arrayPopIndex<T>(items: T[], index: number): [T[], T | undefined, T[]] {
  const pre = items.slice(0, index);
  const post = items.slice(index + 1);
  const item = items[index];
  return [pre, item, post]
}
const possible = RegExp("(https?://[^\\s]+)\\s|([^\\.\\?]+\\?(\\s|$))\\s", "g")

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
    if ('text' in joinSpan) {

      buffer += joinSpan.text
    }
    let post = []
    if ('text' in postSpan) {
      buffer += postSpan.text
    } else {
      post = [postSpan]
    }

    let spans = comprehendText(buffer)
    return [...unmodifiedBlocks, { ...lastBlock, spans }]
  } else {
    const innerBlocks = appendSpans(lastBlock.blocks, joinSpan, newSpans)
    return [...unmodifiedBlocks, { ...lastBlock, blocks: innerBlocks }]
  }
}

export function comprehendText(buffer: string, matcher = possible): Span[] {
  if (buffer === "") {
    return [{ type: 'text', text: "" }]
  }
  let found = Array.from(buffer.matchAll(matcher))

  let current = 0
  let output: Span[] = []
  found.forEach(function (match) {
    const [all, plain] = match
    if (match.index == current) {

    } else {
      output.push({ type: 'text', text: buffer.slice(current, match.index) })
    }
    if (!plain) {
      throw "We haven't sorted this link out yet"
    }
    output.push({ type: 'link', url: plain })
    if (match.index === undefined) {
      throw "Why do you get an undefined index"
    }
    if (all === undefined) {
      throw "All should always b a thin"
    }
    current = match.index + all.length
  })
  if (current < buffer.length) {
    output.push({ type: 'text', text: buffer.slice(current) })
  }
  return output
}

export function summary(blocks: Block[]): Span[] {
  const [spans] = popLine(blocks)
  return spans
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

    let span = spans[0]
    if (span === undefined) {
      throw "no more spans"
    }
    spans = spans.slice(1)


    let length = spanLength(span)
    if (length >= offset) {
      // offset only changes if text exits, softbreak has length 0
      if ('text' in span) {

        let preText = span.text.slice(0, offset)
        let postText = span.text.slice(offset)

        return [
          [...pre, { ...span, text: preText }],
          [{ ...span, text: postText }, ...spans]
        ]
      } else {
        throw "split other things"
      }
    } else {
      pre.push(span)
      offset = offset - length
    }
  }
  return [pre, spans]
}

function splitBlocks(blocks: Block[], point: Point): [Block[], Block[]] {
  const unnested = point_module.unnest(point)
  if (!unnested) {
    throw "first should always exist in a path"
  }
  const [index, inner] = unnested


  const [pre, block, post] = arrayPopIndex(blocks, index);
  if (!block) {

    throw "invalid point"
  }

  if ('blocks' in block) {
    const [preChildren, postChildren] = splitBlocks(block.blocks, inner)
    return [[...pre, { ...block, blocks: preChildren }], [{ ...block, blocks: postChildren }, ...post]]
  } else {
    const [preChildren, postChildren] = splitSpans(block.spans, inner.offset)
    return [[...pre, { ...block, spans: preChildren }], [{ ...block, spans: postChildren }, ...post]]

  }
}
// TODO fix this weird
function spanLength(span: Span): number {
  if ('text' in span) {
    return span.text.length + 1
  } else {
    return 0
  }
}

export function lineLength(spans: Span[]): number {
  return spans.reduce(function (acc: number, span: Span) {
    if ('text' in span) {
      return acc + span.text.length
    } else {
      return acc
    }
  }, 0)
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