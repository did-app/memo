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
  return (await response.json());
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
export async function writeMessage(id, content, from, resolve) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/message", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ content, from, resolve })
  });
  console.log(response);
  return {};
}
export async function addPin(id, content) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/pin", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ content })
  });
  console.log(response);
  return {};
}
export async function setNotification(id, notify) {
  const response = await fetch("__API_ORIGIN__/c/" + id + "/notify", {
    method: "POST",
    credentials: "include",
    body: JSON.stringify({ notify })
  });
  console.log(response);
  return {};
}
