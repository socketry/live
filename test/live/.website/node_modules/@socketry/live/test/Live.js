import {describe, before, after, it} from 'node:test';
import {ok, strict, strictEqual, deepStrictEqual} from 'node:assert';

import {WebSocket} from 'ws';
import {JSDOM} from 'jsdom';
import {Live} from '../Live.js';

describe('Live', function () {
	let dom;
	let webSocketServer;

	const webSocketServerConfig = {port: 3000};
	const webSocketServerURL = `ws://localhost:${webSocketServerConfig.port}/live`;

	before(async function () {
		const listening = new Promise((resolve, reject) => {
			webSocketServer = new WebSocket.Server(webSocketServerConfig, resolve);
			webSocketServer.on('error', reject);
		});
		
		dom = new JSDOM('<!DOCTYPE html><html><body><div id="my"><p>Hello World</p></div></body></html>');
		// Ensure the WebSocket class is available:
		dom.window.WebSocket = WebSocket;
		
		await new Promise(resolve => dom.window.addEventListener('load', resolve));
		
		await listening;
	});
	
	after(function () {
		webSocketServer.close();
	});
	
	it('should start the live connection', function () {
		const live = Live.start({window: dom.window, base: 'http://localhost/'});
		ok(live);
		
		strictEqual(live.window, dom.window);
		strictEqual(live.document, dom.window.document);
		strictEqual(live.url.href, 'ws://localhost/live');
	});
	
	it('should connect to the WebSocket server', function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		const server = live.connect();
		ok(server);
		
		live.disconnect();
	});
	
	it('should handle visibility changes', function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		var hidden = false;
		Object.defineProperty(dom.window.document, "hidden", {
			get() {return hidden},
		});
		
		live.handleVisibilityChange();
		
		ok(live.server);
		
		hidden = true;
		
		live.handleVisibilityChange();
		
		ok(!live.server);
	});
	
	it('should handle updates', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'reply') resolve(payload);
			});
		});
		
		socket.send(
			JSON.stringify(['update', 'my', '<div id="my"><p>Goodbye World!</p></div>', {reply: true}])
		);
		
		await reply;
		
		strictEqual(dom.window.document.getElementById('my').innerHTML, '<p>Goodbye World!</p>');
		
		live.disconnect();
	});
	
	it('should handle updates with child live elements', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				console.log("message", payload);
				if (payload[0] == 'bind') resolve(payload);
				else console.log("ignoring", payload);
			});
		});
		
		socket.send(
			JSON.stringify(['update', 'my', '<div id="my"><div id="mychild" class="live"></div></div>'])
		);
		
		let payload = await reply;
		
		deepStrictEqual(payload, ['bind', 'mychild', {}]);
		
		live.disconnect();
	});
	
	it('can unbind removed elements', async function () {
		dom.window.document.body.innerHTML = '<div id="my" class="live"><p>Hello World</p></div>';
		
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'unbind') resolve(payload);
				else console.log("ignoring", payload);
			});
		});
		
		live.attach();
		
		dom.window.document.getElementById('my').remove();
		
		let payload = await reply;
		
		deepStrictEqual(payload, ['unbind', 'my']);
		
		live.disconnect();
	});
	
	it('should handle replacements', async function () {
		dom.window.document.body.innerHTML = '<div id="my"><p>Hello World</p></div>';
		
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'reply') resolve(payload);
				else console.log("ignoring", payload);
			});
		});
		
		socket.send(
			JSON.stringify(['replace', '#my p', '<p>Replaced!</p>', {reply: true}])
		);
		
		await reply;
		
		strictEqual(dom.window.document.getElementById('my').innerHTML, '<p>Replaced!</p>');
		
		live.disconnect();
	});
	
	it('should handle prepends', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		socket.send(
			JSON.stringify(['update', 'my', '<div id="my"><p>Middle</p></div>'])
		);
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'reply') resolve(payload);
				else console.log("ignoring", payload);
			});
		});
		
		socket.send(
			JSON.stringify(['prepend', '#my', '<p>Prepended!</p>', {reply: true}])
		);
		
		await reply;
		
		strictEqual(dom.window.document.getElementById('my').innerHTML, '<p>Prepended!</p><p>Middle</p>');
		
		live.disconnect();
	});
	
	it('should handle appends', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		socket.send(
			JSON.stringify(['update', 'my', '<div id="my"><p>Middle</p></div>'])
		);
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'reply') resolve(payload);
				else console.log("ignoring", payload);
			});
		});
		
		socket.send(
			JSON.stringify(['append', '#my', '<p>Appended!</p>', {reply: true}])
		);
		
		await reply;
		
		strictEqual(dom.window.document.getElementById('my').innerHTML, '<p>Middle</p><p>Appended!</p>');
		
		live.disconnect();
	});
	
	it ('should handle removals', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		socket.send(
			JSON.stringify(['update', 'my', '<div id="my"><p>Middle</p></div>'])
		);
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'reply') resolve(payload);
			});
		});
		
		socket.send(
			JSON.stringify(['remove', '#my p', {reply: true}])
		);
		
		await reply;
		
		strictEqual(dom.window.document.getElementById('my').innerHTML, '');
		
		live.disconnect();
	});
	
	it ('can dispatch custom events', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'reply') resolve(payload);
			});
		});
		
		socket.send(
			JSON.stringify(['dispatchEvent', '#my', 'click', {reply: true}])
		);
		
		await reply;
		
		live.disconnect();
	});
	
	it ('can forward events', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload[0] == 'event') resolve(payload);
			});
		});
		
		dom.window.document.getElementById('my').addEventListener('click', event => {
			live.forwardEvent('my', event);
		});
		
		dom.window.document.getElementById('my').click();
		
		let payload = await reply;
		
		strictEqual(payload[1], 'my');
		strictEqual(payload[2].type, 'click');
		
		live.disconnect();
	});
});
