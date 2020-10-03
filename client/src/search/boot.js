import Page from "./Page.svelte";
import authenticate from "../authenticate.js"
import * as Client from "../client.js";

export default async function() {
  const page = new Page({ target: document.body });
  const identifier = await authenticate()

  let response = await Client.fetchInbox();
  let {conversations} = response.match({ok: function (data) {
    console.log(data);
    return data
  }, fail: function (_) {
    throw "Could not load inbox"
  }});

  let conversationSearch = new MiniSearch({
     fields: ['topic', 'participants', 'slug'], // fields to index for full-text search
     storeFields: ['topic', 'next', 'participants', 'slug', 'updated_at'], // fields to return with search results
     tokenize: (string, fieldName) => {
       return string.split(/[\s,@]+/)
     },
     searchOptions: {
       tokenize: (string) => string.split(/[\s,@]+/) // search query tokenizer
     }
   })
   conversations = conversations.map(function (c) {
     let participants = c.participants.map(function (p) {
       return p.email_address
     }).join(", ")
     return Object.assign({}, c, {participants})
   })
   let unread = conversations.filter(function (c) {
     return c.unread
   }).slice().reverse()
   page.$set({unread, all: conversations})
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
