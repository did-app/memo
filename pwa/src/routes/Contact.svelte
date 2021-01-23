<script lang="typescript">
  import type { Identifier, Memo, Conversation } from "../conversation";
  import * as conversation_module from "../conversation";
  import type { Block } from "../writing";
  import ConversationComponent from "../components/Conversation.svelte";
  export let conversation: Conversation | null;
  export let identifier: Identifier;

  export let acknowledge: () => void;
  export let postMemo: (content: Block[]) => void;
  let loadingMemos: Promise<Memo[]> = Promise.resolve([]);
</script>

<div class="w-full mx-auto max-w-3xl grid md:max-w-2xl">
  {#await loadingMemos then memos}
    {#if conversation}
      <ConversationComponent
        acknowledged={conversation.participation.acknowledged}
        outstanding={conversation_module.isOutstanding(
          conversation.participation
        )}
        {memos}
        {identifier}
        {acknowledge}
        {postMemo}
      />
    {:else}
      <ConversationComponent
        acknowledged={0}
        outstanding={false}
        {identifier}
        {memos}
        {acknowledge}
        {postMemo}
      />
    {/if}
  {/await}
</div>
