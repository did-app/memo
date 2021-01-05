import type { Block, Link, Span, Annotation } from "../writing"
import * as Writing from "../writing";
import type { Memo } from "./memo"
import type { Reference, SectionReference } from "./reference"

export function maxPosition(memos: Memo[]) {
  // This assumes position has been added properly, that memos are in order and positions are continuous
  return memos.length
}

// thread has many memos
// A memo has many blocks and spans in a tree
export function followReference(reference: Reference, memos: { content: Block[] }[]) {
  let memo = memos[reference.memoPosition]
  if ('blockIndex' in reference) {
    // TODO return spans Know that it is a single thing
    let element = memo.content[reference.blockIndex]
    return [element]
  } else {
    return Writing.extractBlocks(memo.content, reference.range)[1]
  }
}


export type Pin = { threadPosition: number, type: "link", item: Link } | { threadPosition: number, type: "annotation", item: Annotation }
export function findPinnable(memos: Memo[]): Pin[] {
  return memos.map(function (memo, threadPosition): Pin[] {
    return memo.content.map(function (block): Pin[] {
      if (block.type === "annotation") {
        return [{ threadPosition, type: "annotation", item: block }]
      } else if (block.type === "prompt") {
        return []
      } else {

        return block.spans.flatMap(function name(span: Span) {
          if (span.type === "link") {
            return [{ threadPosition, type: "link", item: span }]
          } else {
            return []
          }
        })
      }
    })
      .flat()
  })
    .flat()
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

export type Question = {
  blockIndex: number,
  spans: Span[]
}
export function makeSuggestions(blocks: Block[]): Question[] {
  const output: Question[] = [];
  blocks.forEach(function (block, blockIndex) {
    if (block.type === "paragraph" && block.spans.length > 0) {
      // always ends with softbreak
      const lastSpan = block.spans[block.spans.length - 1];
      if (lastSpan.type === "text" && lastSpan.text.endsWith("?")) {
        // TODO remove start
        let suggestion = {
          blockIndex,
          spans: block.spans,
        };
        output.push(suggestion);
      }
    }
  });
  return output;
}

export function gatherPrompts(memos: Memo[], viewer: string) {
  let output: { reference: SectionReference }[] = [];
  memos.forEach(function (memo: Memo, threadPosition: number) {
    if (memo.author === viewer) {
      memo.content.forEach(function (block: Block) {
        if (block.type === "annotation") {
          console.log(block, output);
          output = output.filter(function (item) {
            let reference = item.reference
            if ('blockIndex' in block.reference) {
              return !(reference.memoPosition === block.reference.memoPosition && reference.blockIndex === block.reference.blockIndex)

            } else {
              throw "only range references supported so far"
            }
          })
        }
      })
    } else {
      memo.content.forEach(function (block: Block) {
        if (block.type === "prompt") {
          output.push({ reference: block.reference })
        }
      })

    }
  })
  return output
}