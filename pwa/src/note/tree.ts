import * as Range from "./range.js";

function arrayPopIndex(items, index) {
  const pre = items.slice(0, index);
  const post = items.slice(index + 1);
  const item = items[index];
  return [pre, item, post]
}

function splitText(text, offset) {
  const pre = text.slice(0, offset);
  const post = text.slice(offset);
  return [pre, post]
}
function splitSpans(spans, j, offset) {
  const [pre, span, post] = arrayPopIndex(spans, j);
  const [preText, postText] = splitText(span.text, offset)
  return [
    [...pre, {...span, text: preText}],
    [{...span, text: postText}, ...post]
  ]
}
function splitBlocks(blocks, {path, offset}) {
  const [i, j, ...none] = path
  if (none.length !== 0) {
    throw "extractBlocks only works in paragraphs for now"
  }
  const [pre, paragraph, post] = arrayPopIndex(blocks, i);
  const [preSpans, postSpans] = splitSpans(paragraph.spans, j, offset)
  return [
    [...pre, {...paragraph, spans: preSpans}],
    [{...paragraph, spans: postSpans}, ...post]
  ]
}

export function extractBlocks(blocks, range) {
  const [start, end] = Range.edges(range);
  const [tempBlocks, postBlocks] = splitBlocks(blocks, end)
  const [preBlocks, slicedBlocks] = splitBlocks(tempBlocks, start)
  return [preBlocks, slicedBlocks, postBlocks]
}
