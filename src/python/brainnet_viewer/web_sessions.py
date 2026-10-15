# SPDX-License-Identifier: GPL-3.0-or-later
"""Owned subprocesses for browser sessions; no rendering in the gateway."""
import asyncio
from collections import deque
from dataclasses import dataclass, field
import logging
import os
from pathlib import Path
import secrets
import signal
import socket
import sys
from tempfile import TemporaryDirectory
import time

from aiohttp import ClientError, ClientTimeout

LOG = logging.getLogger(__name__)


@dataclass
class BrowserSession:
    key: str = field(repr=False)
    touched: float = field(default_factory=time.monotonic)
    activity: float = field(default_factory=time.monotonic)
    busy_until: float = 0
    audit_id: str = field(default_factory=lambda: secrets.token_hex(6))
    task: object = None
    worker: object = None
    requests: int = 0
    sockets: set = field(default_factory=set)
    upstreams: set = field(default_factory=set)
    closed: bool = False


class Worker:
    def __init__(self, process, directory, port, token):
        self.process, self.directory, self.port = process, directory, port
        self.token = token
        self.log = deque(maxlen=32)
        self.drainer = asyncio.create_task(self._drain())
        self.closed = False

    @property
    def origin(self):
        return f'http://127.0.0.1:{self.port}'

    async def _drain(self):
        # Consume stdout continuously but keep only a bounded diagnostic tail.
        while chunk := await self.process.stdout.read(2048):
            self.log.append(chunk)

    async def close(self):
        if self.closed:
            return
        self.closed = True
        try:
            if self.process.returncode is None:
                if sys.platform == 'linux':
                    os.killpg(self.process.pid, signal.SIGTERM)
                else:
                    self.process.terminate()
                try:
                    await asyncio.wait_for(self.process.wait(), 5)
                except asyncio.TimeoutError:
                    if sys.platform == 'linux':
                        os.killpg(self.process.pid, signal.SIGKILL)
                    else:
                        self.process.kill()
                    await self.process.wait()
            elif sys.platform == 'linux':
                # A crashed worker can leave a native probe in its process group.
                try:
                    os.killpg(self.process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
        except ProcessLookupError:
            await self.process.wait()
        finally:
            self.drainer.cancel()
            await asyncio.gather(self.drainer, return_exceptions=True)
            self.directory.cleanup()


class ProcessLauncher:
    """Launch only the installed application, never a browser-supplied command."""
    def __init__(self, threads=2, scratch=None):
        self.threads, self.scratch = threads, scratch

    def command(self, port):
        return [sys.executable, '-m', 'brainnet_viewer.web_app',
                '--host', '127.0.0.1', '--port', str(port), '--container']

    async def start(self):
        directory = TemporaryDirectory(prefix='bnv-session-', dir=self.scratch)
        try:
            with socket.socket() as reservation:
                reservation.bind(('127.0.0.1', 0))
                port = reservation.getsockname()[1]
            token = secrets.token_urlsafe(32)
            env = dict(os.environ)
            for name in ('TMPDIR', 'TMP', 'TEMP'):
                env[name] = directory.name
            env.update(BNV_GATEWAY_TOKEN=token,
                       MPLCONFIGDIR=str(Path(directory.name) / 'matplotlib'),
                       XDG_CACHE_HOME=str(Path(directory.name) / 'cache'),
                       PYVISTA_OFF_SCREEN='true')
            for name in ('OMP_NUM_THREADS', 'OPENBLAS_NUM_THREADS', 'MKL_NUM_THREADS',
                         'NUMEXPR_NUM_THREADS', 'VTK_SMP_MAX_THREADS', 'LP_NUM_THREADS'):
                env[name] = str(self.threads)
            env.pop('BNV_WEB_BOOTSTRAPPED', None)
            spawning = asyncio.create_task(asyncio.create_subprocess_exec(
                *self.command(port),
                env=env, cwd=directory.name, stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT, start_new_session=sys.platform == 'linux'))
            try:
                process = await asyncio.shield(spawning)
            except asyncio.CancelledError:
                # Reap even a process created during cancellation of its first request.
                process = await spawning
                await Worker(process, directory, port, token).close()
                raise
            return Worker(process, directory, port, token)
        except BaseException:
            directory.cleanup()
            raise


class SessionPool:
    def __init__(self, client, *, maximum=4, idle_seconds=1800,
                 startup_seconds=90, launcher=None):
        self.client = client
        self.maximum, self.idle_seconds = maximum, idle_seconds
        self.startup_seconds = startup_seconds
        self.launcher = launcher or ProcessLauncher()
        self.sessions = {}
        self.closing = False

    def allocate(self):
        if self.closing or len(self.sessions) >= self.maximum:
            raise RuntimeError('All browser sessions are in use. Please try again later.')
        item = BrowserSession(secrets.token_urlsafe(32))
        self.sessions[item.key] = item
        LOG.info('session created audit=%s', item.audit_id)
        return item

    def find(self, key):
        item = self.sessions.get(key)
        return item if item and not item.closed else None

    async def _launch(self, item):
        worker = await self.launcher.start()
        item.worker = worker
        try:
            deadline = time.monotonic() + self.startup_seconds
            while time.monotonic() < deadline:
                if worker.process.returncode is not None:
                    raise RuntimeError('The browser worker stopped during startup.')
                try:
                    async with self.client.get(
                        worker.origin + '/index.html',
                        headers={'X-BNV-Worker-Token': worker.token},
                        timeout=ClientTimeout(total=2)) as response:
                        if response.status == 200:
                            # The token also proves the ephemeral port belongs to us.
                            return worker
                except (ClientError, asyncio.TimeoutError):
                    pass
                await asyncio.sleep(.2)
            raise RuntimeError('The browser worker did not become ready in time.')
        except BaseException:
            await worker.close()
            raise

    async def ready(self, item):
        if item.closed:
            raise RuntimeError('This browser session has ended. Sign in again.')
        if item.task is None:
            item.task = asyncio.create_task(self._launch(item))
        try:
            # One cancelled HTTP request must not cancel another request's startup.
            # The pool owns, cancels and awaits this task during every cleanup path.
            worker = await asyncio.shield(item.task)
            if item.closed or worker.process.returncode is not None:
                raise RuntimeError('This browser session has ended. Sign in again.')
            return worker
        except asyncio.CancelledError:
            raise
        except Exception:
            await self.remove(item, reason='startup-failed')
            raise

    async def remove(self, item, *, reason='signout'):
        if item.closed:
            return
        item.closed = True
        # Retain the slot until the old process is gone, including failed startup.
        try:
            await asyncio.gather(*(ws.close(code=1001, message=b'Idle session ended' if reason == 'idle' else b'Session ended')
                                   for ws in tuple(item.upstreams)),
                                 return_exceptions=True)
            await asyncio.gather(*(ws.close(code=1001, message=b'Session ended')
                                   for ws in tuple(item.sockets)), return_exceptions=True)
            if item.task is not None:
                if not item.task.done():
                    item.task.cancel()
                await asyncio.gather(item.task, return_exceptions=True)
            if item.worker is not None:
                await item.worker.close()
        finally:
            self.sessions.pop(item.key, None)
            LOG.info('session ended audit=%s reason=%s', item.audit_id, reason)

    async def reap(self, now=None):
        now = time.monotonic() if now is None else now
        for item in tuple(self.sessions.values()):
            dead = item.worker is not None and item.worker.process.returncode is not None
            starting = item.task is not None and not item.task.done()
            idle = (not starting and not item.requests and now >= item.busy_until
                    and now - item.activity >= self.idle_seconds)
            if dead or idle:
                await self.remove(item, reason='crashed' if dead else 'idle')

    async def close(self):
        self.closing = True
        await asyncio.gather(*(self.remove(item, reason='shutdown') for item in tuple(self.sessions.values())))
