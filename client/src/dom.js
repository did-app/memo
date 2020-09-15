export function ready(fn) {
  if (document.readyState != 'loading'){
    fn();
  } else {
    document.addEventListener('DOMContentLoaded', fn);
  }
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
