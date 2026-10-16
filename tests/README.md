# Small associated regression

Install the isolated Python project with its `web` extra, then run:

```text
python -m unittest discover -s tests/python -p test_review_core.py -v
```

The five synthetic fixtures are reused from the project's existing cross-platform
fixtures. They are index/numerical oracles, not anatomical data or real subjects.
The tests cover the changed node comments, Scene syntax/transaction/JSON limits,
XML entity refusal, existing geometry/network values and small upload/ZIP guards.
Symlink permission failures are reported as skips on restricted Windows; Linux
CI exercises that case. GUI, driver, scientific mapping and MATLAB tests are
separate associated checks, not inferred from this suite.

GitHub Actions runs the Python checks on Python 3.10 and 3.12, verifies wheel
payloads and performs a CPU-container HTTP/bootstrap check. These checks do not
replace graphical-desktop, hardware-driver or platform acceptance testing.

For remote-view lifetime changes, run `test_web_view_lifecycle.py`. It checks
native VTK objects and the class-level RPC registration used by wslink, including
late events after a view is retired, context reuse, layout changes, Clear,
failed-scene preparation and export recovery. `test_scalar_display_contract.py` checks
near-zero colors and statistical metadata. Neither suite requires user interaction.

`tests/security/check_server_load.py --subscribe --rounds 20 --memory-check` exercises image
subscriptions, delayed events when a view changes, repeated Apply and PNG export through
an installed multi-session HTTPS server. Supply its required URL, certificate,
password-file, container and output arguments. Keep load tests on isolated
instances, not on a service with active users. Inspect the per-worker RSS series
after warm-up; bounded allocator reuse is different from retaining another
render window on each Apply. The bounded check excludes five warm-up rounds and
requires each worker's RSS slope to stay at or below 2 MiB per round, with no more
than 64 MiB increase between the first and last five-round medians. Passing this
case is not a guarantee for arbitrary data sizes or indefinite server uptime.
