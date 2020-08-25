// TODO this is not safe
export function domify(string) {
  var htmlObject = document.createElement("div");
  htmlObject.innerHTML = string;
  return htmlObject.children[0];
}
