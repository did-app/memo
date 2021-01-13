import type { Point } from "./point"
import * as point_module from "./point";

export type Range = {
  anchor: Point,
  focus: Point
}

// Could return none if no range
export function edges({ anchor, focus }: Range): [Point, Point] {
  if (point_module.compare(anchor, focus) === "before") {
    return [anchor, focus];
  } else {
    return [focus, anchor];
  }
}

export function isCollapsed({ anchor, focus }: Range): boolean {
  return point_module.compare(anchor, focus) === 'same';
}

// function commonPath(range: Range, acc: number[] = []): [number[], Range] {
//   const result = popCommon(range)
//   if (result) {
//     return commonPath(result[1], [...acc, result[0]])
//   } else {
//     return [acc, range]
//   }
// }

export function popCommon(range: Range): [number, Range] | null {
  let { anchor, focus } = range
  const anchorResult = point_module.unnest(anchor);
  const focusResult = point_module.unnest(focus);
  if (anchorResult && focusResult && anchorResult[0] === focusResult[0]) {
    return [anchorResult[0], { anchor: anchorResult[1], focus: focusResult[1] }]
  } else {
    return null
  }
}
