
// https://developer.mozilla.org/en-US/docs/Web/API/Document/keydown_event
document.addEventListener("keydown", event => {
  console.log(event);
  if (event.isComposing || event.keyCode === 229) {
    return;
  }
  var step
  if (event.code == 'ArrowUp') {
    step = -1
  // } else if (event.code == 'ArrowLeft') {
  //   step = -1
  } else if (event.code == 'ArrowDown') {
    step = 1
  // } else if (event.code == 'ArrowRight') {
  //   step = 1
  } else {
    return
  }
  const focusable = [document.querySelector('#search')].concat(Array.from(document.querySelectorAll('#results > a, #results > form > button')))
  console.log(focusable);
  const activeIndex = focusable.indexOf(document.activeElement)
  const nextActiveIndex = activeIndex + step
  const nextActive = focusable[nextActiveIndex];

  if (nextActive) {
    nextActive.focus();
    event && event.preventDefault();
  }
  // do something
});
