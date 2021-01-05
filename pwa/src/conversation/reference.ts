import type { Range } from "../writing"
import { equalPoints } from "../writing"
// could become position + section/index
export type SectionReference = { memoPosition: number, blockIndex: number }
export type RangeReference = { memoPosition: number, range: Range }
export type Reference = RangeReference | SectionReference

export function equal(r1: Reference, r2: Reference): boolean {
  if ('blockIndex' in r1 && 'blockIndex' in r2) {
    return r1.memoPosition === r2.memoPosition && r1.blockIndex == r2.blockIndex
  } else if ('range' in r1 && 'range' in r2) {
    const { anchor: a1, focus: f1 } = r1.range
    const { anchor: a2, focus: f2 } = r2.range
    return equalPoints(a1, a2) && equalPoints(f1, f2)
  } else {
    return false
  }
}