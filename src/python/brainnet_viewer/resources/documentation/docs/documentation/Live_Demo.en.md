# Live Demo

[中文](Live_Demo.zh-CN.md) · [Manual](../manual/en/index.md)

After rendering a Scene, choose **Live Demo** in the Render Canvas toolbar. It continuously rotates the active camera by 5° per step, matching the historical Presentation behavior. Use **Stop Demo** to stop immediately and retain the current camera position; use Reset to restore the configured camera.

The demo is a non-blocking timer, not a busy loop. It stops automatically before rerendering, clearing the figure, changing a view control, or closing the app. Animation export is disabled while a demo runs, and a demo cannot start while animation export is active. Live Demo does not write files or modify Scene display settings; saving a Scene after stopping can retain the current camera through the normal session-state pathway.

The feature needs a rendered canvas. It is intentionally separate from **Rotate**, which enables manual mouse rotation, and **Export Animation...**, which creates a file rather than an interactive demonstration.

Live Demo is a presentation tool, not a performance benchmark.
