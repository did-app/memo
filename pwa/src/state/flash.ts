
let state: string[] = []

export function set(messages: string[]) {
  state = messages
}
export function pop() {
  let messages = state
  state = []
  return messages
}