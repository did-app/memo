import type { Block } from "../writing"

export type Memo = {
  author: string,
  content: Block[],
  postedAt: Date,
  position: number
}