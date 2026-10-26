// SPDX-License-Identifier: GPL-3.0-or-later
// Narrow error handling tests; actual browser teardown is verified separately.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const remove = 'viewport.image.push.observer.remove';
const closed = {code: -32099, message: `RPC call ${remove} unsuccessful: connection not open`};
let current, remote, listener;
const trame = {
  client: {getImageStream: () => current && Object.freeze({getProtocol: () => current}),
    getRemote: () => remote && {Trame: remote}},
  addConnectListener: fn => {listener = fn; fn();},
};
function protocol(result) {
  // Model the pinned client's frozen session and mutable image-stream protocol.
  const session = Object.freeze({call: () => result});
  return {calls: [], unregisterView(...args) {this.calls.push(args); return session.call(remove, args);},
    render: () => session.call('viewport.image.push')};
}
(async () => {
  vm.runInNewContext(fs.readFileSync(process.argv[2], 'utf8'), {window: {trame}});
  current = protocol(Promise.resolve({result: 'success'})); listener();
  const first = current.unregisterView; listener(); assert.equal(current.unregisterView, first);
  assert.deepEqual(await current.unregisterView(7), {result: 'success'});
  assert.deepEqual(current.calls, [[7]]);
  current = protocol(Promise.reject(closed)); listener();
  assert.equal(await current.unregisterView(8), undefined);
  for (const error of [{code: -32000, message: 'Authentication failed'},
                       {code: -32099, message: 'Server cleanup failed'},
                       {code: -1, message: closed.message}]) {
    current = protocol(Promise.reject(error)); listener();
    await assert.rejects(current.unregisterView(9), actual => actual === error);
  }
  current = protocol(Promise.reject(closed)); listener();
  await assert.rejects(current.render(), actual => actual === closed);
  const unchanged = Promise.resolve('render result');
  current = protocol(unchanged); listener();
  assert.equal(current.render(), unchanged);
  const lifecycleClosed = {code: -32099, message: 'RPC call trame.lifecycle.update unsuccessful: connection not open'};
  for (const event of ['client_exited', 'client_unmounted']) {
    remote = {lifeCycleUpdate: () => Promise.reject(lifecycleClosed)}; listener();
    const first = remote.lifeCycleUpdate; listener(); assert.equal(remote.lifeCycleUpdate, first);
    assert.equal(await remote.lifeCycleUpdate(event), undefined);
  }
  remote = {lifeCycleUpdate: () => Promise.reject(lifecycleClosed)}; listener();
  await assert.rejects(remote.lifeCycleUpdate('client_connected'), error => error === lifecycleClosed);
  const auth = {code: -32000, message: 'Authentication failed'};
  remote = {lifeCycleUpdate: () => Promise.reject(auth)}; listener();
  await assert.rejects(remote.lifeCycleUpdate('client_exited'), error => error === auth);
  remote = {calls: [], lifeCycleUpdate(...args) {this.calls.push(args); return unchanged;}}; listener();
  assert.equal(remote.lifeCycleUpdate('client_connected'), unchanged);
  assert.equal(await remote.lifeCycleUpdate('client_exited', 7), 'render result');
  assert.deepEqual(remote.calls, [['client_connected'], ['client_exited', 7]]);
  console.log('Connection cleanup: 18 targeted assertions passed (frozen-session model, not browser).');
})().catch(error => {console.error(error); process.exitCode = 1;});
