import morphdom from 'morphdom';

export class Live {
	static start(options = {}) {
		let window = options.window || globalThis;
		let path = options.path || 'live'
		let base = options.base || window.location.href;
		
		let url = new URL(path, base);
		url.protocol = url.protocol.replace('http', 'ws');
		
		return new this(window, url);
	}
	
	constructor(window, url) {
		this.window = window;
		this.document = window.document;
		
		this.url = url;
		this.events = [];
		
		this.failures = 0;
		this.reconnectTimer = null;
		
		// Track visibility state and connect if required:
		this.document.addEventListener("visibilitychange", () => this.handleVisibilityChange());
		this.handleVisibilityChange();
		
		const elementNodeType = this.window.Node.ELEMENT_NODE;
		
		// Create a MutationObserver to watch for removed nodes
		this.observer = new this.window.MutationObserver((mutationsList, observer) => {
			for (let mutation of mutationsList) {
				if (mutation.type === 'childList') {
					for (let node of mutation.removedNodes) {
						if (node.nodeType !== elementNodeType) continue;
						
						if (node.classList?.contains('live')) {
							this.unbind(node);
						}
						
						// Unbind any child nodes:
						for (let child of node.getElementsByClassName('live')) {
							this.unbind(child);
						}
					}
					
					for (let node of mutation.addedNodes) {
						if (node.nodeType !== elementNodeType) continue;
						
						if (node.classList.contains('live')) {
							this.bind(node);
						}
						
						// Bind any child nodes:
						for (let child of node.getElementsByClassName('live')) {
							this.bind(child);
						}
					}
				}
			}
		});
		
		this.observer.observe(this.document.body, {childList: true, subtree: true});
	}
	
	// -- Connection Handling --
	
	connect() {
		if (this.server) {
			return this.server;
		}
		
		let server = this.server = new this.window.WebSocket(this.url);
		
		if (this.reconnectTimer) {
			clearTimeout(this.reconnectTimer);
			this.reconnectTimer = null;
		}
		
		server.onopen = () => {
			this.failures = 0;
			this.flush();
			this.attach();
		};
		
		server.onmessage = (message) => {
			const [name, ..._arguments] = JSON.parse(message.data);
			
			this[name](..._arguments);
		};
		
		// The remote end has disconnected:
		server.addEventListener('error', () => {
			this.failures += 1;
		});
		
		server.addEventListener('close', () => {
			// Explicit disconnect will clear `this.server`:
			if (this.server && !this.reconnectTimer) {
				// We need a minimum delay otherwise this can end up immediately invoking the callback:
				const delay = Math.max(100 * (this.failures + 1) ** 2, 60000);
				this.reconnectTimer = setTimeout(() => {
					this.reconnectTimer = null;
					this.connect();
				}, delay);
			}
			
			if (this.server === server) {
				this.server = null;
			}
		});
		
		return server;
	}
	
	disconnect() {
		if (this.server) {
			const server = this.server;
			this.server = null;
			server.close();
		}
		
		if (this.reconnectTimer) {
			clearTimeout(this.reconnectTimer);
			this.reconnectTimer = null;
		}
	}
	
	send(message) {
		if (this.server) {
			try {
				return this.server.send(message);
			} catch (error) {
				// console.log("Live.send", "failed to send message to server", error);
			}
		}
		
		this.events.push(message);
	}
	
	flush() {
		if (this.events.length === 0) return;
		
		let events = this.events;
		this.events = [];
		
		for (var event of events) {
			this.send(event);
		}
	}
	
	handleVisibilityChange() {
		if (this.document.hidden) {
			this.disconnect();
		} else {
			this.connect();
		}
	}
	
	bind(element) {
		console.log("bind", element.id, element.dataset);
		
		this.send(JSON.stringify(['bind', element.id, element.dataset]));
	}
	
	unbind(element) {
		console.log("unbind", element.id, element.dataset);
		
		if (this.server) {
			this.send(JSON.stringify(['unbind', element.id]));
		}
	}
	
	attach() {
		for (let node of this.document.getElementsByClassName('live')) {
			this.bind(node);
		}
	}
	
	createDocumentFragment(html) {
		return this.document.createRange().createContextualFragment(html);
	}
	
	reply(options) {
		if (options?.reply) {
			this.send(JSON.stringify(['reply', options.reply]));
		}
	}
	
	// -- RPC Methods --
	
	update(id, html, options) {
		let element = this.document.getElementById(id);
		let fragment = this.createDocumentFragment(html);
		
		morphdom(element, fragment);
		
		this.reply(options);
	}
	
	replace(selector, html, options) {
		let elements = this.document.querySelectorAll(selector);
		let fragment = this.createDocumentFragment(html);
		
		elements.forEach(element => morphdom(element, fragment.cloneNode(true)));
		
		this.reply(options);
	}
	
	prepend(selector, html, options) {
		let elements = this.document.querySelectorAll(selector);
		let fragment = this.createDocumentFragment(html);
		
		elements.forEach(element => element.prepend(fragment.cloneNode(true)));
		
		this.reply(options);
	}
	
	append(selector, html, options) {
		let elements = this.document.querySelectorAll(selector);
		let fragment = this.createDocumentFragment(html);
		
		elements.forEach(element => element.append(fragment.cloneNode(true)));
		
		this.reply(options);
	}
	
	remove(selector, options) {
		let elements = this.document.querySelectorAll(selector);
		
		elements.forEach(element => element.remove());
		
		this.reply(options);
	}
	
	dispatchEvent(selector, type, options) {
		let elements = this.document.querySelectorAll(selector);
		
		elements.forEach(element => element.dispatchEvent(
			new this.window.CustomEvent(type, options)
		));
		
		this.reply(options);
	}
	
	// -- Event Handling --
	
	forward(id, event) {
		this.connect();
		
		this.send(
			JSON.stringify(['event', id, event])
		);
	}
	
	forwardEvent(id, event, detail) {
		event.preventDefault();
		
		this.forward(id, {type: event.type, detail: detail});
	}
	
	forwardFormEvent(id, event, detail) {
		event.preventDefault();
		
		let form = event.form;
		let formData = new FormData(form);
		
		this.forward(id, {type: event.type, detail: detail, formData: [...formData]});
	}
}
