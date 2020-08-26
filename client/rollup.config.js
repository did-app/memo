import svelte from 'rollup-plugin-svelte';
import resolve from '@rollup/plugin-node-resolve';

export default {
	input: 'src/index.js',
	output: [
		{ file: 'dist/main.js', 'format': 'umd', name: "Plum" }
	],
	plugins: [
		svelte(),
		resolve()
	]
};
