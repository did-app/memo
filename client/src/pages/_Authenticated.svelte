<script type="text/javascript">
  import {onMount} from "svelte"
  console.log("foo")
  onMount(function(){
    console.log("bar")
  })
</script>

<a href="/begin">begin</a>
<a href="/">search</a>
<slot></slot>
