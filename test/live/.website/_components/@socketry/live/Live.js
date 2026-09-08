import morphdom from 'morphdom';

// ViewElement - Base class for Live.js custom elements
export class ViewElement extends HTMLElement {
	static observedAttributes = [];
	static connectedElements = new Set();
	
	connectedCallback() {
		if (!this.id) {
			this.id = crypto.randomUUID();
		}
		
		ViewElement.connectedElements.add(this);
		
		const window = this.ownerDocument.defaultView;
		if (window && window.live) {
			window.live.bind(this);
		}
	}
	
	disconnectedCallback() {
		ViewElement.connectedElements.delete(this);
		
		const window = this.ownerDocument.defaultView;
		if (window && window.live) {
			window.live.unbind(this);
		}
	}
}

export class Live {
	#window;
	#document;
	#server;
	#events;
	#failures;
	#reconnectTimer;
	
	static start(options = {}) {
		let window = options.window || globalThis;
		if (window.live) throw new Error("Live.js is already started!");
		
		let path = options.path || 'live'
		let base = options.base || window.location.href;
		
		let url = new URL(path, base);
		url.protocol = url.protocol.replace('http', 'ws');
		
		window.live = new this(window, url);
		if (!window.customElements.get('live-view')) {
			window.customElements.define('live-view', ViewElement);
		}
		
		return window.live;
	}
	
	constructor(window, url) {
		this.#window = window;
		this.#document = window.document;
		
		this.url = url;
		this.#server = null;
		this.#events = [];
		
		this.#failures = 0;
		this.#reconnectTimer = null;
		
		// Track visibility state and connect if required:
		this.#document.addEventListener("visibilitychange", () => this.#handleVisibilityChange());
		
		this.#handleVisibilityChange();
	}
	
	// -- Connection Handling --
	
	connect() {
		if (this.#server) {
			return this.#server;
		}
		
		let server = this.#server = new this.#window.WebSocket(this.url);
		
		if (this.#reconnectTimer) {
			clearTimeout(this.#reconnectTimer);
			this.#reconnectTimer = null;
		}
		
		server.onopen = () => {
			this.#failures = 0;
			this.#flush();
			this.#attach();
		};
		
		server.onmessage = (message) => {
			const [name, ...args] = JSON.parse(message.data);
			
			this[name](...args);
		};
		
		// The remote end has disconnected:
		server.addEventListener('error', () => {
			this.#failures += 1;
		});
		
		server.addEventListener('close', () => {
			// Explicit disconnect will clear `this.#server`:
			if (this.#server && !this.#reconnectTimer) {
				// We need a minimum delay otherwise this can end up immediately invoking the callback:
				const delay = Math.min(100 * (this.#failures ** 2), 60000);
				this.#reconnectTimer = setTimeout(() => {
					this.#reconnectTimer = null;
					this.connect();
				}, delay);
			}
			
			if (this.#server === server) {
				this.#server = null;
			}
		});
		
		return server;
	}
	
	disconnect() {
		if (this.#server) {
			const server = this.#server;
			this.#server = null;
			server.close();
		}
		
		if (this.#reconnectTimer) {
			clearTimeout(this.#reconnectTimer);
			this.#reconnectTimer = null;
		}
	}
	
	#send(message) {
		if (this.#server) {
			try {
				return this.#server.send(message);
			} catch (error) {
				// console.log("Live.send", "failed to send message to server", error);
			}
		}
		
		this.#events.push(message);
	}
	
	#flush() {
		if (this.#events.length === 0) return;
		
		let events = this.#events;
		this.#events = [];
		
		for (var event of events) {
			this.#send(event);
		}
	}
	
	#handleVisibilityChange() {
		if (this.#document.hidden) {
			this.disconnect();
		} else {
			this.connect();
		}
	}
	
	bind(element) {
		this.#send(JSON.stringify(['bind', element.id, element.dataset]));
	}

	unbind(element) {
		if (this.#server) {
			this.#send(JSON.stringify(['unbind', element.id]));
		}
	}

	#attach() {
		for (let element of ViewElement.connectedElements) {
			this.bind(element);
		}
	}
	
	#createDocumentFragment(html) {
		return this.#document.createRange().createContextualFragment(html);
	}
	
	#reply(options, ...args) {
		if (options?.reply) {
			this.#send(JSON.stringify(['reply', options.reply, ...args]));
		}
	}
	
	// -- RPC Methods --
	
	script(id, code, options) {
		let element = this.#document.getElementById(id);
		
		try {
			let result = this.#window.Function(code).call(element);
			
			this.#reply(options, result);
		} catch (error) {
			this.#reply(options, null, {name: error.name, message: error.message, stack: error.stack});
		}
	}
	
	update(id, html, options) {
		let element = this.#document.getElementById(id);
		let fragment = this.#createDocumentFragment(html);
		
		morphdom(element, fragment);
		
		this.#reply(options);
	}
	
	replace(selector, html, options) {
		let elements = this.#document.querySelectorAll(selector);
		let fragment = this.#createDocumentFragment(html);
		
		elements.forEach(element => morphdom(element, fragment.cloneNode(true)));
		
		this.#reply(options);
	}
	
	prepend(selector, html, options) {
		let elements = this.#document.querySelectorAll(selector);
		let fragment = this.#createDocumentFragment(html);
		
		elements.forEach(element => element.prepend(fragment.cloneNode(true)));
		
		this.#reply(options);
	}
	
	append(selector, html, options) {
		let elements = this.#document.querySelectorAll(selector);
		let fragment = this.#createDocumentFragment(html);
		
		elements.forEach(element => element.append(fragment.cloneNode(true)));
		
		this.#reply(options);
	}
	
	remove(selector, options) {
		let elements = this.#document.querySelectorAll(selector);
		
		elements.forEach(element => element.remove());
		
		this.#reply(options);
	}
	
	dispatchEvent(selector, type, options) {
		let elements = this.#document.querySelectorAll(selector);
		
		elements.forEach(element => element.dispatchEvent(
			new this.#window.CustomEvent(type, options)
		));
		
		this.#reply(options);
	}
	
	error(message) {
		console.error("Live.error", ...arguments);
	}
	
	// -- Event Handling --
	
	forward(id, event) {
		this.connect();
		
		this.#send(
			JSON.stringify(['event', id, event])
		);
	}
	
	forwardEvent(id, event, detail, preventDefault = false) {
		if (preventDefault) event.preventDefault();
		
		this.forward(id, {type: event.type, detail: detail});
	}
	
	forwardFormEvent(id, event, detail, preventDefault = true) {
		if (preventDefault) event.preventDefault();
		
		let form = event.form;
		let formData = new FormData(form);
		
		this.forward(id, {type: event.type, detail: detail, formData: [...formData]});
	}
}
