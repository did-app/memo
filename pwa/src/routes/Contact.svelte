<script lang="typescript">
  import type { Memo, Conversation } from "../conversation";
  import { subject } from "../conversation";
  import type { Inbox } from "../sync";
  import type { Block } from "../writing";
  import ConversationComponent from "../components/Conversation.svelte";
  import LoadingComponent from "../components/Loading.svelte";

  export let conversation: Conversation | null;
  // undefined if a group
  export let contactEmailAddress: string | false;
  export let inbox: Inbox;
  export let sharedParams:
    | { title: string | null; text: string | null; url: string | null }
    | undefined;

  export let acknowledge: (
    inboxId: string,
    threadId: string,
    position: number
  ) => void;
  export let postMemo: (
    inboxId: string,
    threadId: string,
    position: number,
    content: Block[]
  ) => void;
  export let startDirectConversation: (
    inboxId: string,
    authorId: string,
    contact: string,
    content: Block[]
  ) => void;
  export let pullMemos: (
    identifierId: string,
    conversation: Conversation | { stranger: string }
  ) => Promise<Memo[]>;

  function acknowledgeFactory({ participation }: Conversation) {
    let current = participation.latest?.position || 0;
    let outstanding = current > participation.acknowledged;
    if (outstanding) {
      return function () {
        acknowledge(inbox.identifier.id, participation.threadId, current);
      };
    }
  }

  function authorId() {
    if (inbox.role.type == "personal") {
      return inbox.identifier.id;
    } else {
      return inbox.role.identifier.id;
    }
  }

  function postMemoFactory(conversation: Conversation) {
    let currentPosition = conversation.participation.latest?.position || 0;

    return function (content: Block[]) {
      postMemo(
        inbox.identifier.id,
        conversation.participation.threadId,
        currentPosition + 1,
        content
      );
    };
  }

  function startConversationFactory(contactEmailAddress: string) {
    console.log("factory", inbox);

    return function (content: Block[]) {
      startDirectConversation(
        inbox.identifier.id,
        authorId(),
        contactEmailAddress,
        content
      );
    };
  }
</script>

<div class="w-full mx-auto max-w-3xl grid md:max-w-2xl">
  {#if conversation}
    <div class="text-center my-4">
      <h1 class="text-2xl">{subject(conversation.contact)[0]}</h1>
      <h2 class="text-gray-500">{subject(conversation.contact)[1]}</h2>
    </div>
  {:else}{/if}
  {#await pullMemos(inbox.identifier.id, conversation || { stranger: contactEmailAddress || "I think this should always be present" })}
    <LoadingComponent />
  {:then memos}
    {#if conversation}
      <ConversationComponent
        emailAddress={inbox.identifier.emailAddress}
        acknowledged={conversation.participation.acknowledged}
        {memos}
        {sharedParams}
        acknowledge={acknowledgeFactory(conversation)}
        dispatchMemo={postMemoFactory(conversation)}
      />
    {:else}
      <ConversationComponent
        emailAddress={inbox.identifier.emailAddress}
        acknowledged={0}
        {memos}
        {sharedParams}
        acknowledge={undefined}
        dispatchMemo={startConversationFactory(
          contactEmailAddress ||
            "NOTE SHOULD only start conversation when contact email address"
        )}
      />
    {/if}
  {/await}
</div>
