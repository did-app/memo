<script lang="typescript">
  import type { State } from "../sync";
  import { toString } from "../writing";
  import type { Identifier } from "../social";
  import { emailAddressToPath } from "../social";

  // import SpanComponent from "../components/Span.svelte";
  import * as Icons from "../icons";

  export let state: State;
  let me: Identifier;
  // let contacts: Contact[];
  let draft: string = "";
  if ("me" in state && state.me) {
    me = state.me;
    // contacts = state.contacts;
    draft = toString(me.greeting);
  }
  console.log(draft);

  async function saveGreeting(): Promise<null> {
    // TODO return id somehow, separate public profile from identifier
    // let response = await API.saveGreeting(me.id, blocks);
    // if ("error" in response) {
    //   throw "failed to save greeting";
    // }
    return null;
  }
</script>

<svelte:head>
  <title>Profile</title>
</svelte:head>
<div class="flex w-full mx-auto max-w-5">
  <article
    class="flex-1 my-4 py-6  pr-6 md:pr-12 bg-white rounded-lg shadow-md ">
    <!-- Impossible to put annotations in the middle of text Impossible to save
  question preferences
  <br />
  Click to make question, NEEDS a text representation for editable pages Can be
  '#? can't have multiple blocks
  `#?ask=peter@plummail.co,bob@plummail.co&urgency=` Question dismissed needs a
  text representation for editing Could simply not make questions optional.
  Keeping the question choices separate means that we can use text editing. BUT
  any change matching to choices requires a hack or tracking where someone is
  typing in the textarea, at which point we might as well have a right text edit
  Ahh but key feature is making annotations look like answers. Alice writes
  something, Bob asks for comment, but without further text. type is Prompt. If
  not optional, direct conversation, no urgency levels
  <br />
  steps are
  <br />
  Go through the example creating what will be created
  <br />
  Find all the questions that are not from you, link to blocks make suggestions
  unless you have annotated previously need a dismiss annotation false
  <br />
  Still even in rich editor don't want attached to question -->
    <textarea />

    <div class="mt-2 pl-6 md:pl-12 flex items-center">
      <div class="flex flex-1" />
      <button
        class="flex-grow-0 flex items-center py-2 px-4 rounded-lg bg-indigo-500 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold"
        on:click={saveGreeting}>
        <span class="inline-block w-4 mr-2">
          <Icons.Send />
        </span>
        Save
      </button>
    </div>
  </article>
  <div class="flex-shrink-0 max-w-sm ">
    <article
      class="my-4 py-6  pr-6 md:pr-12 bg-gray-800 text-white pl-6 md:pl-12 rounded-lg shadow-md ">
      <h1 class="text-2xl">Hi {me.emailAddress}</h1>
      <p>
        Set up your public greeting, that explains how people should get in
        touch with you.
      </p>
      <p>
        Anyone who visits
        <a
          class="underline"
          href="{window.location.origin}{emailAddressToPath(me.emailAddress)}">{window.location.origin}{emailAddressToPath(me.emailAddress)}</a>
        will be able to response this greeting
      </p>
    </article>
  </div>
</div>
