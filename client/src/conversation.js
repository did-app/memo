(async function () {
  const conversationId = parseInt(window.location.pathname.substr(3))
  let response = await fetch("http://localhost:8000" + window.location.pathname)
  const {conversation: conversation} = await response.json()
  console.log(conversation);
})()
