import type { Path } from "../path"
import type { Point } from "../point"
import type { Range as ModelRange } from "../range"


export type InputEvent = {
  getTargetRanges: () => [StaticRange]
  inputType: string,
  data: string | null,
  dataTransfer: DataTransfer | null
}

export function getSelection(): Selection {
  const domSelection = window.getSelection()
  if (domSelection === null) {
    throw "Why would there be no selection"
  } else {
    return domSelection
  }
}

function leafElement(node: Node): HTMLElement | null {
  return node.nodeType === Node.ELEMENT_NODE ? node as HTMLElement : node.parentElement
}

function pathFromElement(element: HTMLElement): [Path, number] | null {
  const path: number[] = []
  while (element) {
    const { blockIndex, memoPosition } = element.dataset

    // switch to root
    if (blockIndex !== undefined) {
      path.unshift(parseInt(blockIndex))
    } else if (memoPosition !== undefined) {
      return [path, parseInt(memoPosition)]
    }

    let parent = element.parentElement
    if (parent === null) {
      break
    }
    element = parent
  }
  return null
}


function pointFromDom(node: Node, domOffset: number): [Point, number] | null {
  const element = leafElement(node)
  if (element === null) {
    return null
  }

  const result = pathFromElement(element)
  if (result === null) {
    return null
  }
  const [path, memoPosition] = result
  const { spanOffset } = element.dataset
  const offset = parseInt(spanOffset || "0") + domOffset
  return [{ path, offset }, memoPosition]
}

export function rangeFromDom(domRange: StaticRange): [ModelRange, number] | null {
  const { startContainer, startOffset, endContainer, endOffset } = domRange;

  const anchorResult = pointFromDom(startContainer, startOffset)
  const focusResult = pointFromDom(endContainer, endOffset)
  if (anchorResult !== null && focusResult !== null) {
    const [anchor, anchorPosition] = anchorResult
    const [focus, focusPosition] = focusResult
    if (anchorPosition === focusPosition) {
      return [{ anchor, focus }, anchorPosition]
    } else {
      return null
    }
  } else {
    return null
  }
}

export function nodeFromPath(root: HTMLElement, path: number[]) {
  console.log(root, path);
  return path.reduce(function (element: HTMLElement, idx) {
    // Mustn't find self otherwise wont decend down path [0, 0]
    const queue: HTMLElement[] = [];
    for (let i = 0; i < element.children.length; i++) {
      queue.push(element.children[i] as HTMLElement);
    }
    let child: Element | undefined = queue.shift();

    while (child) {
      if ('dataset' in child) {
        const { blockIndex, spanIndex } = child.dataset
        if (spanIndex && spanIndex === idx.toString()) {
          return child
        }
        if (blockIndex && blockIndex === idx.toString()) {
          return child
        }
      }

      for (let i = 0; i < child.children.length; i++) {
        queue.push(child.children[i] as HTMLElement);
      }
      child = queue.shift();
    }

    throw "DIDN't find"
    // Search needs to be breadth first
    // return element.querySelector(`[data-sveditor-index="${idx}"]`)
  }, root)
} 