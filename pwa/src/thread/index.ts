import { ANNOTATION, LINK, PARAGRAPH, TEXT, PROMPT } from "../note/elements"
import type { Block, Link, Span, Annotation } from "../note/elements"
import type { Range } from "../note/range"
import type { Note } from "../note"
import * as Tree from "../note/tree"
// discussion/conversation has contributions
// thread has many messages/posts/notes/memo/entry/contribution

export type RangeReference = { note: number, range: Range }
export type SectionReference = { note: number, blockIndex: number }
export type Reference = RangeReference | SectionReference

// thread has many notes
// A note has many blocks and spans in a tree
export function followReference(reference: Reference, notes: { blocks: Block[] }[]) {
  let note = notes[reference.note]
  if ('blockIndex' in reference) {
    // TODO return spans Know that it is a single thing
    let element = note.blocks[reference.blockIndex]
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
      } else if (block.type === PROMPT) {
        return []
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

export function summary(blocks: Block[]): Span[] {
  let first: Block = blocks[0]
  if (first.type === PARAGRAPH) {
    return first.spans
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

export function gatherPrompts(notes: Note[], viewer: string) {
  let output: { reference: SectionReference }[] = [];
  notes.forEach(function (note: Note, noteIndex: number) {
    if (note.author === viewer) {
      note.blocks.forEach(function (block: Block, blockIndex) {
        if (block.type === ANNOTATION) {
          console.log(block, output);
          output = output.filter(function (item) {
            let reference = item.reference
            if ('blockIndex' in block.reference) {
              return !(reference.note === block.reference.note && reference.blockIndex === block.reference.blockIndex)

            } else {
              throw "only range references supported so far"
            }
          })
        }
      })
    } else {
      note.blocks.forEach(function (block: Block, blockIndex) {
        if (block.type === PROMPT) {
          output.push({ reference: block.reference })
        }
      })

    }
  })
  return output
}