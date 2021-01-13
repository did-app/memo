import type { Link, Annotation } from "../writing";
import type { Memo } from "./memo";

export type Pin = { memoPosition: number, item: Link | Annotation }

export function findPinnable(memos: Memo[]): Pin[] {
  return memos.map(function (memo, memoPosition): Pin[] {
    return memo.content.map(function (block): Pin[] {
      if (block.type === "annotation") {
        return [{ memoPosition, item: block }]
      } else {

        return block.spans.flatMap(function name(span) {
          if (span.type === "link") {
            return [{ memoPosition, type: "link", item: span }]
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
