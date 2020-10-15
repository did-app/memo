export function beautifyWherebyLinks(doc) {
  const $links = doc.querySelectorAll('a:only-child')
  $links.forEach(function ($link) {
    const host = $link.host
    if (host === "whereby.com") {
      if ($link.parentElement.childNodes.length === 1) {
        const $img = document.createElement('img')
        $img.src = "https://d32wid4gq0d4kh.cloudfront.net/favicon_whereby-196x196.png"
        $img.classList.add("w-10")

        const $span = document.createElement('span')
        $span.innerText = $link.innerText.trim() || 'Meet with Whereby'
        $span.classList.add('align-middle', 'p-2', 'border-b-4')
        $span.style = "border-color:#f8dbd5;"

        const $richLink = document.createElement('a')
        $richLink.href = $link.href
        $richLink.target = "_blank"
        $richLink.classList.add('flex', 'items-center', 'items-stretch')

        $richLink.append($img)
        $richLink.append($span)
        $link.parentElement.replaceChild($richLink, $link)
      }
    }
  })
}

export function extractQuestions(doc, authoredByMe) {
  const $questionLinks = doc.querySelectorAll('a[href="#?"]')

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
  }, [])

}
