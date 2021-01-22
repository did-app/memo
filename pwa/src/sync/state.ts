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
  message: string
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

export function startTask({ tasks, taskCounter, ...rest }: State, message: string) {
  let task = { message, counter: taskCounter }
  tasks = [task, ...tasks]
  taskCounter += 1
  let updated: State = { ...rest, tasks, taskCounter }
  return { updated, counter: task.counter }
}

export function resolveTask({ tasks, ...rest }: State, counter: number) {
  tasks = tasks.filter(function (t) {
    return t.counter !== counter
  })
  return { ...rest, tasks }
}

// need a task counter what if delte the last
// See above, inboxSelection never null after authentication
// export function authenticated({ inboxSelection }: State): boolean {
//   return inboxSelection != null
// }
