import type { Reference, SectionReference } from "../conversation/thread"

export type Paragraph = {
  type: "paragraph",
  spans: Span[],

}
export type Text = {
  type: "text",
  text: string,

}
export type Link = {
  type: "link",
  title?: string,
  url: string,
}

export type Annotation = {
  type: "annotation",
  reference: Reference,
  blocks: Block[]
}

export type Prompt = {
  type: "prompt",
  reference: SectionReference
}

export type Softbreak = {
  type: "softbreak"
}

export type Span = Text | Link | Softbreak
export type Block = Paragraph | Annotation | Prompt