function getSelection(): Selection {
  const domSelection = window.getSelection()
  if (domSelection === null) {
    throw "Why would there be no selection"
  } else {
    return domSelection
  }
}

const domSelection = getSelection();

// TODO could check with root element
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

function leafElement(node: Node): HTMLElement {
  // FIXME, is this bad
  let temp: any = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement
  return temp
}

function pathFromNode(node: Node) {
  const path: number[] = []

  let element = leafElement(node)
  while (element) {
    const { spanIndex, blockIndex, noteIndex } = element.dataset

    if (spanIndex !== undefined) {
      path.unshift(parseInt(spanIndex))
    } else if (blockIndex !== undefined) {
      path.unshift(parseInt(blockIndex))
    } else if (noteIndex !== undefined) {
      return { noteIndex: parseInt(noteIndex), path }
    }

    let parent = element.parentElement
    if (parent === null) {
      return undefined
    }
    element = parent
  }
}
