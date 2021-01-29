import type { Reference } from "../../conversation"

import type { Block } from "../elements"
import type { Point } from "../point"
import type { Range } from "../range"
import { lineLength } from "../tree"

import { insertText } from "./insertText"
import { insertParagraph } from "./insertParagraph"

type Event = {
  inputType: string
  data: string | null
  dataTransfer: DataTransfer | null
}

export function handleInput(blocks: Block[], range: Range, event: Event): [Block[], Point] {
  const { inputType, data, dataTransfer } = event
  if (inputType === "insertText") {
    return insertText(blocks, range, data || "")
  } else if (inputType === "insertReplacementText") {
    let replacement = dataTransfer && dataTransfer.getData("text/plain") || ""
    return insertText(blocks, range, replacement)
  } else if (inputType === "insertFromPaste") {
    let replacement = dataTransfer && dataTransfer.getData("text/plain") || ""
    return insertText(blocks, range, replacement)
  } else if (inputType === "insertFromDrop") {
    let replacement = dataTransfer && dataTransfer.getData("text/plain") || ""
    return insertText(blocks, range, replacement)
  } else if (inputType === "insertParagraph") {
    return insertParagraph(blocks, range)
  } else if (inputType === "insertLineBreak") {
    return insertParagraph(blocks, range)
  } else if (inputType === "insertCompositionText") {
    // This is rather simplistic, assumes composition text in format "stuff\r"
    let text = data || ""
    let newLine = false
    if (text.slice(-1) === "\n") {
      newLine = true
      text = text.slice(0, -1)
    }
    let [updated, cursor] = insertText(blocks, range, text)
    if (newLine) {
      return insertParagraph(updated, { anchor: cursor, focus: cursor })
    } else {
      return [updated, cursor]
    }
  } else if (inputType === "deleteContent") {
    return insertText(blocks, range, "")
  } else if (inputType === "deleteContentBackward") {
    return insertText(blocks, range, "")
  } else if (inputType === "deleteContentForward") {
    // Even with just a cursor the behaviour is to first change the selection
    // This is probably because I am using the event selection and not the getSelection from before
    return insertText(blocks, range, "")
  } else if (inputType === "deleteWordBackward") {
    return insertText(blocks, range, "")
  } else if (inputType === "deleteWordForward") {
    return insertText(blocks, range, "")
  } else if (inputType === "deleteHardLineBackward") {
    return insertText(blocks, range, "")
  } else if (inputType === "deleteHardLineForward") {
    return insertText(blocks, range, "")
  } else if (inputType === "deleteByCut") {
    return insertText(blocks, range, "")
  } else {
    console.warn("Unsupported input inputType: " + inputType)
    return [blocks, range.anchor]
  }
}

export function addAnnotation(blocks: Block[], reference: Reference): Block[] {
  return addBlock(blocks, {
    type: "annotation",
    reference,
    // This can probably be removed when fragment is collected to handle empty blocks
    blocks: [{ type: "paragraph", spans: [] }],
  })
}

export function addBlock(blocks: Block[], block: Block): Block[] {
  let lastBlock = blocks[blocks.length - 1];
  let before: Block[];
  if (
    lastBlock &&
    "spans" in lastBlock &&
    lineLength(lastBlock.spans) === 0
  ) {
    before = blocks.slice(0, -1);
  } else {
    before = blocks;
  }
  return [...before, block];
}