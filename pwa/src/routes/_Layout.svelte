<script lang="typescript">
  import router from "page";
  import type { Inbox } from "../sync";
  import {emailAddressToPath} from "../conversation"

  const API_ORIGIN = (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN;
  export let loading: boolean;
  export let inboxes: Inbox[];
  export let inboxSelection: number | null = 0;
  export let installPrompt:
     (() => Promise<{
        outcome: "accepted" | "dismissed";
        platform: string;
      }>)
    | null;
  
  let menuOpen = false
  let inbox: Inbox | null = null
  $: inbox = inboxSelection === null ? null : (inboxes[inboxSelection] || null)
</script>

<!-- $store.attribute does not get properly collapsed types with typescript -->

<header class="px-6">
  <nav class="mx-auto flex flex-wrap items-center">
    <span class="my-1 flex-grow">
      <a class=" text-2xl font-light hover:opacity-50" href="/">
        <svg
          class="float-left mr-2 mt-1.5 w-6"
          version="1.1"
          id="Layer_1"
          xmlns="http://www.w3.org/2000/svg"
          xmlns:xlink="http://www.w3.org/1999/xlink"
          x="0px"
          y="0px"
          viewBox="0 0 301.4 356.4"
          enable-background="new 0 0 301.4 356.4"
          xml:space="preserve"
        >
          <g>
            <g>
              <path
                fill="#34D399"
                d="M150.7,2.6l149.1,304.7h-93.7l-33.3-69.2L150.7,2.6z"
              />
              <path
                fill="#6EE7B7"
                d="M150.7,2.6L1.6,307.3h93.7l33.3-69.2L150.7,2.6z"
              />
              <g>
                <path
                  fill="#059669"
                  d="M150.7,2.6l55.4,304.7l-55.4,47.5L143.4,216L150.7,2.6z"
                />
                <path fill="#10B981" d="M150.7,2.6L95.4,307.3l55.4,47.5V2.6z" />
              </g>
            </g>
          </g>
        </svg>
        memo
      </a>
 
    </span>
    <span class="my-1 ml-4">
      {#if loading}
        <!-- Nothing -->
      {:else if inboxes.length === 0}
        <a href="/sign-in">Sign in</a>
      {:else}
        <a
          class="cursor-pointer"
          on:click|preventDefault={() => menuOpen = true}
        >
          Menu
        </a>
      {/if}
    </span>
  </nav>
</header>
{#if inbox && menuOpen}
<!-- github makes them details and summary -->
  <aside class="absolute z-10 top-0 right-0 min-h-screen w-full sm:max-w-xs shadow flex flex-col bg-white leading-relaxed">
    <section class="w-full max-w-xs mx-auto mt-2 py-2 border-b-2 border-gray-200">
      <a class="block text-right px-4" on:click|preventDefault={() => menuOpen = false} href="">
        close
      </a>
      <a class="block px-4" href="">
        <span>
          Signed in as 
        </span>
        <br>
        <strong>
          {#if inbox.identifier.name}
          {inbox.identifier.name} <span class="font-normal">&lt;{inbox.identifier.emailAddress}&gt;</span>
            {:else}
            {inbox.identifier.emailAddress}
          {/if}
        </strong>
      </a>
    </section>
    {#if inboxes.length > 1}
    <section class="w-full max-w-xs mx-auto py-2 border-b-2 border-gray-200">
      <span class="block px-4">Switch inbox</span>
      {#each inboxes as inbox, index}
        <button class="block w-full text-left px-4 hover:bg-gray-300 hover:text-white" on:click={() => inboxSelection = index}>
          <strong>
            {#if inbox.identifier.name}
            {inbox.identifier.name} <span class="font-normal">&lt;{inbox.identifier.emailAddress}&gt;</span>
              {:else}
              {inbox.identifier.emailAddress}
            {/if}
          </strong>
        </button>
      {/each}
    </section>
  {/if}
    <section class="w-full max-w-xs mx-auto py-2">
      <a class="block px-4 hover:bg-gray-300 hover:text-white" on:click={() => menuOpen=false} href="{emailAddressToPath(inbox.identifier.emailAddress)}">
        Your Profile
      </a>
      <!-- <a class="block px-4 hover:bg-gray-300 hover:text-white" href="">
        Billing
      </a> -->
    </section>
    <footer class="mt-auto w-full max-w-xs mx-auto mb-4 py-2 border-t-2 border-gray-200">
      {#if installPrompt}
        
      <button class="block w-full text-left px-4 hover:bg-gray-300 hover:text-white cursor-pointer" on:click={installPrompt}>
        Install
      </button>
      {/if}
      <a class="block px-4 hover:bg-gray-300 hover:text-white"           target="_self"
      href="{API_ORIGIN}/sign_out">
        <strong>
          Sign out
        </strong>
      </a>
    </footer>
  </aside>
{/if}