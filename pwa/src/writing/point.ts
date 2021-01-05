import * as Path from './path';
import type * as Range from './range';

export type Point = {
  path: Path.Path,
  offset: number
}

export function Point(path: Path.Path, offset: number): Point {
  return {path, offset}
}

export function equal(point1: Point, point2: Point) {
  return Path.equal(point1.path, point2.path) && point1.offset === point2.offset;
}

export function compare(point: Point, reference: Point) {
  const min = Math.min(point.path.length, reference.path.length)
  for (var i = 0; i < point.path.length; i++) {
    if (point.path[i] < reference.path[i]) return {before: true}
    if (point.path[i] > reference.path[i]) return {after: true}
  }
  if (point.path.length === reference.path.length) {
    if (point.offset < reference.offset) return {before: true}
    if (point.offset > reference.offset) return {after: true}
    return {equal: true}
  }
  throw "Valid points can be in another"
}

export function nest(index: number, {path, offset}: Point) {
  return {path: [index, ...path], offset}
}

// export function unnest({path, offset}: Point) {
//   let [index, ...rest] = path
//   if (index !== undefined) {
//     return Some([index, {path: rest, offset}])
//   } else {
//     return None()
//   }
// }
//
// function commonPathFromRange(range: Range.Range, acc = []): [Path.Path, Range.Range] {
//   let { anchor, focus } = range
//   const [anchorIndex, ...anchorRemaining] = anchor.path;
//   const [focusIndex, ...focusRemaining] = focus.path;
//   if (anchorIndex !== undefined && anchorIndex == focusIndex) {
//     return commonPathFromRange(
//       {
//         anchor: { ...anchor, path: anchorRemaining },
//         focus: { ...focus, path: focusRemaining }
//       },
//       [...acc, anchorIndex]
//     );
//   } else {
//     return [acc, range]
//   }
// }
