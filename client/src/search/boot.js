import Page from "./Page.svelte";
import * as Client from "../client.js";

export default async function() {
  const page = new Page({ target: document.body });

  let fragment = window.location.hash.substring(1);
  let params = new URLSearchParams(fragment);
  let code = params.get("code");
  let resp = await Client.authenticate(code)
  if (resp.status != 200) {
    window.location.pathname = "/sign_in"
  }

  let response = await Client.fetchInbox();
  if (response.status != 200) {
    // window.location.pathname = "/sign_in"
    throw "Could not find conversation"

  }
  let {conversations} = await response.json()
  console.log(conversations);
  let conversationSearch = new MiniSearch({
     fields: ['topic', 'participants', 'slug'], // fields to index for full-text search
     storeFields: ['topic', 'participants', 'slug'], // fields to return with search results
     tokenize: (string, fieldName) => {
       return string.split(/[\s,@]+/)
     },
     searchOptions: {
       tokenize: (string) => string.split(/[\s,@]+/) // search query tokenizer
     }
   })
   conversationSearch.addAll(conversations)

   function searchAll(term) {
     if (term.length == 0) {
       return []
     }
     return conversationSearch.search(term, {combineWith: 'AND', fuzzy: 0.2, prefix: true})
   }

   // Don't do if's in view stack up each's
   document.addEventListener("keyup", function (event) {
     var input
     if (input = event.target.closest("input#search")) {
       let term = input.value;
       page.$set({results: searchAll(term), newTopic: term})
     }
   })
}
