export function beautifyWherebyLinks(doc) {
  let $links = doc.querySelectorAll('a:only-child')
  $links.forEach(function ($link) {
    const host = $link.host
    console.log($link.host);
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
