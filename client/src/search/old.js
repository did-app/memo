const { conversations, participants } = JSON.parse(document.currentScript.previousElementSibling.textContent)

// Don't need wile in the footer
function ready(fn) {
  if (document.readyState != 'loading'){
    fn();
  } else {
    document.addEventListener('DOMContentLoaded', fn);
  }
}

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

 let participantSearch = new MiniSearch({
    fields: ['email'], // fields to index for full-text search
    storeFields: ['email'], // fields to return with search results
    tokenize: (string, fieldName) => {
      return string.split(/[\s,@]+/)
    },
    searchOptions: {
      tokenize: (string) => string.split(/[\s,@]+/) // search query tokenizer
    }
  })
  participantSearch.addAll(participants)

const $results = document.getElementById('results')
function searchAll(event) {
  $results.innerHTML = null
  const term = event.target.value.trim()
  if (term.length == 0) {
    return
  }

  const matching = conversationSearch.search(term, {combineWith: 'AND', fuzzy: 0.2, prefix: true})
  matching.forEach(function ({id, topic, participants, slug}) {
    const $topic = document.createElement('h2')
    $topic.className = 'font-bold my-1'
    $topic.innerText = topic
    const $participants = document.createElement('div')
    $participants.className = 'truncate'
    $participants.innerText = slug ? ('/' + slug) :  participants
    const $container = document.createElement('a')
    $container.href = slug ? ('/' + slug) : ('/c#' + id);
    $container.className = 'block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    $container.append($topic)
    $container.append($participants)
    $results.append($container)
  })
  $hr = document.createElement('hr')
  $hr.className = 'w-1/2 mx-auto'
  $results.append($hr)
  var matched = false
  participantSearch.search(term, {combineWith: 'AND', fuzzy: 0.2, prefix: true}).forEach(function ({id, email}) {
    matched = matched || (email === term)
    const $input = document.createElement('input')
    $input.type = 'hidden'
    $input.name = 'participants'
    $input.value = email

    const $prefix = document.createElement('span')
    $prefix.innerText = 'Start a conversation with '
    const $email = document.createElement('span')
    $email.className = 'font-bold'
    $email.innerText = email

    const $header = document.createElement('h2')
    $header.className = 'my-1'
    $header.append($prefix)
    $header.append($email)

    // const $container = document.createElement('a')
    // $container.href = '#'
    // $container.className = 'block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    // $container.append($header)
    // $results.append($container)

    const $button = document.createElement('button')
    $button.type = 'submit'
    $button.className = 'block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    $button.append($prefix)
    $button.append($header)

    const $form = document.createElement('form')
    $form.action = '/c/new'
    $form.method = 'post'
    $form.append($input)
    $form.append($button)
    $results.append($form)
  })
  if (!matched && term.includes('@')) {
    console.log(term);
    const $input = document.createElement('input')
    $input.type = 'hidden'
    $input.name = 'participants'
    $input.value = term

    const $prefix = document.createElement('span')
    $prefix.innerText = 'Start a conversation with '
    const $email = document.createElement('span')
    $email.className = 'font-bold'
    $email.innerText = term

    const $header = document.createElement('h2')
    $header.className = 'my-1'
    $header.append($prefix)
    $header.append($email)

    // const $container = document.createElement('a')
    // $container.href = '#'
    // $container.className = 'block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    // $container.append($header)
    // $results.append($container)

    const $button = document.createElement('button')
    $button.type = 'submit'
    $button.className = 'block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    $button.append($prefix)
    $button.append($header)

    const $form = document.createElement('form')
    $form.action = '/c/new'
    $form.method = 'post'
    $form.append($input)
    $form.append($button)
    $results.append($form)
  } else {
    if (term.length < 3) {
      return
    }
    const $input = document.createElement('input')
    $input.type = 'hidden'
    $input.name = 'topic'
    $input.value = term

    const $prefix = document.createElement('span')
    $prefix.innerText = 'Start new conversation with topic: '
    const $email = document.createElement('span')
    $email.className = 'font-bold'
    $email.innerText = term

    const $header = document.createElement('h2')
    $header.className = 'my-1'
    $header.append($prefix)
    $header.append($email)

    // const $container = document.createElement('a')
    // $container.href = '#'
    // $container.className = 'block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    // $container.append($header)
    // $results.append($container)

    const $button = document.createElement('button')
    $button.type = 'submit'
    $button.className = 'block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    $button.append($prefix)
    $button.append($header)

    const $form = document.createElement('form')
    $form.action = '/c'
    $form.method = 'get'
    $form.append($input)
    $form.append($button)
    $results.append($form)

    // const $prefix = document.createElement('span')
    // $prefix.innerText = 'Start new conversation with topic: '
    //
    // const $topic = document.createElement('span')
    // $topic.className = 'font-bold'
    // $topic.innerText = term
    //
    // const $button = document.createElement('button')
    // $button.type = 'submit'
    // $button.className = 'block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl'
    // $button.append($prefix)
    // $button.append($topic)
    //
    //
    // const $form = document.createElement('form')
    // $form.action = '/new'
    // $form.method = 'post'
    // $form.append($input)
    // $form.append($button)
    //
    // $results.append($form)
  }
}
// https://developer.mozilla.org/en-US/docs/Web/API/Document/keydown_event
document.addEventListener("keydown", event => {
  console.log(event);
  if (event.isComposing || event.keyCode === 229) {
    return;
  }
  var step
  if (event.code == 'ArrowUp') {
    step = -1
  // } else if (event.code == 'ArrowLeft') {
  //   step = -1
  } else if (event.code == 'ArrowDown') {
    step = 1
  // } else if (event.code == 'ArrowRight') {
  //   step = 1
  } else {
    return
  }
  const focusable = [document.querySelector('#search')].concat(Array.from(document.querySelectorAll('#results > a, #results > form > button')))
  console.log(focusable);
  const activeIndex = focusable.indexOf(document.activeElement)
  const nextActiveIndex = activeIndex + step
  const nextActive = focusable[nextActiveIndex];

  if (nextActive) {
    nextActive.focus();
    event && event.preventDefault();
  }
  // do something
});
