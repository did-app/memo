<script>
  // let topic = document.querySelector('input').value;
  let x = "f"

  $: console.log(x);

  function checkValidity(event) {
    const {valueMissing, tooShort, tooLong, patternMismatch} = event.target.validity;

  }

</script>

<input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" required pattern="[^@]*" minlength="2" maxlength="100" on:input={checkValidity} autofocus autocomplete="off"/>
<div class="warning">
  Conversation topics must not contain '@'.
</div>
<input class="w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none" placeholder="Search by name, email, topic or content, also start conversation" required pattern="[^@]*" minlength="2" maxlength="100" on:input={checkValidity} autofocus autocomplete="off"/>
<div class="warning">
  Not a valid email address
</div>
