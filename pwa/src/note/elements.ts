export const PARAGRAPH = "paragraph";
export const TEXT = "text";
export const LINK = "link";
export const ANNOTATION = "annotation";
export const SOFTBREAK = "softbreak";

export type Paragraph = {
  type: typeof PARAGRAPH,
  spans: Span[],
  // TODO remove start
  start: number
}
export type Text = {
  type: typeof TEXT,
  text: string,
  // TODO remove start
  start?: number
}
export type Link = {
  type: typeof LINK,
  title?: string,
  url: string,
  // TODO remove start
  start: number
}

export type Softbreak = {
  type: typeof SOFTBREAK
}

export type Span = Text | Link | Softbreak
export type Block = Paragraph