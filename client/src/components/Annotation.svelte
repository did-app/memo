<script>
  import Block from "./Block.svelte"
  export let reference;
  export let blocks;
  export let index;
  export let notes;

  function displayReference(reference, notes) {
    let note = notes[reference.note]
    let [top, ...rest] = reference.path
    if (rest.length != 0) {
      throw "doesn't support deep path yet"
    }
    console.log(note);
    let element = note.elements[top]
    console.log(element);
    return [element]
  }
</script>

<div class="my-2 ml-12" data-note-index="{index}">
  <blockquote class="border-gray-600 border-l-4 opacity-50 px-2">
    {#each displayReference(reference, notes) as {type, ...data}, index}
    <Block {type} {data} {index}/>
    {/each}
  </blockquote>
  <div class="pl-4">
    {#each blocks as {type, ...data}, index}
    <Block {type} {data} {index}/>
    {/each}
  </div>
  <!-- <hr class="w-1/2 mx-auto"> -->
</div>
