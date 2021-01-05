import type { Block, Link, Span, Annotation } from "../writing"
import * as Writing from "../writing";
import type { Memo } from "./memo"
import type { Reference } from "./reference"

export type Thread = {
  id: number
  latest: Memo | null,
  acknowledged: number
}

export function isOutstanding(thread: Thread): boolean {
  const { latest, acknowledged } = thread
  if (latest) {
    return latest.position > acknowledged
  } else {
    return false
  }
}

export function followReference(reference: Reference, memos: Memo[]) {
  // position is indexed from 1
  let memo = memos[reference.memoPosition - 1]
  if ('blockIndex' in reference) {
    let element = memo.content[reference.blockIndex]
    return [element]
  } else {
    return Writing.extractBlocks(memo.content, reference.range)[1]
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
  let output: { reference: Reference }[] = [];
  memos.forEach(function (memo: Memo, threadPosition: number) {
    if (memo.author === viewer) {
      memo.content.forEach(function (block: Block) {
        if (block.type === "annotation") {
          output = output.filter(function (item) {
            let reference = item.reference
            if ('blockIndex' in block.reference) {
              // return !(reference.memoPosition === block.reference.memoPosition && reference.blockIndex === block.reference.blockIndex)

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