import Glance from './Glance.svelte'

export function beautifyWherebyLinks(doc) {
  const $links = doc.querySelectorAll('a:only-child')
  $links.forEach(function ($link) {
    // https://github.com/sveltejs/svelte/issues/537
    const frag = document.createDocumentFragment();
    console.log($link);
    const preview = new Glance({ target: frag, props: {href: $link.href, text: $link.innerText} });
    $link.replaceWith( frag );
  })
}

export function extractQuestions(doc, authoredByMe, asked) {
  const $questionLinks = doc.querySelectorAll('a[href="#?"]')
  console.log(asked);

  return Array.from($questionLinks).reduce(function (asked, $link) {
    const query = $link.innerHTML

    // Work off the questions array length
    const $details = document.createElement('details')
    $details.id = "Q:" + asked.length

    const $summary = document.createElement('summary')
    $summary.innerHTML = query

    const $answerTray = document.createElement('div')

    const $answerFallback = document.createElement('div')
    $answerFallback.classList.add('fallback')
    $answerFallback.innerHTML = "There are no answers to this question yet"
    $answerFallback.classList.add('border-l-4', 'border-gray-400', "px-2", "pt-1", "mb-2")

    $answerTray.append($answerFallback)
    $details.append($summary)
    $details.append($answerTray)

    $link.parentElement.replaceChild($details, $link)

    const awaiting = !authoredByMe
    return asked.concat({query, awaiting, $answerTray, id: asked.length, answer: ""})
  }, asked)

}
