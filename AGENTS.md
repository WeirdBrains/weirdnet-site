# AGENTS.md

The [WeirdBrains](https://weirdbrains.com) collective `AGENTS.md` applies to this repository. On top of it:

- This is the Weirdnet docs site (Jaspr, static mode). Content must come from the crates' own
  READMEs, SECURITY notes and source; mark anything not shipped as in progress.
- Before every commit: `dart analyze` clean and `jaspr build` succeeds.
- Every published `weirdnet*` crate has an entry in `lib/content/crates.dart` (CI checks with
  `tool/check_crates.py`). Guides in `lib/content/guides.dart` cover only what the sources
  document; leave out what they don't cover instead of guessing, and don't publish gaps,
  roadmap or "coming soon" lists (public-content rules, 2026-11-20). Usage examples live in `tool/examples/` and must
  build against the published crate; regenerate `lib/content/examples.dart` with
  `tool/gen_examples.py`.
- Changes go straight to `main`; the Pages workflow deploys `net.weirdbrains.com`.
