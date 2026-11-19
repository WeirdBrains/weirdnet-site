# AGENTS.md

The WeirdBrains collective `AGENTS.md` applies to this repository. On top of it:

- This is the Weirdnet docs site (Jaspr, static mode). Content must come from the crates' own
  READMEs, SECURITY notes and source; mark anything not shipped as in progress.
- Before every commit: `dart analyze` clean and `jaspr build` succeeds.
- Every published `weirdnet*` crate has an entry in `lib/content/crates.dart` (CI checks with
  `tool/check_crates.py`). A guide in `lib/content/guides.dart` lists in `todo` what the
  sources don't cover yet, instead of guessing. Usage examples live in `tool/examples/` and must
  build against the published crate; regenerate `lib/content/examples.dart` with
  `tool/gen_examples.py`.
- Changes go straight to `main`; the Pages workflow deploys `net.weirdbrains.com`.
