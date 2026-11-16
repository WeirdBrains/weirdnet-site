# AGENTS.md

The WeirdBrains collective `AGENTS.md` applies to this repository. On top of it:

- This is the Weirdnet docs site (Jaspr, static mode). Content must come from the crates' own
  READMEs, SECURITY notes and source; mark anything not shipped as in progress.
- Before every commit: `dart analyze` clean and `jaspr build` succeeds.
- Changes go straight to `main`; the Pages workflow deploys `net.weirdbrains.com`.
