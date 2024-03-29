import type { Span, Block } from "./elements"

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
      output.push({ type: "text", text: unmatched })
    }
    if (token[3] !== undefined) {
      output.push({ type: "link", url: token[3] })
    } else if (token[2] !== undefined) {
      output.push({ type: "link", url: token[2], title: token[1] })
    } else {
      throw "should be handled"
    }
  }
  const unmatched = line.substring(cursor).trim()
  if (unmatched) {
    output.push({ type: "text", text: unmatched })
  }
  return output
}

export function parse(draft: string): null | Block[] {
  draft = draft.trim()
  if (draft.length === 0) {
    return null
  }
  const { doc, node } = draft.split(/\n/).reduce(function ({ doc, node, offset }: any, line) {
    if (line.trim() == "") {
      // close node
      if (node.type === "paragraph") {
        doc.push(node)
        node = false
      } else {
        // do nothing no node
      }

    } else {
      // append line
      node = node || { type: "paragraph", spans: [] }
      // Called softbreak from markdown even thought rendered with br
      if (node.spans.length === 0) {
        node.spans = node.spans.concat(...parseLine(line, offset))
      } else {
        node.spans = node.spans.concat({ type: "softbreak" }, ...parseLine(line, offset))
      }
    }
    // plus one for the newline
    offset = offset + line.length + 1
    return { doc, node, offset }
  }, { doc: [], node: { type: "paragraph", spans: [] }, offset: 0 })
  // close node
  if (node.type === "paragraph") {
    doc.push(node)
  }
  return doc
}