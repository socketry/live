var live = (function () {
	'use strict';

	class Live {
		constructor(document, url) {
			this.document = document;
			
			this.url = url;
			this.events = [];
			
			this.failures = 0;
			
			// Track visibility state and connect if required:
			this.document.addEventListener("visibilitychange", () => this.handleVisibilityChange());
			this.handleVisibilityChange();
		}
		
		connect() {
			if (this.server) return;
			
			let server = this.server = new WebSocket(this.url.href);
			
			server.onopen = () => {
				this.failures = 0;
				this.attach();
			};
			
			server.onmessage = (message) => {
				const [name, _arguments] = JSON.parse(message.data);
				
				this[name](..._arguments);
			};
			
			server.onerror = () => {
				this.failures += 1;
			};
			
			// The remote end has disconnected:
			server.onclose = () => {
				this.server = null;
				
				// We need a minimum delay otherwise this can end up immediately invoking the callback:
				let delay = 100 * (this.failures + 1) ** 2;
				setTimeout(() => this.connect(), delay > 60000 ? 60000 : delay);
			};
		}
		
		disconnect() {
			if (this.server) {
				this.server.close();
				this.server = null;
			}
		}
		
		createDocumentFragment(html) {
			return this.document.createRange().createContextualFragment(html);
		}
		
		// These methods are designed for RPC.
		replace(id, html) {
			let element = document.getElementById(id);
			
			morphdom(element, html);
		}
		
		prepend(id, html) {
			let element = document.getElementById(id);
			let fragment = this.createDocumentFragment(html);
			
			element.prepend(fragment);
		}
		
		append(id, html) {
			let element = document.getElementById(id);
			let fragment = this.createDocumentFragment(html);
			
			element.append(fragment);
		}
		
		dispatch(id, type, details) {
			let element = document.getElementById(id);
			
			element.dispatchEvent(
				new CustomEvent(type, details)
			);
		}
		
		trigger(id, event) {
			this.connect();
			
			this.send(
				JSON.stringify({id: id, event: event})
			);
		}
		
		forward(id, event, details) {
			this.trigger(id, {type: event.type, details: details});
		}
		
		send(message) {
			try {
				this.server.send(message);
			} catch (error) {
				this.events.push(message);
			}
		}
		
		flush() {
			if (this.events.length === 0) return;
			
			let events = this.events;
			this.events = [];
			
			for (var event of events) {
				this.send(event);
			}
		}
		
		bind(elements) {
			for (var element of elements) {
				this.send(JSON.stringify({bind: element.id, data: element.dataset}));
			}
		}
		
		bindElementsByClassName(selector = 'live') {
			this.bind(
				this.document.getElementsByClassName(selector)
			);
			
			this.flush();
		}
		
		handleVisibilityChange() {
			if (document.hidden) {
				this.disconnect();
			} else {
				this.connect();
			}
		}
		
		attach() {
			if (this.document.readyState === 'loading') {
				this.document.addEventListener('DOMContentLoaded', () => this.bindElementsByClassName());
			} else {
				this.bindElementsByClassName();
			}
		}
	}

	let url = new URL('live', location.href);
	url.protocol = url.protocol.replace('http', 'ws');

	let live = new Live(document, url);

	return live;

}());
