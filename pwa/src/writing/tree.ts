import type { Range } from "./range";
import * as range_module from "./range"
import type { Span, Block } from "./elements"
import type { Path } from "./path"
import type { Point } from "./point"
import * as point_module from "./point"


export function arrayPopIndex<T>(items: T[], index: number): [T[], T | undefined, T[]] {
  const pre = items.slice(0, index);
  const post = items.slice(index + 1);
  const item = items[index];
  return [pre, item, post]
}

export function spanFromOffset(spans: Span[], offset: number): [number, number] {
  let index = 0
  let remaining = offset
  while (remaining > 0) {
    let span = spans[0]
    spans = spans.slice(1)
    if (!span) {
      throw "I think there should be a span"
    }
    if ('text' in span) {
      let length = span.text.length
      if (length < remaining) {
        remaining = remaining - length
        index = index + 1
      } else {
        break
      }
    } else {
      // Links count as length one items and we skip over them as much as possible so the cursor is in spans either side.
      // Because they have length one they can be caught in ranges for deletion
      remaining = remaining - 1
      index = index + 1
    }
  }
  return [index, remaining]
}

// https://www.smashingmagazine.com/2019/02/regexp-features-regular-expressions/#lookbehind-assertions
// lookahead assertion
const possible = RegExp("(https?://[^\\s]+)(?=\\s)|([^\\.\\?]+\\?(\\s|$))(?=\\s)", "g")

export function appendSpans(blocks: Block[], joinSpan: Span, newSpans: Span[]): [Block[], number] {
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
    let post: Span[] = []
    if ('text' in postSpan) {
      buffer += postSpan.text
    } else {
      post = [postSpan]
    }
    post = post.concat(newSpans.slice(1))

    let [spans, removed] = comprehendText(buffer)
    spans = lastBlock.spans.slice(0, -1).concat(spans).concat(post)
    return [[...unmodifiedBlocks, { ...lastBlock, spans }], removed]
  } else {
    const [innerBlocks, removed] = appendSpans(lastBlock.blocks, joinSpan, newSpans)
    return [[...unmodifiedBlocks, { ...lastBlock, blocks: innerBlocks }], removed]
  }
}

export function comprehendText(buffer: string, matcher = possible): [Span[], number] {
  if (buffer === "") {
    let span: Span = { type: 'text', text: "" }
    return [[span], 0]
  }
  let found = Array.from(buffer.matchAll(matcher))

  let current = 0
  let output: Span[] = []
  let removed = 0
  found.forEach(function (match) {
    const [all, plain] = match
    if (match.index == current) {

    } else {
      output.push({ type: 'text', text: buffer.slice(current, match.index) })
    }
    let matchedText = match[0]
    if (matchedText === undefined) {
      throw "there should be some text, otherwise it wouldn't be a match"
    }
    removed = removed + matchedText.length - 1
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

  return [output, removed]
}

export function summary(blocks: Block[]): Span[] {
  const [spans] = popLine(blocks)
  return spans
}

export function elementAtPoint(blocks: Block[], point: Point) {
  try {
    let line = getLine(blocks, point.path)
    let [index] = spanFromOffset(line, point.offset)
    return line[index]
  } catch (error) {
    console.warn(error)
  }
}

export function extractBlocks(blocks: Block[], range: Range): [Block[], Block[], Block[]] {
  const [start, end] = range_module.edges(range)
  const [tempBlocks, postBlocks] = splitBlocks(blocks, end)
  const [preBlocks, slicedBlocks] = splitBlocks(tempBlocks, start)
  return [preBlocks, slicedBlocks, postBlocks]
}

export function splitSpans(spans: Span[], offset: number): [Span[], Span[]] {

  const pre: Span[] = []
  // What do we do with an empty span? keep normalise might work.
  while (offset >= 0) {

    let span = spans[0]
    if (span === undefined) {
      return [pre, []]
    }
    spans = spans.slice(1)


    if ('text' in span) {
      if (span.text.length >= offset) {
        let preText = span.text.slice(0, offset)
        let postText = span.text.slice(offset)

        return [
          [...pre, { ...span, text: preText }],
          [{ ...span, text: postText }, ...spans]
        ]
      } else {
        pre.push(span)
        offset = offset - span.text.length

      }
    } else {
      if (offset === 1) {
        return [
          [...pre, span],
          spans
        ]
      } else {
        pre.push(span)
        offset = offset - 1
      }
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

export function getLine(blocks: Block[], path: Path): Span[] {
  const [index, ...rest] = path
  if (index === undefined) {
    throw "Could not get line"
  }
  let block = blocks[index]
  if (!block) {
    throw "invalid path"
  }
  if ('spans' in block) {
    return block.spans
  } else {
    return getLine(block.blocks, rest)
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