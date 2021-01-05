import type { Block, Prompt } from "../writing"
import * as Writing from "../writing";
import type { Memo } from "./memo"
import type { Reference } from "./reference"
import { equal } from "./reference"

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
// There is no type that is range or section at the individual memo level
export function makeSuggestions(blocks: Block[], memoPosition: number): Prompt[] {
  const output: Prompt[] = [];
  blocks.forEach(function (block, blockIndex) {
    if (block.type === "paragraph" && block.spans.length > 0) {
      // always ends with softbreak
      const lastSpan = block.spans[block.spans.length - 1];
      if (lastSpan.type === "text" && lastSpan.text.endsWith("?")) {
        output.push({ type: "prompt", reference: { blockIndex, memoPosition } });
      }
    }
  });
  return output;
}

export function gatherPrompts(memos: Memo[], viewer: string) {
  let output: Reference[] = [];
  memos.forEach(function (memo: Memo, threadPosition: number) {
    if (memo.author === viewer) {
      memo.content.forEach(function (block: Block) {
        if (block.type === "annotation") {
          console.log(block);

          output = output.filter(function (reference: Reference) {
            return !equal(reference, block.reference)
          })
        }
      })
    } else {
      memo.content.forEach(function (block: Block) {
        if (block.type === "prompt") {

          output.push(block.reference)
        }
      })
    }
    console.log(output);
  })

  return output
}