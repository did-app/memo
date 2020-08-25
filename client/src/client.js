const API_ROOT = "http://localhost:8000"

export async function fetchConversation(id) {
  const response = await fetch(API_ROOT + "/c/" + id, {})
  return (await response.json()).conversation
}
export async function addParticipant(id, emailAddress) {
  const response = await fetch(API_ROOT + "/c/" + id + "/participant", {
    method: "POST",
    body: JSON.stringify({email_address: emailAddress})
  })
  console.log(response);
  return ({})
}
