const API_ROOT = "http://localhost:8000";

export async function fetchInbox() {
  const response = await fetch(API_ROOT + "/inbox", {});
  return {
    conversations: [
      {
        id: 1,
        topic: "Investor Meeting - InvestINC",
        updated_at: "19 July",
        participants: "Richard, Gary"
      },
      {
        id: 2,
        topic: "New Brand Design",
        updated_at: "18 July",
        participants: "Richard, Peter, Alex, Jane, Doreen"
      },
      {
        id: 3,
        topic: "Sign me up to Plum Mail!",
        updated_at: "14 July",
        participants: "Richard, Sally-Anne"
      }
    ]
  };
}
export async function fetchConversation(id) {
  const response = await fetch(API_ROOT + "/c/" + id, {});
  return (await response.json()).conversation;
}
export async function addParticipant(id, emailAddress) {
  const response = await fetch(API_ROOT + "/c/" + id + "/participant", {
    method: "POST",
    body: JSON.stringify({ email_address: emailAddress })
  });
  console.log(response);
  return {};
}
export async function writeMessage(id, content) {
  const response = await fetch(API_ROOT + "/c/" + id + "/message", {
    method: "POST",
    body: JSON.stringify({ content: content })
  });
  console.log(response);
  return {};
}
