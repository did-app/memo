import type { Block } from "../writing"

export type Memo = {
  author: string,
  content: Block[],
  posted_at: Date,
  position: number
}