## 2020-09-17

### Concluding a conversation

The choice was between a `concluded` field on a conversation
or a `conclusion` field on a message.

Concluding a thread is done when a message is sent.

We chose to put the `conclusion` field on a message:
- It gives who and when information associated with the message.
- A conversation can be concluded more than once,
  if the last message is not a conclusion assume it was reopened
- Conversations already load most recent message for update information.

### Recording who started a conversation

The choice was between an `original` field on the participant table
or a `started_by` on a conversation.

We chose the `started_by` field.
- This ensures every conversation records who started it, not possible/easy to constrain otherwise
- `original` field allowed us to constrain that a participant was the `original` participant
  or that they were invited. This constrain is not important for public conversations.
- Allows a conversation to be started by not a participant,
  important for bot or managers of a team
- This will also be used to record the pricing level for a user,
  starting a conversation will add it to your plan.

### Recording who invited a user

The choice was between a `first_participantion` field on participant
or `referred_by` on an identifier.

Chose `referred_by`:
- This allows a user to be referred by someone without automatically being in the same conversation.
