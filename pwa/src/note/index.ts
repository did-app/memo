import { PARAGRAPH, TEXT, LINK, SOFTBREAK } from "./elements"
import type { Block, Span, Paragraph } from "./elements"

export type Note = {
  author: string,
  blocks: Block[],
  inserted_at: Date,
  counter: number
}

function parseLine(line: string, offset: number) {
  // Can't end with |(.+\?) because question capture will catch all middle links
  // Questionmark in the body of a link causes confusion, not good if people are making their own questions
  // const tokeniser = /(?:\[([^\[]+)\]\(([^\(]*)\))|(?:(?:\s|^)(https?:\/\/[\w\d./?=#]+))|(^.+\?)/gm
  const tokeniser = /(?:\[([^\[]*)\]\(([^\(]+)\))|(?:(?:\s|^)(https?:\/\/[\w\d-./?=#]+))/gm
  const output: Span[] = []
  let cursor = 0;
  let token
  while (token = tokeniser.exec(line)) {
    const unmatched = line.substring(cursor, token.index).trim()
    cursor = tokeniser.lastIndex
    const start = offset + token.index
    let range = document.createRange()

    if (unmatched) {
      output.push({ type: TEXT, text: unmatched, start })
    }
    if (token[3] !== undefined) {
      output.push({ type: LINK, url: token[3], start })
    } else if (token[2] !== undefined) {
      output.push({ type: LINK, url: token[2], title: token[1], start })
    } else {
      throw "should be handled"
    }
  }
  const unmatched = line.substring(cursor).trim()
  if (unmatched) {
    output.push({ type: TEXT, text: unmatched })
  }
  return output
}

export function parse(draft: string): null | Block[] {
  draft = draft.trim()
  if (draft.length === 0) {
    return null
  }
  // TODO remove any
  const { doc, node } = draft.split(/\n/).reduce(function ({ doc, node, offset }: any, line) {
    if (line.trim() == "") {
      // close node
      if (node.type === PARAGRAPH) {
        doc.push(node)
        node = false
      } else {
        // do nothing no node
      }

    } else {
      // append line
      node = node || { type: PARAGRAPH, spans: [] }
      // TODO merge same text
      // Called softbreak from markdown even thought rendered with br
      if (node.spans.length === 0) {
        node.spans = node.spans.concat(...parseLine(line, offset))
      } else {
        node.spans = node.spans.concat({ type: SOFTBREAK }, ...parseLine(line, offset))
      }
    }
    // plus one for the newline
    offset = offset + line.length + 1
    return { doc, node, offset }
  }, { doc: [], node: { type: PARAGRAPH, spans: [] }, offset: 0 })
  // close node
  if (node.type === PARAGRAPH) {
    doc.push(node)
  }
  return doc
}

export function toString(blocks: Block[] | null): string {
  if (blocks === null) {
    return ""
  }
  return blocks.map(function (block) {
    if (block.type === PARAGRAPH) {
      return block.spans.map(function (span: Span) {
        if (span.type === TEXT && "text" in span) {
          return span.text
        } else if (span.type === LINK && "title" in span) {
          return ` [${span.title}](${span.url}) `
        } else if (span.type === LINK && "url" in span) {
          return " " + span.url + " "
        } else if (span.type === SOFTBREAK) {
          return "\n"
        }
      }).join("").trim() + "\n"
    } else {
      throw "what an unexpected block type" + block.type
    }
  }).join("\n")
}
