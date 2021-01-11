import type { Path } from "./path"
import { equal as equalPath, compare as pathCompare } from './path';
import type * as Range from './range';

export type Point = {
  path: Path,
  offset: number
}

export function Point(path: Path, offset: number): Point {
  return { path, offset }
}

export function equal(point1: Point, point2: Point) {
  return equalPath(point1.path, point2.path) && point1.offset === point2.offset;
}

export function compare(point: Point, reference: Point): "same" | "before" | "after" {
  let temp = pathCompare(point.path, reference.path)
  if (temp == "same") {
    if (point.offset < reference.offset) return "before"
    if (point.offset > reference.offset) return "after"
    return "same"
  } else {
    return temp
  }
}

export function nest(index: number, { path, offset }: Point) {
  return { path: [index, ...path], offset }
}


