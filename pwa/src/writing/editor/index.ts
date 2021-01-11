import type { Block } from "../elements"
import type { Point } from "../point"
import type { Range } from "../range"

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
    // TODO our rich quoting
  } else if (inputType === "insertFromDrop") {
    let replacement = dataTransfer && dataTransfer.getData("text/plain") || ""
    return insertText(blocks, range, replacement)
    // TODO our rich quoting
  } else if (inputType === "insertParagraph") {
    return insertParagraph(blocks, range)
  } else if (inputType === "insertLineBreak") {
    return insertParagraph(blocks, range)
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


