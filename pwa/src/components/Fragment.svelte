<script lang="typescript">
  import BlockComponent from "./Block.svelte";
  // import { ANNOTATION } from "../note/elements";
  import type { Block } from "../note/elements";
  import type { Note } from "../note";
  // import type { Reference } from "../thread";

  export let blocks: Block[];
  export let active: Record<number, undefined | (() => void)> = {};
  export let thread: Note[];

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
  function handleMouseDown(index: number) {
    let targetAction = active[index];
    if (targetAction) {
      targetAction();
    }
  }
</script>

<!-- <div data-note-index={index}> -->
<!-- TODO put note index on container -->
{#each blocks as block, index}
  <div class="flex">
    <div
      class="w-8 my-0 mx-2 cursor-pointer flex-none"
      on:mousedown={() => handleMouseDown(index)}>
      <svg
        class:opacity-0={undefined === active[index]}
        class="w-full p-1 fill-current text-gray-700"
        enable-background="new 0 0 512 512"
        viewBox="0 0 512 512"
        xmlns="http://www.w3.org/2000/svg"><g>
          <path
            d="m127.694 499.604c.69 3.918 2.91 7.401 6.168 9.683 2.539 1.778 5.546 2.713 8.604 2.713.867 0 1.739-.075 2.605-.228l77.059-13.588-99.381-26.629z" />
          <path
            d="m511.77 431.881-34.558-195.99-61.117 228.091 83.508-14.725c8.157-1.437 13.605-9.217 12.167-17.376z" />
          <path
            d="m457.2 136.708 2.648.709-3.645-20.674c-1.438-8.158-9.215-13.603-17.377-12.167l-61.243 10.799z" />
          <path
            d="m458.546 172.675c-1.989-3.445-5.266-5.959-9.108-6.989l-138.438-37.094v61.408c0 22.056-17.944 40-40 40s-40-17.944-40-40v-15c0-8.284 6.716-15 15-15s15 6.716 15 15v15c0 5.514 4.486 10 10 10s10-4.486 10-10v-69.447l-50-13.397v-52.156c0-13.785 11.215-25 25-25s25 11.215 25 25v65.553l30 8.038v-73.591c0-30.327-24.673-55-55-55s-55 24.673-55 55v44.117l-99.295-26.606c-8.003-2.146-16.228 2.604-18.371 10.606l-82.823 309.097c-1.03 3.843-.491 7.937 1.499 11.382 1.989 3.445 5.265 5.959 9.108 6.989l347.734 93.175c1.3.349 2.605.515 3.892.515 6.622 0 12.684-4.42 14.479-11.122l82.822-309.096c1.029-3.843.49-7.937-1.499-11.382zm-201.025 226.288c-1.795 6.701-7.857 11.122-14.479 11.122-1.285 0-2.591-.167-3.892-.515l-154.547-41.411c-8.002-2.144-12.75-10.369-10.606-18.371s10.367-12.753 18.371-10.606l154.548 41.411c8.001 2.143 12.75 10.368 10.605 18.37zm92.804-37.25c-1.796 6.701-7.857 11.122-14.479 11.122-1.286 0-2.592-.167-3.892-.515l-231.823-62.117c-8.002-2.144-12.75-10.369-10.606-18.371s10.366-12.75 18.371-10.606l231.822 62.117c8.002 2.143 12.751 10.368 10.607 18.37zm15.529-57.955c-1.796 6.701-7.857 11.122-14.479 11.122-1.286 0-2.592-.167-3.892-.515l-231.823-62.117c-8.002-2.144-12.75-10.369-10.606-18.371 2.144-8.001 10.366-12.751 18.371-10.606l231.822 62.117c8.002 2.143 12.751 10.368 10.607 18.37z" />
        </g></svg>
    </div>

    <BlockComponent {block} {index} {thread} />
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
