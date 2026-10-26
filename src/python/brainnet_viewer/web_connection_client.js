// SPDX-License-Identifier: GPL-3.0-or-later
// The pinned client sends teardown RPCs after wslink has disconnected.
// Treat only those unsent cleanup requests as complete; retain other failures.
(() => {
  'use strict';
  const trame = window.trame;
  const installed = new WeakSet();
  function cleanup(result, method) {
    return result.catch(error => {
      if (error?.code === -32099 &&
          error.message === `RPC call ${method} unsuccessful: connection not open`) return;
      throw error;
    });
  }
  trame.addConnectListener(() => {
    // wslink sessions are frozen. The image stream exposes its mutable protocol.
    const protocol = trame.client?.getImageStream()?.getProtocol();
    if (protocol && !installed.has(protocol)) {
      installed.add(protocol);
      const unregister = protocol.unregisterView;
      protocol.unregisterView = function (...args) {
        return cleanup(unregister.apply(this, args), 'viewport.image.push.observer.remove');
      };
    }
    const remote = trame.client?.getRemote()?.Trame;
    if (remote && !installed.has(remote)) {
      installed.add(remote);
      const lifecycle = remote.lifeCycleUpdate;
      remote.lifeCycleUpdate = function (event, ...args) {
        const result = lifecycle.call(this, event, ...args);
        return event === 'client_exited' || event === 'client_unmounted'
          ? cleanup(result, 'trame.lifecycle.update') : result;
      };
    }
  });
})();
