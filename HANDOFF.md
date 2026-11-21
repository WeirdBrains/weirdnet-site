# Handoff

Running log for [weirdnet-site](https://github.com/WeirdBrains/weirdnet-site) ([net.weirdbrains.com](https://net.weirdbrains.com)), newest first. Shared rules: the collective `AGENTS.md` and this repo's [AGENTS.md](AGENTS.md).

## 2026-11-21: weirdnet-plugin 0.1.1, weirdnet-code-spaces 0.1.2

What changed (`lib/content/crates.dart`, `tool/examples/examples.toml`, `lib/content/examples.dart`): the [weirdnet-plugin](https://net.weirdbrains.com/crates/plugin) page shows 0.1.1 (SDK version 0.1.1) and the [weirdnet-code-spaces](https://net.weirdbrains.com/crates/code-spaces) page shows 0.1.2, which bundles that SDK. weirdnet-plugin 0.1.0 is yanked.

Checks run: `python3 tool/check_crates.py --strict`, `dart analyze`, `jaspr build`.

Not tested: the two examples were not rebuilt.

What's left and next: nothing for these releases.

## 2026-11-21: republished crate versions

What changed (`lib/content/crates.dart`, `tool/examples/examples.toml`, `lib/content/examples.dart`): every crate page shows the newest version on [crates.io](https://crates.io/search?q=weirdnet) after the public-content patch releases: weirdnet-net 0.8.2, weirdnet-relay 0.6.1, weirdnet-keys 0.1.2, weirdnet-storage 0.1.1, weirdnet-update 0.2.2, weirdnet-accounts 0.1.1, weirdnet-alerts 0.2.1, weirdnet-code-spaces 0.1.1, weirdnet-pipelines 0.1.1, weirdnet-rules 0.1.1, weirdnet-render 0.1.1, weirdnet-themes 0.1.1, weirdnet-text 0.1.1, weirdnet-push 0.1.1, weirdnet-device-link 0.4.1, weirdnet-access 0.1.2, weirdnet-schemes 0.1.1, weirdnetctl 0.1.1 and weirdnet-ext, weirdnet-ext-proto and weirdnet-ext-sdk 0.1.1. These releases change package metadata and docs only, so no guide text changed. Earlier versions are yanked.

Checks run: `python3 tool/check_crates.py --strict`, `dart analyze`, `jaspr build`; the weirdnet-keys example was built against 0.1.2.

Not tested: the other examples were not rebuilt; the new versions change package metadata and docs only.

What's left and next: nothing for these releases.

## 2026-11-21: weirdnet-model 0.5.1, weirdnet-alerts 0.2.0, weirdnet-backends 0.3.0

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`):

- [weirdnet-model](https://net.weirdbrains.com/crates/model) 0.5.1: Hub search and split GGUFs (`hf::Hub`), `fit`, `HfToken`, `download_parts`, listing and removing models; a "Find a model that fits (0.5.1)" guide section; the example takes `"0.5"`; the `agent` feature line lists every weirdnet-agent requirement.
- [weirdnet-backends](https://net.weirdbrains.com/crates/backends) 0.3.0: `/weirdnet-backends/models/1` and `Supervisor::add_model`/`remove_model`; the breaking change (weirdnet-model 0.5.1 required, 0.4 dropped) in the notes; a "Managing models (0.3.0)" guide section; the example takes `"0.3"`.
- [weirdnet-alerts](https://net.weirdbrains.com/crates/alerts) 0.2.0: the `backends` feature takes weirdnet-backends 0.2 or 0.3 (breaking for that feature), `engine.removed`; the example takes `"0.2"`. Dropped a not-yet-supported note (public pages list no gaps).

Content comes from each crate's README, CHANGELOG and source at its release tag.

Checks run: `dart analyze` (no issues); `python3 tool/check_crates.py --strict` (30 crates on crates.io, 30 on the site, no stale versions); `jaspr build --sitemap-domain https://net.weirdbrains.com`; the built pages link crates.io and docs.rs for the new versions.

Not tested: `tool/examples/examples.toml` has no entries for these three crates, so their examples are not compiled by the site.

What's left and next: nothing for these releases.
