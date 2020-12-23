import * as Point from "./point";

export type Range = {
  anchor: Point.Point,
  focus: Point.Point
}

export function Range(anchor: Point.Point, focus: Point.Point): Range {
  return { anchor, focus };
}

// Could return none if no range
export function edges({ anchor, focus }: Range) {
  if (Point.compare(anchor, focus).before) {
    return [anchor, focus];
  } else {
    return [focus, anchor];
  }
}

export function isCollapsed({ anchor, focus }: Range) {
  return Point.equal(anchor, focus);
}
