// SPDX-License-Identifier: GPL-3.0-or-later
// Script logic only. This is not native browser or visual acceptance evidence.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const listeners = {}, timers = [], calls = [], elements = [];
let now = 0, expired = false, remaining = 3;
function element(tag) {
  const node = {tag, style: {}, children: [], events: {}, removed: false,
    setAttribute() {}, appendChild(item) {this.children.push(item);},
    replaceChildren(...items) {this.children = items;}, remove() {this.removed = true;},
    addEventListener(name, fn) {this.events[name] = fn;}};
  elements.push(node); return node;
}
const sandbox = {
  document: {readyState: 'complete', body: element('body'), createElement: element,
    createTextNode: (text) => ({text}), addEventListener: (name, fn) => {listeners[name] = fn;}},
  window: {location: {assign: (value) => {calls.push({navigate: value});}}},
  Date: {now: () => now}, setInterval: (fn) => {timers.push(fn);},
  fetch: async (url, options) => {
    calls.push({url, method: options.method || 'GET'});
    return {ok: !expired, status: expired ? 401 : 200,
            json: async () => ({remaining, warning: 10, busy: false})};
  }
};
async function settle() {await Promise.resolve(); await Promise.resolve(); await Promise.resolve();}
(async () => {
  vm.runInNewContext(fs.readFileSync(process.argv[2], 'utf8'), sandbox);
  await settle();
  assert.equal(calls.filter(x => x.url === '/_bnv/activity').length, 1);
  await timers[0]();
  assert.equal(calls.filter(x => x.url === '/_bnv/activity').length, 1, 'Status polls must not renew activity');
  const warning = elements.filter(x => x.tag === 'aside').at(-1);
  assert.equal(warning.children.at(-1).textContent, 'Keep session');
  warning.children.at(-1).events.click(); await settle();
  assert.equal(calls.filter(x => x.url === '/_bnv/activity').length, 2);
  now = 10000;
  listeners.pointermove({buttons: 0}); await settle();
  assert.equal(calls.filter(x => x.url === '/_bnv/activity').length, 2);
  listeners.pointerdown(); await settle();
  assert.equal(calls.filter(x => x.url === '/_bnv/activity').length, 3);
  expired = true;
  await timers[0]();
  const end = elements.filter(x => x.tag === 'aside').at(-1);
  assert.equal(end.children.at(-1).textContent, 'Sign in');
  end.children.at(-1).events.click();
  assert.equal(calls.at(-1).navigate, '/_bnv/login');
  console.log('Session client logic: 8 assertions passed (mock DOM, not native browser).');
})().catch(error => {console.error(error); process.exitCode = 1;});
