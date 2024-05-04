import {describe, before, after, it} from 'node:test';
import {ok, strict, strictEqual} from 'node:assert';

import {WebSocket} from 'ws';
import {JSDOM} from 'jsdom';
import {Live} from '../Live.js';

describe('Live', function () {
	let dom;
	let webSocketServer;

	const webSocketServerConfig = {port: 3000};
	const webSocketServerURL = `ws://localhost:${webSocketServerConfig.port}/live`;

	before(async function () {
		const listening = new Promise(resolve => {
			webSocketServer = new WebSocket.Server(webSocketServerConfig, resolve);
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
				if (payload.reply) resolve(payload);
			});
		});
		
		socket.send(
			JSON.stringify(['update', 'my', '<div id="my"><p>Goodbye World!</p></div>', {reply: true}])
		);
		
		await reply;
		
		strictEqual(dom.window.document.getElementById('my').innerHTML, '<p>Goodbye World!</p>');
		
		live.disconnect();
	});
	
	it('should handle replacements', async function () {
		const live = new Live(dom.window, webSocketServerURL);
		
		live.connect();
		
		const connected = new Promise(resolve => {
			webSocketServer.on('connection', resolve);
		});
		
		let socket = await connected;
		
		const reply = new Promise((resolve, reject) => {
			socket.on('message', message => {
				let payload = JSON.parse(message);
				if (payload.reply) resolve(payload);
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
				if (payload.reply) resolve(payload);
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
				if (payload.reply) resolve(payload);
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
				if (payload.reply) resolve(payload);
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
				if (payload.reply) resolve(payload);
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
				if (payload.event) resolve(payload);
			});
		});
		
		dom.window.document.getElementById('my').addEventListener('click', event => {
			live.forwardEvent('my', event);
		});
		
		dom.window.document.getElementById('my').click();
		
		let payload = await reply;
		
		strictEqual(payload.id, 'my');
		strictEqual(payload.event.type, 'click');
		
		live.disconnect();
	});
});
