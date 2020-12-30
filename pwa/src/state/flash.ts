
let state: string[] = []

export function set(messages: string[]) {
  state = messages
}
export function pop() {
  let messages = state
  state = []
  return messages
}
// export type Success = { type: "success", title: string, id: number }
// export type Info = { type: "error", detail: string, url: string id: number };
// export type Error = { type: "error", detail: string, id: number };

// let counter = 0;
// let setter: any
// let state: Flash[] = []
// export const flashes = readable(state, function start(set) {
//   setter = set
// })

// function set(x: Flash[]) {
//   setter && setter(x)
// }

// export function reportSuccess(title: string) {
//   let id = counter;
//   counter = id + 1
//   let next: Flash = { type: "success", title, id }
//   state = [...state, next]
//   set(state)
// }

// export function reportError(detail: string) {
//   let id = counter;
//   counter = id + 1
//   let next: Flash = { type: "error", detail, id }
//   state = [...state, next]
//   set(state)
// }