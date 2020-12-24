<script lang="typescript">
  import BlockComponent from "./Block.svelte";
  // import { ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import type { Range } from "../note/range";
  import type { Note } from "../note";
  // import type { Reference } from "../thread";

  export let blocks: Block[] = [];
  export let notes: Note[];
  // export let index: number;
  export let selection: Range | undefined;
  console.log(selection);

  let selectRange = {};
  // $: if (selection) {
  //   selectRange = Object.fromEntries([
  //     [selection.anchor.path[0], { noteIndex: index, selection }],
  //   ]);
  // } else {
  //   selectRange = {};
  // }
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

<!-- <div data-note-index={index}> -->
<!-- TODO put note index on container -->
{#each blocks as block, index}
  <BlockComponent
    {block}
    {index}
    {notes}
    annotations={[]}
    topLevel={true}
    on:annotate />
{/each}
