import type { Block } from "../note/elements"
import type { Range } from "../note/range"
import * as Tree from "../note/tree"
// discussion/conversation has contributions
// thread has many messages/posts/notes/memo/entry/contribution

type Reference = { note: number, range: Range } | { note: number, path: number[] }

// thread has many notes
// A note has many blocks and spans in a tree
export function followReference(reference: Reference, notes: { blocks: Block[] }[]) {
  let note = notes[reference.note]
  if ('path' in reference) {
    let [top, ...rest] = reference.path
    if (rest.length != 0) {
      throw "doesn't support deep path yet"
    }
    let element = note.blocks[top]
    return [element]
  } else {
    return Tree.extractBlocks(note.blocks, reference.range)[1]
  }
}
