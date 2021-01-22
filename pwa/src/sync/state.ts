// All errors are task Failure

export type Shared = {}
export type Personal = {
  id: number,
  emailAddress: string,
  greeting: Block[] | null
}
export type Identifier = Personal | Shared

export type Group {
  name: string,
}

export type Participation = {
  threadId: number,
  acknowledged: number,
  latest: Memo | null
}
export type DirectConversation = {
  contact: Identifier,
  participation: Participation
}
export type GroupConversation = {
  group: Group,
  participation: Participation
}
export type Conversation = DirectConversation | GroupConversation

export type Inbox = {
  conversations: Conversation,
  identifier: Identifier
}

export type Task = {}

// In the future a selected inbox Flag will be left in localstorage
// therefore we don't have a loading state.
// If no inbox is selected that is the trigger to show sign in
// If the selected inbox can't be loaded due to out of date session and errored task will prompt to reauthenticate.

export type State = {
  inboxes: Inbox[],
  inboxSelection: number | null,
  tasks: Task[]
}

export function initial(): State {
  return { inboxes: [], inboxSelection: null, tasks: [] }
}

// See above, inboxSelection never null after authentication
export function authenticated({ inboxSelection }: State): boolean {
  return inboxSelection != null
}
