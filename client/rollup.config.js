import replace from "@rollup/plugin-replace";
import svelte from "rollup-plugin-svelte";
import resolve from "@rollup/plugin-node-resolve";
import typescript from "@rollup/plugin-typescript";
import sveltePreprocess from "svelte-preprocess";

const API_ORIGIN = process.env.API_ORIGIN || MISSING_API_ORIGIN();
const GLANCE_ORIGIN = process.env.GLANCE_ORIGIN || MISSING_GLANCE_ORIGIN();

export default {
  input: "src/main.js",
  output: [{ file: "public/build/main.js", format: "umd", name: "Plum" }],
  plugins: [
    replace({ __API_ORIGIN__: API_ORIGIN, __GLANCE_ORIGIN__: GLANCE_ORIGIN }),
    svelte({ dev: true, preprocess: sveltePreprocess(), }),
    resolve(),
    typescript()
  ]
};
