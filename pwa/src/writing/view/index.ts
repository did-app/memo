import type { Path } from "../path"
import type { Point } from "../point"
import type { Range as ModelRange } from "../range"
import type { Reference } from "../../conversation/reference"


export type InputEvent = {
  getTargetRanges: () => [Range]
  inputType: string,
  data: string | null,
  dataTransfer: DataTransfer | null
}

// function getSelection(): Selection {
//   const domSelection = window.getSelection()
//   if (domSelection === null) {
//     throw "Why would there be no selection"
//   } else {
//     return domSelection
//   }
// }

// const domSelection = getSelection();

// export function getSelected(root: HTMLElement) {
//   const domRange = domSelection.getRangeAt(0)
//   if (!domRange) {
//     return undefined
//   }

//   const { startContainer, startOffset, endContainer, endOffset } = domRange;
//   const startPath = root.contains(startContainer) ? pathFromNode(startContainer) : undefined;
//   const endPath = root.contains(endContainer) ? pathFromNode(endContainer) : undefined;

//   const anchor = startPath ? { ...startPath, offset: startOffset } : undefined
//   const focus = endPath ? { ...endPath, offset: endOffset } : undefined
//   return { anchor, focus }
// }

// export function getReference(root: HTMLElement): Reference | null {
//   const selected = getSelected(root)

//   if (selected && selected.anchor && selected.focus) {
//     let { memoPosition: anchorPosition, ...anchor } = selected.anchor;
//     let { memoPosition: focusPosition, ...focus } = selected.focus;

//     if (anchorPosition === focusPosition) {
//       let range = { anchor, focus }

//       if (Writing.isCollapsed(range)) {
//         let blockIndex = anchor.path[0]
//         if (blockIndex === undefined) {
//           return null
//         }
//         return { memoPosition: anchorPosition, blockIndex }
//       } else {
//         return { memoPosition: anchorPosition, range }
//       }
//     } else {
//       return null
//     }
//   } else {
//     return null
//   }
// }

function leafElement(node: Node): HTMLElement {
  // FIXME, is this bad
  let temp: any = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement
  return temp
}

function pathFromElement(element: HTMLElement): Path {
  const path: number[] = []
  while (element) {
    const { blockIndex, memoPosition } = element.dataset

    // switch to root
    if (blockIndex !== undefined) {
      path.unshift(parseInt(blockIndex))
    } else if (memoPosition !== undefined) {
      return path
    }

    let parent = element.parentElement
    if (parent === null) {
      break
    }
    element = parent
  }
  throw "there should always be a parent element"
}


function pointFromDom(node: Node, domOffset: number): Point {
  const element = leafElement(node)
  const path = pathFromElement(element)
  const { spanOffset } = element.dataset
  const offset = parseInt(spanOffset || "0") + domOffset
  return { path, offset }
}

export function rangeFromDom(domRange: Range): ModelRange {
  const { startContainer, startOffset, endContainer, endOffset } = domRange;
  const anchor = pointFromDom(startContainer, startOffset)
  const focus = pointFromDom(endContainer, endOffset)
  return { anchor, focus }
}

export function nodeFromPath(root: HTMLElement, path: number[]) {
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