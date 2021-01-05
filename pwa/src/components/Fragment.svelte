<script lang="typescript">
  import BlockComponent from "./Block.svelte";
  import type { Memo } from "../conversation";
  import type { Block } from "../writing";
  import * as Icons from "../icons";

  export let blocks: Block[];
  export let active: Record<number, undefined | (() => void)> = {};
  export let peers: Memo[];

  // function annotationsForNote(notes: Note[], index: number) {
  //   return notes
  //     .map(function ({ blocks, author }, noteId) {
  //       return blocks
  //         .filter(function (block) {
  //           return (
  //             block.type === ANNOTATION &&
  //             block.reference.note === index &&
  //             "path" in block.reference
  //           );
  //         })
  //         .map(function ({ reference, blocks }) {
  //           return { reference, blocks, author, note: noteId };
  //         });
  //     })
  //     .flat()
  //     .reduce(function (state, { reference, ...data }) {
  //       let [index, ...rest] = reference.path;
  //       if (rest.length !== 0) {
  //         throw "We haven't fixed this for deep blocks";
  //       }
  //       state[index] = [...(state[index] || []), data];
  //       return state;
  //     }, {});
  //   // This group by needs to happen after flat
  // }
  // let annotations: { reference: Reference; raw: string }[];
  // $: annotations = annotationsForNote(notes, index);
  function handleMouseDown(index: number) {
    let targetAction = active[index];
    if (targetAction) {
      targetAction();
    }
  }
</script>

{#each blocks as block, index}
  <div class="flex">
    <div
      class="w-8 my-0 mx-2 p-1 cursor-pointer flex-none"
      on:mousedown={() => handleMouseDown(index)}>
      <Icons.Attachment />
    </div>

    <BlockComponent {block} {index} {peers} />
  </div>
  <!-- </div> -->
  <!-- {#each annotations as { blocks, author, note }}
    <blockquote class="my-1 ml-12 border-gray-600 border-l-4 opacity-50 px-2">
      {#each blocks as span, index}
        <Block {span} {index} />
      {/each}
      <a class="text-purple-800" href="#{note}"><small>{author}</small></a>
    </blockquote>
  {/each} -->
  <!-- </div> -->
{/each}
