const $pins = document.getElementById("pins");
const $messages = document.getElementById("messages");
const $replyForm = document.getElementById("reply-form");
const $concludedBanner = document.getElementById("concluded-banner");
const $textarea = document.querySelector("textarea");
const $preview = document.querySelector("#preview");

$textarea.addEventListener("keyup", event => {
  $preview.innerHTML = marked(event.target.value);
});
$textarea.addEventListener("change", event => {
  $preview.innerHTML = marked(event.target.value);
});










function resolveConversation() {
  $concludedBanner.classList.remove('hidden')
    $replyForm.classList.add('hidden')
}

function writeMessage(event) {
  event.preventDefault();
  const $form = event.target;
  const { content, from, resolve } = formValues($form);
  if (resolve) {
    resolveConversation()
  }

  document.querySelectorAll("#messages > article > input.hidden").forEach(element => {
    element.checked = true
  })
  renderMessage({ content, author: from, date: "11 Aug"});
  $form.reset();
  $preview.innerHTML = "";
  // $textarea.dispatchEvent(e);
}



function inviteParticipant(event) {
  event.preventDefault()
  const $form = event.target;
  const { email: emailAddress } = formValues($form);
  let [name] = emailAddress.split("@")
  $form.reset();
  renderParticipant(name, emailAddress)
}

function renderPin(content) {
  let pin = `<li class="bg-white border-indigo-700 border-l-4 m-1 p-2 shadow-lg text-xl">${content}</li>`;
  $pins.append(domify(pin));
}

function replyWithQuote(event) {
  const snippet = "\r\n> " + event.replace(/\r?\n/g, "\r\n> ");
  $textarea.value += snippet;
  const e = new Event("change");
  $textarea.dispatchEvent(e);
}

function addSnippet(event) {
  renderPin(event);
}

const tooltip = new TextTip({
  scope: "main",
  iconFormat: 'font',
  buttons: [
    { title: "Quote", icon: "fa fa-quote-right", callback: replyWithQuote },
    { title: "Pin", icon: "fa fa-map-pin", callback: addSnippet }
  ]
});

// document.querySelector("i.fa").addEventListener('click', function (event) {
//   console.log(event);
//   if (event.target.closest('.fa-quote-right')) {
//     replyWithQuote(document.getSelection().toString())
//   }
//   if (event.target.closest('.fa-map-pin')) {
//     replyWithQuote(document.getSelection().toString())
//   }
// })

const $composeMenu = document.getElementById('compose-menu')
function textareaExpand(field) {
  // Reset field height
  field.style.height = 'inherit';
  // Get the computed styles for the element
  var computed = window.getComputedStyle(field);
  // Calculate the height
  var height = parseInt(computed.getPropertyValue('border-top-width'), 10)
               + parseInt(computed.getPropertyValue('padding-top'), 10)
               + field.scrollHeight
               + parseInt(computed.getPropertyValue('padding-bottom'), 10)
               + parseInt(computed.getPropertyValue('border-bottom-width'), 10);
  field.style.height = height + 'px';
  $composeMenu.scrollIntoView();
};

document.addEventListener('input', function (event) {
  console.log('hello');
  if (event.target.tagName.toLowerCase() !== 'textarea') return;
  textareaExpand(event.target);
}, false);
