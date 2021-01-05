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
  return p1.every((item, index) => {return item == p2[index]})
}
