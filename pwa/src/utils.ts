
export function emailAddressToPath(emailAddress: string) {
  let [username, domain] = emailAddress.split("@");
  if (domain === "plummail.co") {
    return "/" + username;
  } else {
    return "/" + domain + "/" + username;
  }
}