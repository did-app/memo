import type { Reference, SectionReference } from "../thread"

export const PARAGRAPH = "paragraph";
export const TEXT = "text";
export const LINK = "link";
export const ANNOTATION = "annotation";
export const SOFTBREAK = "softbreak";
export const PROMPT = "prompt"

export type Paragraph = {
  type: typeof PARAGRAPH,
  spans: Span[],

}
export type Text = {
  type: typeof TEXT,
  text: string,

}
export type Link = {
  type: typeof LINK,
  title?: string,
  url: string,

}

export type Annotation = {
  type: typeof ANNOTATION,
  reference: Reference,
  blocks: Block[]
}

export type Prompt = {
  type: typeof PROMPT,
  reference: SectionReference
}

export type Softbreak = {
  type: typeof SOFTBREAK
}

export type Span = Text | Link | Softbreak
export type Block = Paragraph | Annotation | Prompt