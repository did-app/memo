var messageIndex = 0;

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

function formValues($form) {
  // https://codepen.io/ntpumartin/pen/MWYmypq
  var obj = {};
  var elements = $form.querySelectorAll("input, select, textarea");
  for (var i = 0; i < elements.length; ++i) {
    var element = elements[i];
    var name = element.name;
    var value = element.value;
    var type = element.type;

    if (type === "checkbox") {
      obj[name] = element.checked
    } else {
      if (name) {
        obj[name] = value;
      }

    }

  }
  return obj;
}

function domify(string) {
  var htmlObject = document.createElement("div");
  htmlObject.innerHTML = string;
  return htmlObject.children[0];
}



function renderMessage({ author, date, checked, content }) {
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

const fragment = window.location.hash
console.log(fragment);
if (fragment === "#1") {

  setTopic("Investor Meeting - InvestINC.")
  renderParticipant("Richard", "richard@plummail.co")
  renderParticipant("Gary", "gary@investor.eg")
  renderMessage({
    author: "Richard",
    date: "19 July",
    checked: true,
    content:
    `Hi Mr Investor, Which of the following dates work for a meeting?
    `
  });

  renderMessage({
    author: "Gary Investor",
    date: "20 July",
    checked: false,
    content:
    `Hi Richard,

Great to hear from you.

I would love to meet at 2pm on Wednesday.

Where is good for you to meet?

Gary

    `
  });


} else if (fragment === "#2") {
  setTopic("New Brand Design")
  renderParticipant("Richard", "richard@plummail.co")
  renderParticipant("Peter", "peter@plummail.co")
  renderParticipant("Alex", "alex@designcompany.co")
  renderParticipant("Jane", "jane@designcompany.co")
  renderParticipant("Doreen", "doreen@plummail.co")
  renderMessage({
    author: "Richard",
    date: "18 July",
    checked: true,
    content:
    `Hi Team, Really looking forward to seeing what you come up with.

At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga.

Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.
    `
  });
  renderMessage({
    author: "Doreen",
    date: "18 July",
    checked: true,
    content:
    `Alex, Jane, Welcome to the team, we are looking forward to working with you on this design project for Plum Mail.

Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.

    `
  });
    renderMessage({
    author: "Alex",
    date: "19 July",
    checked: true,
    content:
    `Hi Doreen,

We are thinking of going with a nice plum theme.

How do you like this picture?

![](https://images.unsplash.com/photo-1503267509980-772860efc568?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1189&q=80)

    `
  });
      renderMessage({
    author: "Doreen",
    date: "19 July",
    checked: true,
    content:
    `Hi Alex, How about this one, it is a little known fact that plums can sometimes be yellow.

  ![](https://images.unsplash.com/photo-1594388908602-013ad329e1c7?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1050&q=80)

    `
  });
        renderMessage({
    author: "Peter",
    date: "20 July",
    checked: false,
    content:
    `Hi Everyone,

Alex's suggestion of yellow plums is excellent.

We are all agreed that we're going to go with Yellow Plums.

Thanks for all your help.

Peter

    `
  });
  resolveConversation()

} else if (fragment === "#3") {
  setTopic("Sign me up to Plum Mail!")
  renderParticipant("Richard", "richard@plummail.co")
  renderParticipant("Sally-Anne", "sally-anne@example.co")
  renderMessage({
    author: "Sally-Anne",
    date: "14 July",
    checked: false,
    content:
    `Hi Richard, It was very good to meet you yesterday.  Thanks again for helping me out.

I think I would like to find out more about [Plum Mail](https://plummail.co) and the benefits it will have for my team.

Please can you set me up with a demo as you described?

*Best wishes*

Sally Anne

    `
  });


} else if (fragment === "") {
  var searchParams = new URLSearchParams(window.location.search);
  setTopic(searchParams.get('topic'))
}
