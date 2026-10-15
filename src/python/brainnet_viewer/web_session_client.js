/* SPDX-License-Identifier: GPL-3.0-or-later */
(() => {
  'use strict';
  let lastSent = -Infinity;
  let busy = false;
  let ended = false;
  let notice;
  function show(message, expired) {
    if (!notice) {
      notice = document.createElement('aside');
      notice.setAttribute('role', 'status');
      notice.style.cssText = 'position:fixed;top:4px;left:50%;transform:translateX(-50%);z-index:10000;max-width:92%;padding:10px;background:#fff7db;color:#172c50;border:1px solid #ad8425;border-radius:5px;font:14px Arial,sans-serif;';
      document.body.appendChild(notice);
    }
    notice.replaceChildren(document.createTextNode(message + ' '));
    const button = document.createElement('button');
    button.textContent = expired ? 'Sign in' : 'Keep session';
    button.addEventListener('click', () => {
      if (expired) window.location.assign('/_bnv/login');
      else activity(true);
    });
    notice.appendChild(button);
  }
  async function activity(force = false) {
    if (ended || busy || (!force && Date.now() - lastSent < 5000)) return;
    busy = true;
    try {
      const response = await fetch('/_bnv/activity', {method: 'POST', credentials: 'same-origin', cache: 'no-store'});
      if (response.ok) {
        lastSent = Date.now();
        if (notice) notice.remove();
        notice = undefined;
      }
    } catch (_) { /* Reconnect is handled by the application transport. */ }
    finally { busy = false; }
  }
  async function status() {
    if (ended) return;
    try {
      const response = await fetch('/_bnv/status', {credentials: 'same-origin', cache: 'no-store'});
      if (response.status === 401) {
        ended = true;
        show('This session has ended. Unsaved data is no longer available.', true);
      } else if (response.ok) {
        const value = await response.json();
        if (!value.busy && value.remaining <= value.warning) {
          show('Session inactive: it will end soon. Save your Scene or keep the session.', false);
        }
      }
    } catch (_) { /* Do not mistake a network error for confirmed expiration. */ }
  }
  function start() {
    for (const event of ['pointerdown', 'wheel', 'keydown', 'touchstart']) {
      document.addEventListener(event, () => activity(), {passive: true});
    }
    document.addEventListener('pointermove', (event) => { if (event.buttons) activity(); }, {passive: true});
    activity(true);
    setInterval(status, 5000);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start, {once: true});
  else start();
})();
