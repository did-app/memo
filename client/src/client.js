export async function fetchInbox() {
  const response = await fetch("__API_ORIGIN__/inbox", {
    credentials: "include"
  });
  return response
}
export async function fetchConversation(id) {
  const response = await fetch("__API_ORIGIN__/c/" + id, {
    credentials: "include"
  });
  return (await response.json()).conversation;
}
export async function addParticipant(id, emailAddress) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/participant", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ email_address: emailAddress }),
  });
  console.log(response);
  return {};
}
export async function writeMessage(id, content, resolve) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/message", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ content, resolve })
  });
  console.log(response);
  return {};
}
