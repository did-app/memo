
const $messages = document.getElementById("messages");
var messageIndex = 0;

export function renderMessage({ author, date, checked, content }) {
  messageIndex += 1;

  checked = checked ? "checked" : "";
  const [intro] = content.trim().split(/\r?\n/)
  const html = marked(content)
  var message = `
  <article class="relative rounded-2xl my-shadow bg-white">
    <input id="message-${messageIndex}" class="message-checkbox hidden" type="checkbox" ${checked}>
    <label for="message-${messageIndex}">
      <header class="pt-4 pb-4 flex">
        <span class="font-bold ml-20">${author}</span>
        <span class="ml-auto mr-8">${date}</span>
      </header>
      <div class="message-overlay absolute bottom-0 top-0 right-0 left-0 ">
      </div>
    </label>
    <div class="content-intro px-20 truncate">${intro}</div>
    <div class="markdown-body px-20">${html}</div>
    <footer class="h-12 mb-2 mt-4">

    </footer>
  </article>
  `;
  $messages.append(domify(message));
}
