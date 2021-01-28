<script lang="typescript">
  import router from "page";
  import type { Inbox } from "../sync";

  const API_ORIGIN = (import.meta as any).env.SNOWPACK_PUBLIC_API_ORIGIN;
  export let inboxes: Inbox[];
  export let inboxSelection: number | null = 0;

  function emailAddresses(inboxes: Inbox[]): string[] {
    return inboxes.map(function ({ identifier }) {
      return identifier.emailAddress;
    });
  }
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
      <select
        bind:value={inboxSelection}
        on:change={() => router.redirect("/")}
      >
        {#each emailAddresses(inboxes) as emailAddress, index}
          <option value={index}>
            {emailAddress}
          </option>
        {/each}
      </select>
    </span>
    <span class="my-1 ml-4">
      {#if true}
        <!-- explicitly set target so page.js ignores it -->
        <a
          target="_self"
          class="ml-auto ml-2 text-xs"
          href="{API_ORIGIN}/sign_out"
        >
          <svg
            class="mx-auto mt-2 w-4"
            enable-background="new 0 0 24 24"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            ><g
              ><path
                d="m13.5 21h-4c-.276 0-.5-.224-.5-.5s.224-.5.5-.5h4c.827 0 1.5-.673 1.5-1.5v-5c0-.276.224-.5.5-.5s.5.224.5.5v5c0 1.378-1.121 2.5-2.5 2.5z"
              /></g
            ><g
              ><path
                d="m23.5 11h-10c-.276 0-.5-.224-.5-.5s.224-.5.5-.5h10c.276 0 .5.224.5.5s-.224.5-.5.5z"
              /></g
            ><g
              ><path
                d="m8 24c-.22 0-.435-.037-.638-.109l-5.99-1.997c-.82-.273-1.372-1.035-1.372-1.894v-18c0-1.103.897-2 2-2 .222 0 .438.037.639.11l5.989 1.996c.82.272 1.372 1.034 1.372 1.894v18c0 1.103-.897 2-2 2zm-6-23c-.552 0-1 .449-1 1v18c0 .428.276.808.688.946l6 2c.656.233 1.312-.292 1.312-.946v-18c0-.429-.276-.809-.688-.945l-6-2c-.103-.037-.208-.055-.312-.055z"
              /></g
            ><g
              ><path
                d="m15.5 8c-.276 0-.5-.224-.5-.5v-5c0-.827-.673-1.5-1.5-1.5h-11.5c-.276 0-.5-.224-.5-.5s.224-.5.5-.5h11.5c1.379 0 2.5 1.122 2.5 2.5v5c0 .276-.224.5-.5.5z"
              /></g
            ><g
              ><path
                d="m19.5 15c-.128 0-.256-.049-.354-.146-.195-.195-.195-.512 0-.707l3.646-3.646-3.646-3.646c-.195-.195-.195-.512 0-.707s.512-.195.707 0l4 4c.195.195.195.512 0 .707l-4 4c-.097.096-.225.145-.353.145z"
              /></g
            ></svg
          >
          <span> Sign out </span>
        </a>
      {:else}
        sign in
      {/if}
    </span>
  </nav>
</header>
