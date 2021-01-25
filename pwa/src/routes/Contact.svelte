<script lang="typescript">
  import type { Memo, Conversation } from "../conversation";
  import { subject } from "../conversation";
  import type { Inbox } from "../sync";
  import * as API from "../sync/api";
  import type { Block } from "../writing";
  import ConversationComponent from "../components/Conversation.svelte";
  import LoadingComponent from "../components/Loading.svelte";

  export let conversation: Conversation | null;
  export let contactEmailAddress: string;
  export let inbox: Inbox;

  export let acknowledge: (
    inboxId: number,
    threadId: number,
    position: number
  ) => void;
  export let postMemo: (
    inboxId: number,
    threadId: number,
    position: number,
    content: Block[]
  ) => void;
  export let startDirectConversation: (
    inboxId: number,
    authorId: number,
    contact: string,
    content: Block[]
  ) => void;
  export let pullMemos: (conversation: Conversation | null) => Promise<Memo[]>;

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
  {:else}
    {JSON.stringify(conversation)}
  {/if}
  {#await pullMemos(conversation)}
    <LoadingComponent />
  {:then memos}
    {#if conversation}
      <ConversationComponent
        acknowledged={conversation.participation.acknowledged}
        {memos}
        acknowledge={acknowledgeFactory(conversation)}
        dispatchMemo={postMemoFactory(conversation)}
      />
    {:else}
      <ConversationComponent
        acknowledged={0}
        {memos}
        acknowledge={undefined}
        dispatchMemo={startConversationFactory(contactEmailAddress)}
      />
    {/if}
  {/await}
</div>
