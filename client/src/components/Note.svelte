<script>
  import Block from "./Block.svelte";

  export let blocks = [];
  export let author;
  export let notes;
  export let index;
  export let selection;

  let selectRange = {};
  $: if (selection) {
    selectRange = Object.fromEntries([[selection.anchor.path[0], {noteIndex: index, selection}]]);
  } else {
    selectRange = {};
  }
  // let fragment;
  // $: fragment = selection && !Range.isCollapsed(selection) ? Tree.extractBlocks(blocks, selection)[1] : undefined;
  // $: console.log(fragment, "---");

  function annotationsForNote(notes, index) {
    // TODO this needs to do author
    return notes
    .map(function ({blocks, author}, noteId) {
      return blocks
      .filter(function ({type, reference}) {
        return type === "annotation" && reference.note === index && reference.path !== undefined
      })
      .map(function ({reference, blocks}) {
        return {reference, blocks, author, note: noteId};
      })
    })
    .flat()
    .reduce(function (state, {reference, ...data}) {
      let [index, ...rest] = reference.path
      if (rest.length !== 0) {
        throw "We haven't fixed this for deep blocks"
      }
      // TODO needs author
      state[index] = [...(state[index] || []), data]
      return state
    }, {})
    // This group by needs to happen after flat
  }
  let annotations;
  $: annotations = annotationsForNote(notes, index);
</script>

<article id={index} class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md" >
  <header class="ml-12 mb-6 flex text-gray-600">
    <span class="font-bold">{author}</span>
    <span class="ml-auto">{index + 1} December</span>
  </header>
  <div data-note-index={index}>
    {#each blocks as {type, ...data}, index}
    <Block {type} {data} {index} {notes} action={selectRange[index]} topLevel={true} annotations={annotations[index] || []} on:annotate/>
    {/each}
  </div>
  <!-- {JSON.stringify(selection)} -->
  <!-- Put editable bit in slot, better than lots more names, same possible for composer -->
  <!-- Although we do need named slots for the top -->
  <!-- Slots would make collapsing to summary easier -->
  <slot></slot>
</article>
