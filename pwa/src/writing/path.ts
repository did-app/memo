export type Path = number[];

export function level(path: Path) {
  return path.length
}

export function index(path: Path) {
  return path[path.length - 1]
}

export function append(path: Path, index: number) {
  return [...path, index]
}

export function equal(p1: Path, p2: Path) {
  if (p1.length !== p2.length) {
    return false
  };
  return p1.every((item, index) => { return item == p2[index] })
}


export function compare(path: Path, reference: Path): "same" | "before" | "after" {
  let p: number | undefined, r: number | undefined
  do {
    p = path[0]
    path = path.slice(1)
    r = reference[0]
    reference = reference.slice(1)
    if (p === undefined && r === undefined) {
      return "same"
    } else if (p === undefined || r === undefined) {
      throw "Valid points can be in another"
    } else if (p < r) {
      return "before"
    } else if (p > r) {
      return "after"
    }
    // else equal and not undefined
  } while (true);
}