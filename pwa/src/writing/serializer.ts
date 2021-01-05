import type { Span, Block } from "./elements";

export function toString(blocks: Block[] | null): string {
  if (blocks === null) {
    return ""
  }
  return blocks.map(function (block) {
    if (block.type === "paragraph") {
      return block.spans.map(function (span: Span) {
        if (span.type === "text" && "text" in span) {
          return span.text
        } else if (span.type === "link" && "title" in span) {
          return ` [${span.title}](${span.url}) `
        } else if (span.type === "link" && "url" in span) {
          return " " + span.url + " "
        } else if (span.type === "softbreak") {
          return "\n"
        }
      }).join("").trim() + "\n"
    } else {
      throw "what an unexpected block type" + block.type
    }
  }).join("\n")
}
