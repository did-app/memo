type Block = { blocks: Block[] } | { spans: { text: string } }
type Point = { path: number[]; offset: number };
type Range = { anchor: Point; focus: Point };
type Event = {
  type: string
  data: string | null
  dataTransfer: DataTransfer | null
}

export function handleInput(blocks: Block[], range: Range, event: Event) {
  console.log(event);

}