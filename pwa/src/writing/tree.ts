import * as Range from "./range.js";
// import type { Span, Block } from "./elements"
// import type { Point } from "./point"

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

export function extractBlocks(blocks: Block[], range: Range.Range): [Block[], Block[], Block[]] {
  // const [start, end] = Range.edges(range);
  // const [tempBlocks, postBlocks] = splitBlocks(blocks, end)
  // const [preBlocks, slicedBlocks] = splitBlocks(tempBlocks, start)
  // return [preBlocks, slicedBlocks, postBlocks]
  [[], [], []]
}

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