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
