# plum mail

### Direct conversations
- [x] View the contact page for a unknown identifier, 
  - [x] start conversation
  - [x] Update conversation state in client for the new contact
- [x] View the contact page for a direct conversation you are participating in
  - [x] See contact information
  - [x] Send futher memo
  - [x] Update conversation state in client with sent memo

### Group conversations
- [x] Create a new group
  - [x] Send invitations
- [x] View the group page
  - [x] See participant information 
  - [x] post memo

### From the homepage see conversations that you are participating in
- [x] See direct conversations
- [x] See group conversations
- [x] See outstanding conversations first, ordered by oldest. 

### Features available in a thread
- [x] Acknowledge the latest memo
- [x] Quote content in previous messages
- [ ] See questions from previous messages highlighted
- [ ] View attachments, links etc

### Set up a greeting
- [x] See your profile editing page 
- [x] Save a new greeting
- [x] update a greeting
- [x] strangers see the greeting on their contact page
- [ ] strangers see any questions in the greeting

### Set up a team inbox
- [ ] Backend greate a group with an identifier id
- [ ] start direct conversation as the shared identity
- [ ] post a memo in the shared thread
- [ ] acknowledge should be on the whole team identifier

### Saving draft
- [ ] Save a draft for a thread.



# Later
- Add member to an existing group
- Leave a group
- See which contact has invited you to a group

### Local Development

Change to the correct directory and run.
This only needs to be done once but must be done before either of the following commands is run

```
docker-compose down --remove-orphans --volumes
```

You need to access two terminals to run locally.

```
docker-compose run -p 8000:8000 service bash
    mix deps.get
    diesel migration run
    mix test
    iex -S mix
```

```
docker-compose run -p 8080:8080 -e SNOWPACK_PUBLIC_GLANCE_ORIGIN=https://glance.did.app pwa bash
    npm i
    npm start
```

Visit http://localhost:8080 and sign in.

Login with email will not send emails when running locally.
You can open the terminal where you are running the backend "service" and copy the link that would have been sent from there.

### Prepare Heroku app

This app uses the container stack.

```
heroku stack:set -a plum-mail container
```

## Naming
### Conversation

- A conversation happen in a **Thread**
  - **Direct Threads** are between a **Pair** of individuals
  - **Group Threads** are between the **Members** of a **Group**
  - There maybe other types of threads in the future such as **Linked/Sub Threads** or **Support threads**
- A **Participant** is any individual involved in a thread
- Participants communicate in a thread by **Posting** a **Memo**
- **Participation** in a thread records the most recent **Acknowledged** memo.
- If there are more recent memos than there are acknowledged then the thread is **Outstanding**
- If all participants have acknowledged the latest memo in a thread then that thread is considered **Concluded**
- Not all threads have a topic, e.g. there is no topic in a direct/group thread
- A **Point** in a thread consists of a memo position and a point in that memo
- Each memo has a **Position** in a thread, starting at 1 and increasing from there.

Contact might be a Bad term because of groups and direct.
Your close contacts are people you have direct conversations with but you can contact anyone in a group


Notes

- *Threads where originally called conversations but a conversation is a less defined term and could potentially cross threads.*
- *Posting a memo could be called writing or creating a memo but those terms are more likely to refer to writing a draft, posting is the process of sending it i.e. posting on a notice board/forum, physically posting in a mailbox.*
- *Other possible names for a topic are subject or title. Decided to keep subject to refer specifically to the subject of the email notifications, that might not always be the same as the topic. Particularly in the case of direct threads where there is no topic. Title has too many other uses including Mr/Mrs*
- *Potentially memo is just one type of entry, if we have voice recordings*
- *Contributors are the participants who have an entry*

discussion/conversation has contributions
thread has many messages/posts/notes/memo/entry/contribution

### writing

- The **Content** of a memo, or greeting, consists of *Blocks*
- Blocks can contain further Blocks and top level blocks are called **Sections**
- A Block can be a **Paragraph** or **Annotation**
- A paragraph has **Spans**
- An Annotation has a Reference to a Position/Location in a thread**
- A **Location** in a memo is either a **Section** or a **Range**

Notes

- *A memo could be called a Note or Message. Note sounded more like something written for ones self, and Memo has more connotation of being a useful unit than a message because of how message is used in Instant messenger*
- *The content of the memo could just have been called the blocks of the message but that wouldn't necessarily say that they where in a nested structure. Also other things consist of blocks, i.e. the greeting of an individual which need a better name than just blocks*
- *The content of the memo could also be the Text or Note, both terms are potentially reused*
-

### Identification Knowing people
Names not all set in this section
This section is probably better completed by understanding how our group/ hello thread works.

- An **Identifier** is a communication address for something, i.e. thread/ individual
- An **Individual** has many **Link Tokens**/**Authentication Codes**
- A **Group** has Individuals as **Members**


Groups don't always need a contact

team@sendmemo.app -> group -> me + Richard
                  -> group -> me + laura

How do you discover a group, for direct conversation, don't need to.



Group has id, optionally has a profile, needs to be discovered for the greeting to work.
Group could have a name, but not a profile.

Do threads get a profile, no it's groups become open.

Threads don't get identifiers but they do if replying.
When sending a memo, the sending from address indentifies the author, but the reply-to address identifies the thread
reply to code

Might be useful sending link_tokens to group emails so you can validate team@thirdparty.com
Both group and individual might have payment information, although I think it's more likely enterprise with lot's of groups

Ideally identifiers have a unique id set
Identifier/Profile
email_address | greeting | group_id | individual_id
email_address | greeting | id | group_id

it's simply not a group until you start adding members

Sign in then have a make group button.

Groups can have a name but not a profile me + Richard

Group
id, name,

A visibile group is one that has an identifier, 
An open(not public) group is one where new people can join themselves.


Memberships
group_id(group_id) individual(indentifiers.id) member_id

Test, sign in as group returns message saying sign in as individual instead

<!-- FOREIGN KEY (thread_id, Null) REFERENCES memos(thread_id, position), -->