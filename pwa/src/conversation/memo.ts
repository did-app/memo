import type { Block } from "../writing"

export type Memo = {
  author: {name: string | null, emailAddress: string},
  content: Block[],
  postedAt: Date,
  position: number
}