(function (factory) {
    typeof define === 'function' && define.amd ? define(factory) :
    factory();
}((function () { 'use strict';

    function noop() { }
    function run(fn) {
        return fn();
    }
    function blank_object() {
        return Object.create(null);
    }
    function run_all(fns) {
        fns.forEach(run);
    }
    function is_function(thing) {
        return typeof thing === 'function';
    }
    function safe_not_equal(a, b) {
        return a != a ? b == b : a !== b || ((a && typeof a === 'object') || typeof a === 'function');
    }
    function is_empty(obj) {
        return Object.keys(obj).length === 0;
    }

    function append(target, node) {
        target.appendChild(node);
    }
    function insert(target, node, anchor) {
        target.insertBefore(node, anchor || null);
    }
    function detach(node) {
        node.parentNode.removeChild(node);
    }
    function destroy_each(iterations, detaching) {
        for (let i = 0; i < iterations.length; i += 1) {
            if (iterations[i])
                iterations[i].d(detaching);
        }
    }
    function element(name) {
        return document.createElement(name);
    }
    function text(data) {
        return document.createTextNode(data);
    }
    function space() {
        return text(' ');
    }
    function empty() {
        return text('');
    }
    function attr(node, attribute, value) {
        if (value == null)
            node.removeAttribute(attribute);
        else if (node.getAttribute(attribute) !== value)
            node.setAttribute(attribute, value);
    }
    function children(element) {
        return Array.from(element.childNodes);
    }
    function set_data(text, data) {
        data = '' + data;
        if (text.wholeText !== data)
            text.data = data;
    }
    function set_style(node, key, value, important) {
        node.style.setProperty(key, value, important ? 'important' : '');
    }

    let current_component;
    function set_current_component(component) {
        current_component = component;
    }

    const dirty_components = [];
    const binding_callbacks = [];
    const render_callbacks = [];
    const flush_callbacks = [];
    const resolved_promise = Promise.resolve();
    let update_scheduled = false;
    function schedule_update() {
        if (!update_scheduled) {
            update_scheduled = true;
            resolved_promise.then(flush);
        }
    }
    function add_render_callback(fn) {
        render_callbacks.push(fn);
    }
    let flushing = false;
    const seen_callbacks = new Set();
    function flush() {
        if (flushing)
            return;
        flushing = true;
        do {
            // first, call beforeUpdate functions
            // and update components
            for (let i = 0; i < dirty_components.length; i += 1) {
                const component = dirty_components[i];
                set_current_component(component);
                update(component.$$);
            }
            dirty_components.length = 0;
            while (binding_callbacks.length)
                binding_callbacks.pop()();
            // then, once components are updated, call
            // afterUpdate functions. This may cause
            // subsequent updates...
            for (let i = 0; i < render_callbacks.length; i += 1) {
                const callback = render_callbacks[i];
                if (!seen_callbacks.has(callback)) {
                    // ...so guard against infinite loops
                    seen_callbacks.add(callback);
                    callback();
                }
            }
            render_callbacks.length = 0;
        } while (dirty_components.length);
        while (flush_callbacks.length) {
            flush_callbacks.pop()();
        }
        update_scheduled = false;
        flushing = false;
        seen_callbacks.clear();
    }
    function update($$) {
        if ($$.fragment !== null) {
            $$.update();
            run_all($$.before_update);
            const dirty = $$.dirty;
            $$.dirty = [-1];
            $$.fragment && $$.fragment.p($$.ctx, dirty);
            $$.after_update.forEach(add_render_callback);
        }
    }
    const outroing = new Set();
    let outros;
    function group_outros() {
        outros = {
            r: 0,
            c: [],
            p: outros // parent group
        };
    }
    function check_outros() {
        if (!outros.r) {
            run_all(outros.c);
        }
        outros = outros.p;
    }
    function transition_in(block, local) {
        if (block && block.i) {
            outroing.delete(block);
            block.i(local);
        }
    }
    function transition_out(block, local, detach, callback) {
        if (block && block.o) {
            if (outroing.has(block))
                return;
            outroing.add(block);
            outros.c.push(() => {
                outroing.delete(block);
                if (callback) {
                    if (detach)
                        block.d(1);
                    callback();
                }
            });
            block.o(local);
        }
    }
    function create_component(block) {
        block && block.c();
    }
    function mount_component(component, target, anchor) {
        const { fragment, on_mount, on_destroy, after_update } = component.$$;
        fragment && fragment.m(target, anchor);
        // onMount happens before the initial afterUpdate
        add_render_callback(() => {
            const new_on_destroy = on_mount.map(run).filter(is_function);
            if (on_destroy) {
                on_destroy.push(...new_on_destroy);
            }
            else {
                // Edge case - component was destroyed immediately,
                // most likely as a result of a binding initialising
                run_all(new_on_destroy);
            }
            component.$$.on_mount = [];
        });
        after_update.forEach(add_render_callback);
    }
    function destroy_component(component, detaching) {
        const $$ = component.$$;
        if ($$.fragment !== null) {
            run_all($$.on_destroy);
            $$.fragment && $$.fragment.d(detaching);
            // TODO null out other refs, including component.$$ (but need to
            // preserve final state?)
            $$.on_destroy = $$.fragment = null;
            $$.ctx = [];
        }
    }
    function make_dirty(component, i) {
        if (component.$$.dirty[0] === -1) {
            dirty_components.push(component);
            schedule_update();
            component.$$.dirty.fill(0);
        }
        component.$$.dirty[(i / 31) | 0] |= (1 << (i % 31));
    }
    function init(component, options, instance, create_fragment, not_equal, props, dirty = [-1]) {
        const parent_component = current_component;
        set_current_component(component);
        const prop_values = options.props || {};
        const $$ = component.$$ = {
            fragment: null,
            ctx: null,
            // state
            props,
            update: noop,
            not_equal,
            bound: blank_object(),
            // lifecycle
            on_mount: [],
            on_destroy: [],
            before_update: [],
            after_update: [],
            context: new Map(parent_component ? parent_component.$$.context : []),
            // everything else
            callbacks: blank_object(),
            dirty,
            skip_bound: false
        };
        let ready = false;
        $$.ctx = instance
            ? instance(component, prop_values, (i, ret, ...rest) => {
                const value = rest.length ? rest[0] : ret;
                if ($$.ctx && not_equal($$.ctx[i], $$.ctx[i] = value)) {
                    if (!$$.skip_bound && $$.bound[i])
                        $$.bound[i](value);
                    if (ready)
                        make_dirty(component, i);
                }
                return ret;
            })
            : [];
        $$.update();
        ready = true;
        run_all($$.before_update);
        // `false` as a special case of no DOM component
        $$.fragment = create_fragment ? create_fragment($$.ctx) : false;
        if (options.target) {
            if (options.hydrate) {
                const nodes = children(options.target);
                // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
                $$.fragment && $$.fragment.l(nodes);
                nodes.forEach(detach);
            }
            else {
                // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
                $$.fragment && $$.fragment.c();
            }
            if (options.intro)
                transition_in(component.$$.fragment);
            mount_component(component, options.target, options.anchor);
            flush();
        }
        set_current_component(parent_component);
    }
    class SvelteComponent {
        $destroy() {
            destroy_component(this, 1);
            this.$destroy = noop;
        }
        $on(type, callback) {
            const callbacks = (this.$$.callbacks[type] || (this.$$.callbacks[type] = []));
            callbacks.push(callback);
            return () => {
                const index = callbacks.indexOf(callback);
                if (index !== -1)
                    callbacks.splice(index, 1);
            };
        }
        $set($$props) {
            if (this.$$set && !is_empty($$props)) {
                this.$$.skip_bound = true;
                this.$$set($$props);
                this.$$.skip_bound = false;
            }
        }
    }

    /* node_modules/svelte-loading-spinners/src/Circle2.svelte generated by Svelte v3.24.1 */

    function add_css() {
    	var style = element("style");
    	style.id = "svelte-gkf9c4-style";
    	style.textContent = ".circle.svelte-gkf9c4{width:var(--size);height:var(--size);box-sizing:border-box;position:relative;border:3px solid transparent;border-top-color:var(--colorOuter);border-radius:50%;animation:svelte-gkf9c4-circleSpin 2s linear infinite}.circle.svelte-gkf9c4:before,.circle.svelte-gkf9c4:after{content:\"\";box-sizing:border-box;position:absolute;border:3px solid transparent;border-radius:50%}.circle.svelte-gkf9c4:after{border-top-color:var(--colorInner);top:9px;left:9px;right:9px;bottom:9px;animation:svelte-gkf9c4-circleSpin 1.5s linear infinite}.circle.svelte-gkf9c4:before{border-top-color:var(--colorCenter);top:3px;left:3px;right:3px;bottom:3px;animation:svelte-gkf9c4-circleSpin 3s linear infinite}@keyframes svelte-gkf9c4-circleSpin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}";
    	append(document.head, style);
    }

    function create_fragment(ctx) {
    	let div;

    	return {
    		c() {
    			div = element("div");
    			attr(div, "class", "circle svelte-gkf9c4");
    			set_style(div, "--size", /*size*/ ctx[0] + /*unit*/ ctx[1]);
    			set_style(div, "--colorInner", /*colorInner*/ ctx[4]);
    			set_style(div, "--colorCenter", /*colorCenter*/ ctx[3]);
    			set_style(div, "--colorOuter", /*colorOuter*/ ctx[2]);
    		},
    		m(target, anchor) {
    			insert(target, div, anchor);
    		},
    		p(ctx, [dirty]) {
    			if (dirty & /*size, unit*/ 3) {
    				set_style(div, "--size", /*size*/ ctx[0] + /*unit*/ ctx[1]);
    			}

    			if (dirty & /*colorInner*/ 16) {
    				set_style(div, "--colorInner", /*colorInner*/ ctx[4]);
    			}

    			if (dirty & /*colorCenter*/ 8) {
    				set_style(div, "--colorCenter", /*colorCenter*/ ctx[3]);
    			}

    			if (dirty & /*colorOuter*/ 4) {
    				set_style(div, "--colorOuter", /*colorOuter*/ ctx[2]);
    			}
    		},
    		i: noop,
    		o: noop,
    		d(detaching) {
    			if (detaching) detach(div);
    		}
    	};
    }

    function instance($$self, $$props, $$invalidate) {
    	let { size = 60 } = $$props;
    	let { unit = "px" } = $$props;
    	let { colorOuter = "#FF3E00" } = $$props;
    	let { colorCenter = "#40B3FF" } = $$props;
    	let { colorInner = "#676778" } = $$props;

    	$$self.$$set = $$props => {
    		if ("size" in $$props) $$invalidate(0, size = $$props.size);
    		if ("unit" in $$props) $$invalidate(1, unit = $$props.unit);
    		if ("colorOuter" in $$props) $$invalidate(2, colorOuter = $$props.colorOuter);
    		if ("colorCenter" in $$props) $$invalidate(3, colorCenter = $$props.colorCenter);
    		if ("colorInner" in $$props) $$invalidate(4, colorInner = $$props.colorInner);
    	};

    	return [size, unit, colorOuter, colorCenter, colorInner];
    }

    class Circle2 extends SvelteComponent {
    	constructor(options) {
    		super();
    		if (!document.getElementById("svelte-gkf9c4-style")) add_css();

    		init(this, options, instance, create_fragment, safe_not_equal, {
    			size: 0,
    			unit: 1,
    			colorOuter: 2,
    			colorCenter: 3,
    			colorInner: 4
    		});
    	}
    }

    /* src/conversation/Page.svelte generated by Svelte v3.24.1 */

    function get_each_context(ctx, list, i) {
    	const child_ctx = ctx.slice();
    	child_ctx[3] = list[i].name;
    	child_ctx[4] = list[i].emailAddress;
    	return child_ctx;
    }

    function get_each_context_1(ctx, list, i) {
    	const child_ctx = ctx.slice();
    	child_ctx[7] = list[i].checked;
    	child_ctx[8] = list[i].author;
    	child_ctx[9] = list[i].date;
    	child_ctx[10] = list[i].intro;
    	child_ctx[11] = list[i].html;
    	child_ctx[13] = i;
    	return child_ctx;
    }

    // (15:0) {:else}
    function create_else_block(ctx) {
    	let header;
    	let h1;
    	let t0;
    	let t1;
    	let div6;
    	let main;
    	let div0;
    	let t2;
    	let h2;
    	let t5;
    	let form0;
    	let t20;
    	let aside;
    	let h30;
    	let t22;
    	let style;
    	let t24;
    	let ul0;
    	let t26;
    	let h31;
    	let t28;
    	let ul1;
    	let t29;
    	let form1;
    	let t32;
    	let h32;
    	let t34;
    	let p;
    	let t36;
    	let label2;
    	let t40;
    	let label3;
    	let t44;
    	let label4;
    	let each_value_1 = /*messages*/ ctx[2];
    	let each_blocks_1 = [];

    	for (let i = 0; i < each_value_1.length; i += 1) {
    		each_blocks_1[i] = create_each_block_1(get_each_context_1(ctx, each_value_1, i));
    	}

    	let each_value = /*participants*/ ctx[1];
    	let each_blocks = [];

    	for (let i = 0; i < each_value.length; i += 1) {
    		each_blocks[i] = create_each_block(get_each_context(ctx, each_value, i));
    	}

    	return {
    		c() {
    			header = element("header");
    			h1 = element("h1");
    			t0 = text(/*topic*/ ctx[0]);
    			t1 = space();
    			div6 = element("div");
    			main = element("main");
    			div0 = element("div");

    			for (let i = 0; i < each_blocks_1.length; i += 1) {
    				each_blocks_1[i].c();
    			}

    			t2 = space();
    			h2 = element("h2");
    			h2.innerHTML = `This conversation has been resolved, <br> No further messages can be sent.`;
    			t5 = space();
    			form0 = element("form");

    			form0.innerHTML = `<input id="preview-tab" class="hidden" type="checkbox"> 
      <textarea class="w-full px-2 bg-white outline-none" name="content" style="min-height:14em" placeholder="Write message ..."></textarea> 
      <div id="preview" class="markdown-body p-2" style="min-height:14em;">No preview yet.</div> 
      <section class="font-bold flex px-2 pb-1"><span class="text-gray-700 pr-2">From:</span> 
        <input class="border-b bg-white border-white flex-grow focus:border-gray-700 outline-none placeholder-gray-700" type="text" name="from" placeholder="&lt;%= Helpers.email_address(identifier) %&gt;" value="Richard"></section> 
      <footer id="compose-menu" class="flex items-baseline border-t"><label class="font-bold flex px-2 py-1 justify-start items-start"><span class="text-gray-700 pr-2">Close conversation</span> 
          <div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500"><input type="checkbox" class="opacity-0 absolute" name="resolve"> 
            <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20"><path d="M0 11l2-2 5 5L18 3l2 2L7 18z"></path></svg></div></label> 
        <label for="preview-tab" class="ml-auto"><span class="m-1 ml-auto px-2 py-1 rounded border cursor-pointer border-indigo-900 focus:border-indigo-700 hover:border-indigo-700 text-indigo-800 font-bold mt-4">Preview</span></label> 
        <button class="m-1 px-2 py-1 rounded bg-indigo-900 focus:bg-indigo-700 hover:bg-indigo-700 text-white font-bold mt-4" type="submit">Send</button></footer>`;

    			t20 = space();
    			aside = element("aside");
    			h30 = element("h3");
    			h30.textContent = "Pins";
    			t22 = space();
    			style = element("style");
    			style.textContent = ".last-only {\n        display: none;\n      }\n\n      .last-only:last-child {\n        display: block;\n      }";
    			t24 = space();
    			ul0 = element("ul");
    			ul0.innerHTML = `<li class="last-only">Select message text to add first pin.</li>`;
    			t26 = space();
    			h31 = element("h3");
    			h31.textContent = "Participants";
    			t28 = space();
    			ul1 = element("ul");

    			for (let i = 0; i < each_blocks.length; i += 1) {
    				each_blocks[i].c();
    			}

    			t29 = space();
    			form1 = element("form");

    			form1.innerHTML = `<input class="duration-200 mt-2 px-4 py-1 rounded transition-colors bg-white" id="invite" type="text" name="emailAddress" value="" placeholder="email address"> 
      <button class="px-4 py-1 hover:bg-indigo-700 rounded bg-indigo-900 text-white mt-2" type="submit">Invite</button>`;

    			t32 = space();
    			h32 = element("h3");
    			h32.textContent = "Notifications";
    			t34 = space();
    			p = element("p");
    			p.textContent = "Send me notifications for";
    			t36 = space();
    			label2 = element("label");

    			label2.innerHTML = `<div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500"><input type="radio" class="opacity-0 absolute" name="resolve" checked=""> 
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20"><path d="M0 11l2-2 5 5L18 3l2 2L7 18z"></path></svg></div> 
      <span class="text-gray-700 pr-2">All messages</span>`;

    			t40 = space();
    			label3 = element("label");

    			label3.innerHTML = `<div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500"><input type="radio" class="opacity-0 absolute" name="resolve"> 
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20"><path d="M0 11l2-2 5 5L18 3l2 2L7 18z"></path></svg></div> 
      <span class="text-gray-700 pr-2">Conversation concluded</span>`;

    			t44 = space();
    			label4 = element("label");

    			label4.innerHTML = `<div class="bg-white border-2 rounded border-gray-400 w-6 h-6 flex flex-shrink-0 justify-center items-center mr-2 focus-within:border-blue-500"><input type="radio" class="opacity-0 absolute" name="resolve"> 
        <svg class="fill-current hidden w-4 h-4 text-indigo-800 pointer-events-none" viewBox="0 0 20 20"><path d="M0 11l2-2 5 5L18 3l2 2L7 18z"></path></svg></div> 
      <span class="text-gray-700 pr-2">Never</span>`;

    			attr(h1, "id", "topic");
    			attr(h1, "class", "text-2xl");
    			attr(header, "class", "max-w-3xl mx-auto text-center pt-6 pb-4");
    			attr(div0, "id", "messages");
    			attr(div0, "class", "");
    			attr(h2, "id", "concluded-banner");
    			attr(h2, "class", "hidden text-lg text-center font-bold text-gray-700 mb-14");
    			attr(form0, "id", "reply-form");
    			attr(form0, "class", "relative w-full rounded-2xl my-shadow bg-white mt-2 mb-8 py-6 px-20");
    			attr(form0, "data-action", "writeMessage");
    			attr(main, "class", "flex-grow max-w-3xl ml-auto px-2 mb-16");
    			attr(h30, "class", "font-bold");
    			attr(style, "media", "screen");
    			attr(ul0, "id", "pins");
    			attr(h31, "class", "font-bold mt-8");
    			attr(ul1, "id", "participants");
    			attr(form1, "class", "");
    			attr(form1, "data-action", "addParticipant");
    			attr(form1, "method", "post");
    			attr(h32, "class", "font-bold mt-4");
    			attr(label2, "class", "flex px-2 py-1 justify-start items-start");
    			attr(label3, "class", "flex px-2 py-1 justify-start items-start");
    			attr(label4, "class", "flex px-2 py-1 justify-start items-start");
    			attr(aside, "class", "w-full max-w-md flex flex-col py-2 px-6 text-gray-700 mr-auto");
    			attr(div6, "class", "flex");
    		},
    		m(target, anchor) {
    			insert(target, header, anchor);
    			append(header, h1);
    			append(h1, t0);
    			insert(target, t1, anchor);
    			insert(target, div6, anchor);
    			append(div6, main);
    			append(main, div0);

    			for (let i = 0; i < each_blocks_1.length; i += 1) {
    				each_blocks_1[i].m(div0, null);
    			}

    			append(main, t2);
    			append(main, h2);
    			append(main, t5);
    			append(main, form0);
    			append(div6, t20);
    			append(div6, aside);
    			append(aside, h30);
    			append(aside, t22);
    			append(aside, style);
    			append(aside, t24);
    			append(aside, ul0);
    			append(aside, t26);
    			append(aside, h31);
    			append(aside, t28);
    			append(aside, ul1);

    			for (let i = 0; i < each_blocks.length; i += 1) {
    				each_blocks[i].m(ul1, null);
    			}

    			append(aside, t29);
    			append(aside, form1);
    			append(aside, t32);
    			append(aside, h32);
    			append(aside, t34);
    			append(aside, p);
    			append(aside, t36);
    			append(aside, label2);
    			append(aside, t40);
    			append(aside, label3);
    			append(aside, t44);
    			append(aside, label4);
    		},
    		p(ctx, dirty) {
    			if (dirty & /*topic*/ 1) set_data(t0, /*topic*/ ctx[0]);

    			if (dirty & /*messages*/ 4) {
    				each_value_1 = /*messages*/ ctx[2];
    				let i;

    				for (i = 0; i < each_value_1.length; i += 1) {
    					const child_ctx = get_each_context_1(ctx, each_value_1, i);

    					if (each_blocks_1[i]) {
    						each_blocks_1[i].p(child_ctx, dirty);
    					} else {
    						each_blocks_1[i] = create_each_block_1(child_ctx);
    						each_blocks_1[i].c();
    						each_blocks_1[i].m(div0, null);
    					}
    				}

    				for (; i < each_blocks_1.length; i += 1) {
    					each_blocks_1[i].d(1);
    				}

    				each_blocks_1.length = each_value_1.length;
    			}

    			if (dirty & /*participants*/ 2) {
    				each_value = /*participants*/ ctx[1];
    				let i;

    				for (i = 0; i < each_value.length; i += 1) {
    					const child_ctx = get_each_context(ctx, each_value, i);

    					if (each_blocks[i]) {
    						each_blocks[i].p(child_ctx, dirty);
    					} else {
    						each_blocks[i] = create_each_block(child_ctx);
    						each_blocks[i].c();
    						each_blocks[i].m(ul1, null);
    					}
    				}

    				for (; i < each_blocks.length; i += 1) {
    					each_blocks[i].d(1);
    				}

    				each_blocks.length = each_value.length;
    			}
    		},
    		i: noop,
    		o: noop,
    		d(detaching) {
    			if (detaching) detach(header);
    			if (detaching) detach(t1);
    			if (detaching) detach(div6);
    			destroy_each(each_blocks_1, detaching);
    			destroy_each(each_blocks, detaching);
    		}
    	};
    }

    // (8:0) {#if !topic}
    function create_if_block(ctx) {
    	let div1;
    	let div0;
    	let circle2;
    	let current;

    	circle2 = new Circle2({
    			props: {
    				size: "25",
    				colorOuter: "#3c366b",
    				colorCenter: "#3c366b",
    				colorInner: "#3c366b",
    				unit: "vw"
    			}
    		});

    	return {
    		c() {
    			div1 = element("div");
    			div0 = element("div");
    			create_component(circle2.$$.fragment);
    			attr(div0, "class", "m-auto");
    			attr(div1, "class", "flex min-h-screen flex-col");
    		},
    		m(target, anchor) {
    			insert(target, div1, anchor);
    			append(div1, div0);
    			mount_component(circle2, div0, null);
    			current = true;
    		},
    		p: noop,
    		i(local) {
    			if (current) return;
    			transition_in(circle2.$$.fragment, local);
    			current = true;
    		},
    		o(local) {
    			transition_out(circle2.$$.fragment, local);
    			current = false;
    		},
    		d(detaching) {
    			if (detaching) detach(div1);
    			destroy_component(circle2);
    		}
    	};
    }

    // (23:6) {#each messages as {checked, author, date, intro, html}
    function create_each_block_1(ctx) {
    	let article;
    	let input;
    	let input_id_value;
    	let input_checked_value;
    	let t0;
    	let label;
    	let header;
    	let span0;
    	let t1_value = /*author*/ ctx[8] + "";
    	let t1;
    	let t2;
    	let span1;
    	let t3_value = /*date*/ ctx[9] + "";
    	let t3;
    	let t4;
    	let div0;
    	let label_for_value;
    	let t5;
    	let div1;
    	let t6_value = /*intro*/ ctx[10] + "";
    	let t6;
    	let t7;
    	let div2;
    	let raw_value = /*html*/ ctx[11] + "";
    	let t8;
    	let footer;
    	let t9;

    	return {
    		c() {
    			article = element("article");
    			input = element("input");
    			t0 = space();
    			label = element("label");
    			header = element("header");
    			span0 = element("span");
    			t1 = text(t1_value);
    			t2 = space();
    			span1 = element("span");
    			t3 = text(t3_value);
    			t4 = space();
    			div0 = element("div");
    			t5 = space();
    			div1 = element("div");
    			t6 = text(t6_value);
    			t7 = space();
    			div2 = element("div");
    			t8 = space();
    			footer = element("footer");
    			t9 = space();
    			attr(input, "id", input_id_value = "message-" + /*count*/ ctx[13]);
    			attr(input, "class", "message-checkbox hidden");
    			attr(input, "type", "checkbox");
    			input.checked = input_checked_value = /*checked*/ ctx[7];
    			attr(span0, "class", "font-bold ml-20");
    			attr(span1, "class", "ml-auto mr-8");
    			attr(header, "class", "pt-4 pb-4 flex");
    			attr(div0, "class", "message-overlay absolute bottom-0 top-0 right-0 left-0 ");
    			attr(label, "for", label_for_value = "message-" + /*count*/ ctx[13]);
    			attr(div1, "class", "content-intro px-20 truncate");
    			attr(div2, "class", "markdown-body px-20");
    			attr(footer, "class", "h-12 mb-2 mt-4");
    			attr(article, "class", "relative rounded-2xl my-shadow bg-white");
    		},
    		m(target, anchor) {
    			insert(target, article, anchor);
    			append(article, input);
    			append(article, t0);
    			append(article, label);
    			append(label, header);
    			append(header, span0);
    			append(span0, t1);
    			append(header, t2);
    			append(header, span1);
    			append(span1, t3);
    			append(label, t4);
    			append(label, div0);
    			append(article, t5);
    			append(article, div1);
    			append(div1, t6);
    			append(article, t7);
    			append(article, div2);
    			div2.innerHTML = raw_value;
    			append(article, t8);
    			append(article, footer);
    			append(article, t9);
    		},
    		p(ctx, dirty) {
    			if (dirty & /*messages*/ 4 && input_checked_value !== (input_checked_value = /*checked*/ ctx[7])) {
    				input.checked = input_checked_value;
    			}

    			if (dirty & /*messages*/ 4 && t1_value !== (t1_value = /*author*/ ctx[8] + "")) set_data(t1, t1_value);
    			if (dirty & /*messages*/ 4 && t3_value !== (t3_value = /*date*/ ctx[9] + "")) set_data(t3, t3_value);
    			if (dirty & /*messages*/ 4 && t6_value !== (t6_value = /*intro*/ ctx[10] + "")) set_data(t6, t6_value);
    			if (dirty & /*messages*/ 4 && raw_value !== (raw_value = /*html*/ ctx[11] + "")) div2.innerHTML = raw_value;		},
    		d(detaching) {
    			if (detaching) detach(article);
    		}
    	};
    }

    // (89:6) {#each participants as {name, emailAddress}}
    function create_each_block(ctx) {
    	let li;
    	let t0_value = /*name*/ ctx[3] + "";
    	let t0;
    	let t1;
    	let small;
    	let t2;
    	let t3_value = /*emailAddress*/ ctx[4] + "";
    	let t3;
    	let t4;

    	return {
    		c() {
    			li = element("li");
    			t0 = text(t0_value);
    			t1 = space();
    			small = element("small");
    			t2 = text("<");
    			t3 = text(t3_value);
    			t4 = text(">");
    			attr(li, "class", "m-1 whitespace-no-wrap truncate");
    		},
    		m(target, anchor) {
    			insert(target, li, anchor);
    			append(li, t0);
    			append(li, t1);
    			append(li, small);
    			append(small, t2);
    			append(small, t3);
    			append(small, t4);
    		},
    		p(ctx, dirty) {
    			if (dirty & /*participants*/ 2 && t0_value !== (t0_value = /*name*/ ctx[3] + "")) set_data(t0, t0_value);
    			if (dirty & /*participants*/ 2 && t3_value !== (t3_value = /*emailAddress*/ ctx[4] + "")) set_data(t3, t3_value);
    		},
    		d(detaching) {
    			if (detaching) detach(li);
    		}
    	};
    }

    function create_fragment$1(ctx) {
    	let current_block_type_index;
    	let if_block;
    	let if_block_anchor;
    	let current;
    	const if_block_creators = [create_if_block, create_else_block];
    	const if_blocks = [];

    	function select_block_type(ctx, dirty) {
    		if (!/*topic*/ ctx[0]) return 0;
    		return 1;
    	}

    	current_block_type_index = select_block_type(ctx);
    	if_block = if_blocks[current_block_type_index] = if_block_creators[current_block_type_index](ctx);

    	return {
    		c() {
    			if_block.c();
    			if_block_anchor = empty();
    		},
    		m(target, anchor) {
    			if_blocks[current_block_type_index].m(target, anchor);
    			insert(target, if_block_anchor, anchor);
    			current = true;
    		},
    		p(ctx, [dirty]) {
    			let previous_block_index = current_block_type_index;
    			current_block_type_index = select_block_type(ctx);

    			if (current_block_type_index === previous_block_index) {
    				if_blocks[current_block_type_index].p(ctx, dirty);
    			} else {
    				group_outros();

    				transition_out(if_blocks[previous_block_index], 1, 1, () => {
    					if_blocks[previous_block_index] = null;
    				});

    				check_outros();
    				if_block = if_blocks[current_block_type_index];

    				if (!if_block) {
    					if_block = if_blocks[current_block_type_index] = if_block_creators[current_block_type_index](ctx);
    					if_block.c();
    				}

    				transition_in(if_block, 1);
    				if_block.m(if_block_anchor.parentNode, if_block_anchor);
    			}
    		},
    		i(local) {
    			if (current) return;
    			transition_in(if_block);
    			current = true;
    		},
    		o(local) {
    			transition_out(if_block);
    			current = false;
    		},
    		d(detaching) {
    			if_blocks[current_block_type_index].d(detaching);
    			if (detaching) detach(if_block_anchor);
    		}
    	};
    }

    function instance$1($$self, $$props, $$invalidate) {
    	let { topic } = $$props;
    	let { participants = [] } = $$props;
    	let { messages = [] } = $$props;

    	$$self.$$set = $$props => {
    		if ("topic" in $$props) $$invalidate(0, topic = $$props.topic);
    		if ("participants" in $$props) $$invalidate(1, participants = $$props.participants);
    		if ("messages" in $$props) $$invalidate(2, messages = $$props.messages);
    	};

    	return [topic, participants, messages];
    }

    class Page extends SvelteComponent {
    	constructor(options) {
    		super();
    		init(this, options, instance$1, create_fragment$1, safe_not_equal, { topic: 0, participants: 1, messages: 2 });
    	}
    }

    const API_ROOT = "http://localhost:8000";

    async function fetchInbox() {
      const response = await fetch(API_ROOT + "/inbox", {
        credentials: "include"
      });
      return response
    }
    async function fetchConversation(id) {
      const response = await fetch(API_ROOT + "/c/" + id, {});
      return (await response.json()).conversation;
    }
    async function addParticipant(id, emailAddress) {
      const response = await fetch(API_ROOT + "/c/" + id + "/participant", {
        method: "POST",
        body: JSON.stringify({ email_address: emailAddress })
      });
      console.log(response);
      return {};
    }
    async function writeMessage(id, content) {
      const response = await fetch(API_ROOT + "/c/" + id + "/message", {
        method: "POST",
        body: JSON.stringify({ content: content })
      });
      console.log(response);
      return {};
    }

    function formValues($form) {
      // https://codepen.io/ntpumartin/pen/MWYmypq
      var obj = {};
      var elements = $form.querySelectorAll("input, select, textarea");
      for (var i = 0; i < elements.length; ++i) {
        var element = elements[i];
        var name = element.name;
        var value = element.value;
        var type = element.type;

        if (type === "checkbox") {
          obj[name] = element.checked;
        } else {
          if (name) {
            obj[name] = value;
          }

        }

      }
      return obj;
    }

    async function conversation() {
      const conversationId = parseInt(window.location.pathname.substr(3));

      const page = new Page({ target: document.body });
      let data = await fetchConversation(conversationId);
      let topic = data.topic;
      let participants = data.participants.map(function({
        email_address: emailAddress
      }) {
        const [name] = emailAddress.split("@");
        return { name, emailAddress };
      });
      let messages = data.messages.map(function ({content}) {
        const [intro] = content.trim().split(/\r?\n/);
        const html = marked(content);
        const checked = true;
        const date ="12 Aug";
        const author = "vov";
        return {checked, author, date, intro, html}
      });
      console.log(messages);
      page.$set({topic, participants, messages});

      document.addEventListener('submit', async function (event) {
        event.preventDefault();

        const action = event.target.dataset.action;

        const form = formValues(event.target);
        console.log(form);

        if (action === "addParticipant") {
          let {emailAddress} = form;

          let response = await addParticipant(conversationId, emailAddress);
          console.log(response);
          // window.location.reload()
        } else if (action == "writeMessage") {
          let {content} = form;

          let response = await writeMessage(conversationId, content);
          window.location.reload();
        }
      });
    }

    /* src/search/Page.svelte generated by Svelte v3.24.1 */

    function get_each_context$1(ctx, list, i) {
    	const child_ctx = ctx.slice();
    	child_ctx[2] = list[i].id;
    	child_ctx[3] = list[i].topic;
    	return child_ctx;
    }

    // (29:4) {#each results as {id, topic}}
    function create_each_block$1(ctx) {
    	let a;
    	let h2;
    	let t0_value = /*topic*/ ctx[3] + "";
    	let t0;
    	let t1;
    	let div;
    	let a_href_value;

    	return {
    		c() {
    			a = element("a");
    			h2 = element("h2");
    			t0 = text(t0_value);
    			t1 = space();
    			div = element("div");
    			div.textContent = "TODO participants";
    			attr(h2, "class", "font-bold my-1");
    			attr(div, "class", "truncate");
    			attr(a, "class", "block my-2 py-1 px-2 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl");
    			attr(a, "href", a_href_value = "/c/" + /*id*/ ctx[2]);
    		},
    		m(target, anchor) {
    			insert(target, a, anchor);
    			append(a, h2);
    			append(h2, t0);
    			append(a, t1);
    			append(a, div);
    		},
    		p(ctx, dirty) {
    			if (dirty & /*results*/ 1 && t0_value !== (t0_value = /*topic*/ ctx[3] + "")) set_data(t0, t0_value);

    			if (dirty & /*results*/ 1 && a_href_value !== (a_href_value = "/c/" + /*id*/ ctx[2])) {
    				attr(a, "href", a_href_value);
    			}
    		},
    		d(detaching) {
    			if (detaching) detach(a);
    		}
    	};
    }

    // (35:4) {#if newTopic}
    function create_if_block$1(ctx) {
    	let form;
    	let input;
    	let t0;
    	let button;
    	let h2;
    	let t1;
    	let span;
    	let t2;

    	return {
    		c() {
    			form = element("form");
    			input = element("input");
    			t0 = space();
    			button = element("button");
    			h2 = element("h2");
    			t1 = text("Start new conversation with topic: ");
    			span = element("span");
    			t2 = text(/*newTopic*/ ctx[1]);
    			attr(input, "type", "hidden");
    			attr(input, "name", "topic");
    			input.value = /*newTopic*/ ctx[1];
    			attr(span, "class", "font-bold");
    			attr(h2, "class", "my-1");
    			attr(button, "class", "block w-full text-left my-2 py-2 px-4 rounded border border-l-4 text-gray-800 bg-white focus:outline-none focus:text-gray-900 focus:border-indigo-800 hover:border-indigo-800 focus:shadow-xl");
    			attr(button, "type", "submit");
    			attr(form, "class", "");
    			attr(form, "action", "http://localhost:8000/c/create");
    			attr(form, "method", "post");
    		},
    		m(target, anchor) {
    			insert(target, form, anchor);
    			append(form, input);
    			append(form, t0);
    			append(form, button);
    			append(button, h2);
    			append(h2, t1);
    			append(h2, span);
    			append(span, t2);
    		},
    		p(ctx, dirty) {
    			if (dirty & /*newTopic*/ 2) {
    				input.value = /*newTopic*/ ctx[1];
    			}

    			if (dirty & /*newTopic*/ 2) set_data(t2, /*newTopic*/ ctx[1]);
    		},
    		d(detaching) {
    			if (detaching) detach(form);
    		}
    	};
    }

    function create_fragment$2(ctx) {
    	let header;
    	let t6;
    	let main;
    	let h1;
    	let t8;
    	let input1;
    	let t9;
    	let nav0;
    	let t10;
    	let t11;
    	let div;
    	let each_value = /*results*/ ctx[0];
    	let each_blocks = [];

    	for (let i = 0; i < each_value.length; i += 1) {
    		each_blocks[i] = create_each_block$1(get_each_context$1(ctx, each_value, i));
    	}

    	let if_block = /*newTopic*/ ctx[1] && create_if_block$1(ctx);

    	return {
    		c() {
    			header = element("header");

    			header.innerHTML = `<style media="screen">#notifications:checked ~ .inline-block  {
      display: none;
    }
    #notifications:checked ~ .hidden  {
      display: inline-block;
    }</style> 
  <label><input id="notifications" class="hidden" type="checkbox" name="" value=""> 
    <span class="inline-block ml-auto text-lg p-4"><span href="/c#1">Next update 8am <img class="inline-block w-8" src="002-clock.svg" alt=""></span></span> 
    <span class="hidden ml-auto text-lg p-4"><a href="/c#3">New messages <img class="inline-block w-8" src="003-chat.svg" alt=""></a></span></label>`;

    			t6 = space();
    			main = element("main");
    			h1 = element("h1");
    			h1.textContent = "plum mail";
    			t8 = space();
    			input1 = element("input");
    			t9 = space();
    			nav0 = element("nav");

    			for (let i = 0; i < each_blocks.length; i += 1) {
    				each_blocks[i].c();
    			}

    			t10 = space();
    			if (if_block) if_block.c();
    			t11 = space();
    			div = element("div");

    			div.innerHTML = `<nav class="inline-block my-4 text-indigo-800"><style media="screen">a[href="/index"]::after {
        content: ' ';
        width: 8px;
        height: 8px;
        background: #673AB7;
        display: inline-block;
        margin: 0 0 7px 7px;
        border-radius: 8px;
      }</style> 
    <a class="inline-block px-4 py-1 border-b-2 border-gray-100 focus:border-indigo-800 hover:border-indigo-800 outline-none" href="/index">Inbox</a> 
    <style media="screen">ol {
      max-height:0;
      transition:max-height 0.2s;
      overflow:hidden;
    }
    input[type="checkbox"]:checked + ol {
      max-height: 6em;
    }</style> 
    <label for="advanced-menu"><span class="inline-block px-4 py-1 border-b-2 border-gray-100 focus:border-indigo-800 hover:border-indigo-800 outline-none cursor-pointer" href="#">Menu</span></label> 
    <input class="hidden" type="checkbox" id="advanced-menu" name="advanced-menu" value=""> 
    <ol class="text-left m-2 mt-0" style=""><li class="border-l-2 border-gray-100 hover:border-indigo-800"><a class="px-3 mb-2 block w-full" href="/sign_out">Sign out (richard@plummail.co)</a></li></ol></nav>`;

    			attr(header, "class", "w-full max-w-2xl mx-auto text-right");
    			attr(h1, "class", "flex-grow font-serif text-indigo-800 text-6xl text-center");
    			attr(input1, "id", "search");
    			attr(input1, "type", "text");
    			attr(input1, "class", "w-full px-4 py-2 my-4 rounded border-2 border-gray-500 focus:bg-gray-100 text-black shadow-md focus:border-indigo-800 outline-none");
    			attr(input1, "placeholder", "Search by name, email, topic or content, also start conversation");
    			input1.autofocus = true;
    			attr(nav0, "id", "results");
    			attr(main, "class", "w-full max-w-2xl m-auto p-6");
    			attr(div, "class", "hidden w-full mx-auto text-center sticky bottom-0 mt-4 bg-gray-100");
    		},
    		m(target, anchor) {
    			insert(target, header, anchor);
    			insert(target, t6, anchor);
    			insert(target, main, anchor);
    			append(main, h1);
    			append(main, t8);
    			append(main, input1);
    			append(main, t9);
    			append(main, nav0);

    			for (let i = 0; i < each_blocks.length; i += 1) {
    				each_blocks[i].m(nav0, null);
    			}

    			append(nav0, t10);
    			if (if_block) if_block.m(nav0, null);
    			insert(target, t11, anchor);
    			insert(target, div, anchor);
    			input1.focus();
    		},
    		p(ctx, [dirty]) {
    			if (dirty & /*results*/ 1) {
    				each_value = /*results*/ ctx[0];
    				let i;

    				for (i = 0; i < each_value.length; i += 1) {
    					const child_ctx = get_each_context$1(ctx, each_value, i);

    					if (each_blocks[i]) {
    						each_blocks[i].p(child_ctx, dirty);
    					} else {
    						each_blocks[i] = create_each_block$1(child_ctx);
    						each_blocks[i].c();
    						each_blocks[i].m(nav0, t10);
    					}
    				}

    				for (; i < each_blocks.length; i += 1) {
    					each_blocks[i].d(1);
    				}

    				each_blocks.length = each_value.length;
    			}

    			if (/*newTopic*/ ctx[1]) {
    				if (if_block) {
    					if_block.p(ctx, dirty);
    				} else {
    					if_block = create_if_block$1(ctx);
    					if_block.c();
    					if_block.m(nav0, null);
    				}
    			} else if (if_block) {
    				if_block.d(1);
    				if_block = null;
    			}
    		},
    		i: noop,
    		o: noop,
    		d(detaching) {
    			if (detaching) detach(header);
    			if (detaching) detach(t6);
    			if (detaching) detach(main);
    			destroy_each(each_blocks, detaching);
    			if (if_block) if_block.d();
    			if (detaching) detach(t11);
    			if (detaching) detach(div);
    		}
    	};
    }

    function instance$2($$self, $$props, $$invalidate) {
    	let { results = [] } = $$props;
    	let { newTopic } = $$props;

    	$$self.$$set = $$props => {
    		if ("results" in $$props) $$invalidate(0, results = $$props.results);
    		if ("newTopic" in $$props) $$invalidate(1, newTopic = $$props.newTopic);
    	};

    	return [results, newTopic];
    }

    class Page$1 extends SvelteComponent {
    	constructor(options) {
    		super();
    		init(this, options, instance$2, create_fragment$2, safe_not_equal, { results: 0, newTopic: 1 });
    	}
    }

    async function search() {
      const page = new Page$1({ target: document.body });
      let response = await fetchInbox();
      if (response.status != 200) {
        window.location.pathname = "/sign_in";
      }
      let {conversations} = await response.json();
      console.log(conversations);
      let conversationSearch = new MiniSearch({
         fields: ['topic', 'participants', 'slug'], // fields to index for full-text search
         storeFields: ['topic', 'participants', 'slug'], // fields to return with search results
         tokenize: (string, fieldName) => {
           return string.split(/[\s,@]+/)
         },
         searchOptions: {
           tokenize: (string) => string.split(/[\s,@]+/) // search query tokenizer
         }
       });
       conversationSearch.addAll(conversations);

       function searchAll(term) {
         if (term.length == 0) {
           return []
         }
         return conversationSearch.search(term, {combineWith: 'AND', fuzzy: 0.2, prefix: true})
       }

       // Don't do if's in view stack up each's
       document.addEventListener("keyup", function (event) {
         var input;
         if (input = event.target.closest("input#search")) {
           let term = input.value;
           page.$set({results: searchAll(term), newTopic: term});
         }
       });
    }

    const boot = document.currentScript.dataset.boot;

    if (boot === "conversation") {
      conversation();
    } else if (boot === "search") {
      search();
    } else {
      throw "Unknown page: " + boot
    }

})));
