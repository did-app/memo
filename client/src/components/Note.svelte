<script>
  import Glance from "../glance/Glance.svelte"
  import Block from "./Block.svelte"

  export let elements = [];
  export let author;
  export let notes;
  export let index;

  function annotationsForNote(notes, index) {
    // TODO this needs to do author
    return notes
    .map(function ({elements, author}, noteId) {
      return elements
      .filter(function ({type, reference}) {
        return type === "annotation" && reference.note === index
      })
      .map(function ({reference, blocks}) {
        return {reference, blocks, author, note: noteId};
      })
    })
    .flat()
    .reduce(function (state, {reference, ...data}) {
      let [index, ...rest] = reference.path
      if (rest.length !== 0) {
        throw "We haven't fixed this for deep elements"
      }
      // TODO needs author
      state[index] = [...(state[index] || []), data]
      console.log(state, "state");
      return state
    }, {})
    // This group by needs to happen after flat
  }
  let annotations;
  $: annotations = annotationsForNote(notes, index);
</script>

<article id={index} class="my-4 py-6 pr-12 bg-white rounded-lg shadow-md" data-note-index={index}>
  <header class="ml-12 mb-6 flex text-gray-600">
    <span class="font-bold">{author}</span>
    <span class="ml-auto">{index + 1} December</span>
  </header>
  {#each elements as {type, ...data}, index}
  <Block {type} {data} {index} {notes} topLevel={true} annotations={annotations[index] || []} on:annotate/>
  {/each}
</article>
