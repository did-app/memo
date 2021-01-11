import type { Reference } from "../../conversation/reference"
// import * as Writing from ".."

function getSelection(): Selection {
  const domSelection = window.getSelection()
  if (domSelection === null) {
    throw "Why would there be no selection"
  } else {
    return domSelection
  }
}

const domSelection = getSelection();

export function getSelected(root: HTMLElement) {
  const domRange = domSelection.getRangeAt(0)
  if (!domRange) {
    return undefined
  }

  const { startContainer, startOffset, endContainer, endOffset } = domRange;
  const startPath = root.contains(startContainer) ? pathFromNode(startContainer) : undefined;
  const endPath = root.contains(endContainer) ? pathFromNode(endContainer) : undefined;

  const anchor = startPath ? { ...startPath, offset: startOffset } : undefined
  const focus = endPath ? { ...endPath, offset: endOffset } : undefined
  return { anchor, focus }
}

export function getReference(root: HTMLElement): Reference | null {
  const selected = getSelected(root)

  if (selected && selected.anchor && selected.focus) {
    let { memoPosition: anchorPosition, ...anchor } = selected.anchor;
    let { memoPosition: focusPosition, ...focus } = selected.focus;

    if (anchorPosition === focusPosition) {
      let range = { anchor, focus }

      if (Writing.isCollapsed(range)) {
        let blockIndex = anchor.path[0]
        if (blockIndex === undefined) {
          return null
        }
        return { memoPosition: anchorPosition, blockIndex }
      } else {
        return { memoPosition: anchorPosition, range }
      }
    } else {
      return null
    }
  } else {
    return null
  }
}

function leafElement(node: Node): HTMLElement {
  // FIXME, is this bad
  let temp: any = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement
  return temp
}

function pathFromElement(element: HTMLElement) {
  const path: number[] = []

  while (element) {

    const { blockIndex, memoPosition } = element.dataset

    // switch to root
    if (blockIndex !== undefined) {
      path.unshift(parseInt(blockIndex))
    } else if (memoPosition !== undefined) {
      return { path }
    }

    let parent = element.parentElement
    if (parent === null) {
      return undefined
    }
    element = parent
  }

}


function pointFromDom(node: Node, domOffset: number) {
  const element = leafElement(node)
  const path = pathFromElement(element)
  const { spanOffset } = element.dataset
  const offset = parseInt(spanOffset || "0") + domOffset
  return { path, offset }
}

export function rangeFromDom(domRange: Range) {
  const { startContainer, startOffset, endContainer, endOffset } = domRange;
  const anchor = pointFromDom(startContainer, startOffset)
  const focus = pointFromDom(endContainer, endOffset)
  return { anchor, focus }
}