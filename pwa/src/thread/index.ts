import { ANNOTATION, LINK } from "../note/elements"
import type { Block, Link, Span, Annotation } from "../note/elements"
import type { Range } from "../note/range"
import type { Note } from "../note"
import * as Tree from "../note/tree"
// discussion/conversation has contributions
// thread has many messages/posts/notes/memo/entry/contribution

export type Reference = { note: number, range: Range } | { note: number, path: number[] }

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

export type Pin = { noteIndex: number, type: typeof LINK, item: Link } | { noteIndex: number, type: typeof ANNOTATION, item: Annotation }
export function findPinnable(notes: Note[]): Pin[] {
  return notes.map(function (note, noteIndex): Pin[] {
    return note.blocks.map(function (block): Pin[] {
      if (block.type === ANNOTATION) {
        return [{ noteIndex, type: ANNOTATION, item: block }]
      } else {

        return block.spans.flatMap(function name(span: Span) {
          if (span.type === LINK) {
            return [{ noteIndex, type: LINK, item: span }]
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