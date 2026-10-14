# Contributing

When reporting a problem, include the software version or commit, operating
system, runtime version, steps to reproduce it and the complete error message.
Provide a small example if you can share it safely. Report security issues
privately as described in [SECURITY.md](SECURITY.md).

Keep each contribution focused on one change. Preserve scientific coordinates,
values and provenance, and distinguish applied settings from pending edits.
Registration must be explicit; invalid or nonfinite values must not be replaced
silently. Submit formatting, dependency and resource changes separately from
functional fixes whenever possible.

Use an isolated environment with the project's pinned dependencies. Relevant tests are in
`tests/python`, `tests/security/check_local_server.py` and
`tests/matlab/runReviewNodeComments.m`. Report which tests you ran and distinguish
automated checks from interactive testing.

Retain GPL-3.0-or-later code identifiers and third-party notices. Submit only work
you have the right to license. Third-party data retain their own terms even when
distributed with GPL-licensed code.
