# Handoff

Running log for [weirdnet-site](https://github.com/WeirdBrains/weirdnet-site) ([net.weirdbrains.com](https://net.weirdbrains.com)), newest first. Shared rules: the collective `AGENTS.md` and this repo's [AGENTS.md](AGENTS.md).

## 2026-11-21: weirdnet-model 0.5.1, weirdnet-alerts 0.2.0, weirdnet-backends 0.3.0

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`):

- [weirdnet-model](https://net.weirdbrains.com/crates/model) 0.5.1: Hub search and split GGUFs (`hf::Hub`), `fit`, `HfToken`, `download_parts`, listing and removing models; a "Find a model that fits (0.5.1)" guide section; the example takes `"0.5"`; the `agent` feature line lists every weirdnet-agent requirement.
- [weirdnet-backends](https://net.weirdbrains.com/crates/backends) 0.3.0: `/weirdnet-backends/models/1` and `Supervisor::add_model`/`remove_model`; the breaking change (weirdnet-model 0.5.1 required, 0.4 dropped) in the notes; a "Managing models (0.3.0)" guide section; the example takes `"0.3"`.
- [weirdnet-alerts](https://net.weirdbrains.com/crates/alerts) 0.2.0: the `backends` feature takes weirdnet-backends 0.2 or 0.3 (breaking for that feature), `engine.removed`; the example takes `"0.2"`. Dropped a not-yet-supported note (public pages list no gaps).

Content comes from each crate's README, CHANGELOG and source at its release tag.

Checks run: `dart analyze` (no issues); `python3 tool/check_crates.py --strict` (30 crates on crates.io, 30 on the site, no stale versions); `jaspr build --sitemap-domain https://net.weirdbrains.com`; the built pages link crates.io and docs.rs for the new versions.

Not tested: `tool/examples/examples.toml` has no entries for these three crates, so their examples are not compiled by the site.

What's left and next: nothing for these releases.
