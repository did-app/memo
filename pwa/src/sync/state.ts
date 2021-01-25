// All errors are task Failure
import type { Participation, Conversation, Identifier } from "../conversation"
import type { Failure } from "./client"


export type Inbox = {
  conversations: Conversation[],
  identifier: Identifier,
  role: { type: 'personal' } | { type: 'member', identifier: Identifier }
}

// Task can have a show working, show done or show error status
// I think all should have a show errored status
// Loading can be task 0 is running if we fancy
export type Task = {
  type: "running" | "success" | "failure",
  counter: number,
  message: string
}

// In the future a selected inbox Flag will be left in localstorage
// therefore we don't have a loading state.
// If no inbox is selected that is the trigger to show sign in
// If the selected inbox can't be loaded due to out of date session and errored task will prompt to reauthenticate.

export type State = {
  loading: boolean,
  inboxes: Inbox[],
  inboxSelection: number | null,
  taskCounter: number,
  tasks: Task[]
}

export function initial(): State {
  return {
    loading: true,
    inboxes: [],
    inboxSelection: null,
    taskCounter: 0,
    tasks: []
  }
}

export function startTask({ tasks, taskCounter, ...rest }: State, message: string) {
  let task: Task = { type: "running", message, counter: taskCounter }
  tasks = [task, ...tasks]
  taskCounter += 1
  let updated: State = { ...rest, tasks, taskCounter }
  return { updated, counter: task.counter }
}

export function resolveTask({ tasks, ...rest }: State, counter: number, message: string) {
  tasks = tasks.map(function (t): Task {
    if (t.counter === counter) {
      return { type: 'success', message, counter }
    } else {
      return t
    }
  })
  return { ...rest, tasks }

}

export function removeTask({ tasks, ...rest }: State, counter: number) {
  tasks = tasks.filter(function (t) {
    return t.counter !== counter
  })
  return { ...rest, tasks }
}

export function reportFailure({ tasks, taskCounter, ...rest }: State, failure: Failure): State {
  let task: Task = { type: "failure", message: failure.detail, counter: taskCounter }
  tasks = [task, ...tasks]
  taskCounter += 1
  return { ...rest, tasks, taskCounter }
}

export function selectedInbox({ inboxSelection, inboxes }: State): Inbox | null {
  if (inboxSelection !== null) {
    return inboxes[inboxSelection] || null;
  } else {
    return null;
  }
}


export function selectedConversation(inbox: Inbox, params: { emailAddress: string } | { groupId: string } | undefined): Conversation | null {
  if (params && 'emailAddress' in params) {
    return inbox.conversations.find(function ({ contact }) {
      return ('emailAddress' in contact) && contact.emailAddress == params.emailAddress
    }) || null
  } else if (params) {
    return inbox.conversations.find(function ({ contact }) {
      return contact.type === 'group' && contact.id == params.groupId
    }) || null
  } else {
    return null
  }
}
