function getSelection(): Selection {
  const domSelection = window.getSelection()
  if (domSelection === null) {
    throw "Why would there be no selection"
  } else {
    return domSelection
  }
}

const domSelection = getSelection()

export function getSelectedRange() {
  return domSelection.getRangeAt(0)
}
