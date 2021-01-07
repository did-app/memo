import type { Point } from "./point"
import { compare, equal } from "./point";

export type Range = {
  anchor: Point,
  focus: Point
}

export function Range(anchor: Point, focus: Point): Range {
  return { anchor, focus };
}

// Could return none if no range
export function edges({ anchor, focus }: Range): [Point, Point] {
  if (compare(anchor, focus) === "before") {
    return [anchor, focus];
  } else {
    return [focus, anchor];
  }
}

export function isCollapsed({ anchor, focus }: Range) {
  return equal(anchor, focus);
}
