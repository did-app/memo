export type SectionReference = { memoPosition: number, blockIndex: number }
export type RangeReference = { memoPosition: number, range: Range }
export type Reference = RangeReference | SectionReference