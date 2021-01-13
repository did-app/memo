declare namespace svelte.JSX {
  interface HTMLAttributes<T> {
    // You can replace any with something more specific if you like
    onbeforeinput?: (event: any) => void;
  }
}