// TODO this is not safe
export function domify(string) {
  var htmlObject = document.createElement("div");
  htmlObject.innerHTML = string;
  return htmlObject.children[0];
}

export function formValues($form) {
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
