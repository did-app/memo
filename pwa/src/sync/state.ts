// All errors are task Failure
import type { Participation, Conversation, Identifier } from "../conversation"



export type Inbox = {
  conversations: Conversation[],
  identifier: Identifier
}

// Task can have a show working, show done or show error status
// I think all should have a show errored status
// Loading can be task 0 is running if we fancy
export type Task = {
  counter: number,
}

// In the future a selected inbox Flag will be left in localstorage
// therefore we don't have a loading state.
// If no inbox is selected that is the trigger to show sign in
// If the selected inbox can't be loaded due to out of date session and errored task will prompt to reauthenticate.

export type State = {
  inboxes: Inbox[],
  inboxSelection: number | null,
  taskCounter: number,
  tasks: Task[]
}

export function initial(): State {
  return {
    inboxes: [],
    inboxSelection: null,
    taskCounter: 0,
    tasks: []
  }
}

// need a task counter what if delte the last
// See above, inboxSelection never null after authentication
// export function authenticated({ inboxSelection }: State): boolean {
//   return inboxSelection != null
// }
