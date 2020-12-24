<script lang="typescript">
  import BlockComponent from "./Block.svelte";
  import { ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import type { Range } from "../note/range";
  import type { Note } from "../note";
  import type { Reference } from "../thread";

  export let blocks: Block[] = [];
  export let author: string;
  export let notes: Note[];
  export let index: number;
  export let selection: Range | undefined;

  let selectRange = {};
  $: if (selection) {
    selectRange = Object.fromEntries([
      [selection.anchor.path[0], { noteIndex: index, selection }],
    ]);
  } else {
    selectRange = {};
  }
  console.log(selectRange);

  // function annotationsForNote(notes: Note[], index: number) {
  //   // TODO this needs to do author
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
  //       // TODO needs author
  //       state[index] = [...(state[index] || []), data];
  //       return state;
  //     }, {});
  //   // This group by needs to happen after flat
  // }
  // let annotations: { reference: Reference; raw: string }[];
  // $: annotations = annotationsForNote(notes, index);
</script>

<article
  id={index.toString()}
  class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md">
  <header class="ml-12 mb-6 flex text-gray-600">
    <span class="font-bold">{author}</span>
    <span class="ml-auto">{index + 1} December</span>
  </header>
  <div data-note-index={index}>
    {#each blocks as block, index}
      <BlockComponent
        {block}
        {index}
        {notes}
        annotations={[]}
        topLevel={true}
        on:annotate />
    {/each}
    <!-- action={selectRange[index]} -->
    <!-- annotations={annotations[index] || []} -->
  </div>
  <!-- {JSON.stringify(selection)} -->
  <!-- Put editable bit in slot, better than lots more names, same possible for composer -->
  <!-- Although we do need named slots for the top -->
  <!-- Slots would make collapsing to summary easier -->
  <slot />
</article>
