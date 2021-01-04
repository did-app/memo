import { ANNOTATION, LINK, PARAGRAPH, TEXT, PROMPT, SOFTBREAK } from "../memo/elements"
import type { Block, Link, Span, Annotation } from "../memo/elements"
import type { Range } from "../memo/range"
import type { Memo } from "../memo"
import * as Tree from "../memo/tree"
// discussion/conversation has contributions
// thread has many messages/posts/notes/memo/entry/contribution

export type SectionReference = { memoPosition: number, blockIndex: number }
export type RangeReference = { memoPosition: number, range: Range }
export type Reference = RangeReference | SectionReference

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
    return Tree.extractBlocks(memo.content, reference.range)[1]
  }
}


export type Pin = { threadPosition: number, type: typeof LINK, item: Link } | { threadPosition: number, type: typeof ANNOTATION, item: Annotation }
export function findPinnable(memos: Memo[]): Pin[] {
  return memos.map(function (memo, threadPosition): Pin[] {
    return memo.content.map(function (block): Pin[] {
      if (block.type === ANNOTATION) {
        return [{ threadPosition, type: ANNOTATION, item: block }]
      } else if (block.type === PROMPT) {
        return []
      } else {

        return block.spans.flatMap(function name(span: Span) {
          if (span.type === LINK) {
            return [{ threadPosition, type: LINK, item: span }]
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
  if (first.type === PARAGRAPH) {
    let firstBreak = first.spans.findIndex(function (span: Span) {
      return span.type === SOFTBREAK
    })
    if (firstBreak === -1) {
      return first.spans
    } else {
      return first.spans.slice(0, firstBreak)
    }
  } else if (first.type === ANNOTATION) {
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
    if (block.type === PARAGRAPH && block.spans.length > 0) {
      // always ends with softbreak
      const lastSpan = block.spans[block.spans.length - 1];
      if (lastSpan.type === TEXT && lastSpan.text.endsWith("?")) {
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
        if (block.type === ANNOTATION) {
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
        if (block.type === PROMPT) {
          output.push({ reference: block.reference })
        }
      })

    }
  })
  return output
}