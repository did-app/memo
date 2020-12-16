// discussion/conversation has contributions
// thread has many messages/posts/notes/memo/entry/contribution

// thread has many notes
// A note has many blocks and spans in a tree
export function followReference(reference, notes) {
  let note = notes[reference.note]
  let [top, ...rest] = reference.path
  if (rest.length != 0) {
    throw "doesn't support deep path yet"
  }
  let element = note.blocks[top]
  return [element]
}
