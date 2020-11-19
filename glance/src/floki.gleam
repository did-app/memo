pub external type HTMLNode

pub external fn parse_document(raw: String) -> Result(List(HTMLNode), String) =
  "Elixir.Floki" "parse_document"

pub external fn find(tree: List(HTMLNode), query: String) -> List(HTMLNode) =
  "Elixir.Floki" "find"

pub external fn attribute(tree: List(HTMLNode), name: String) -> List(String) =
  "Elixir.Floki" "attribute"

// TODO maybe need a text children function
// be aware can have both e.g. <p>text <span>and</span></p>
pub external fn text(tree: List(HTMLNode)) -> String =
  "Elixir.Floki" "text"
