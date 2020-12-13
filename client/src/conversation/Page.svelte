<script>




  let makeQuestion;


function doInstall() {
  installPrompt.prompt()
  installPrompt = false
}
</script>



    <form class="w-full mb-8 md:px-20" on:submit|preventDefault={doInstall}>
      {#if installPrompt}
      <div class="flex">
        <label class="ml-auto font-bold flex py-1 justify-start items-center">
          <p class="mr-2">Find this conversation quicker?</p>
          <button class="my-1 py-1 px-2 rounded bg-gray-900 focus:bg-gray-700 hover:bg-gray-700 text-white font-bold" type="submit" title="Select to no longer see as outsanding">Install</button>
        </label>
      </div>
      {/if}
    </form>

  </main>

</div>
{/if }
