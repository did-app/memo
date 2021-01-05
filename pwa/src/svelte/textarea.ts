function resize(textarea: HTMLTextAreaElement) {
  const { scrollX, scrollY } = window;
  textarea.style.height = "1px";
  textarea.style.height = +textarea.scrollHeight + "px";
  window.scroll(scrollX, scrollY);
}

function watchResize(input: Event) {
  if (input.target) {
    let target = input.target as HTMLTextAreaElement
    resize(target)
  } else {
    console.warn("There should always be a target for an input event")
  }
}

export function autoResize(textarea: HTMLTextAreaElement) {
  resize(textarea);
  textarea.style.overflow = 'hidden';
  textarea.addEventListener('input', watchResize);

  return {
    destroy: () => textarea.removeEventListener('input', watchResize)
  }
}