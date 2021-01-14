# plum mail

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
