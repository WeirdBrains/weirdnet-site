# Handoff

Running log for [weirdnet-site](https://github.com/WeirdBrains/weirdnet-site) ([net.weirdbrains.com](https://net.weirdbrains.com)), newest first. Shared rules: the collective `AGENTS.md` and this repo's [AGENTS.md](AGENTS.md).

## 2026-11-22: per-request answer cache pages merged

What changed: merged `cache-mode` into main ([`d19eb0e`](https://github.com/WeirdBrains/weirdnet-site/commit/d19eb0ea87b0918a84df990cff3aa5db789cb798)) after [weirdnet-agent 0.5.1](https://crates.io/crates/weirdnet-agent/0.5.1), [weirdnet-semcache 0.2.1](https://crates.io/crates/weirdnet-semcache/0.2.1) and [weirdnet-openai 0.2.1](https://crates.io/crates/weirdnet-openai/0.2.1) were published and built on docs.rs ([agent](https://docs.rs/weirdnet-agent/0.5.1), [semcache](https://docs.rs/weirdnet-semcache/0.2.1), [openai](https://docs.rs/weirdnet-openai/0.2.1)).

Checks run: `python3 tool/check_crates.py --strict` (30 of 30), `dart analyze` (clean), `jaspr build` (ok).

Not tested: no example was rebuilt; the guide's snippets are prose only.

What's left and next: confirm the Pages deploy and the live pages; nothing else for these releases.

## 2026-11-22: per-request answer cache (branch `cache-mode`, not merged)

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, [`3fcf007`](https://github.com/WeirdBrains/weirdnet-site/commit/3fcf007678bf131c2c328f1d4cdac3f46c9edbc9)): the [weirdnet-agent](https://net.weirdbrains.com/crates/agent) page shows 0.5.1 with `CacheMode`, `Request::cache`, `Request::with_cache` and `Request::with_wait_for_model`, and its guide has an "Answer cache per request (0.5.1)" section. The [weirdnet-semcache](https://net.weirdbrains.com/crates/semcache) page shows 0.2.1 (`may_read`, `may_store`, `get_rev` / `put_rev`, `exact_key_rev`; the example uses the revision methods) with a "Bypass, refresh and revisions (0.2.1)" guide section. The [weirdnet-openai](https://net.weirdbrains.com/crates/openai) page shows 0.2.1 with the `cache` parameter and the `x-weirdnet-cache` request header.

Checks run: `dart analyze` (clean), `jaspr build` (ok), `python3 tool/check_crates.py` (30 of 30). `--strict` fails only because the three versions aren't on crates.io yet.

Not tested: no example was rebuilt; the guide's snippets are prose only.

What's left and next: merge to main only after weirdnet-agent 0.5.1, weirdnet-semcache 0.2.1 and weirdnet-openai 0.2.1 are on crates.io and docs.rs, then re-run `check_crates.py --strict` and check the live pages.

## 2026-11-22: weirdnet-device-link 0.3.3 additions

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, [`4ae6b7c`](https://github.com/WeirdBrains/weirdnet-site/commit/4ae6b7c9e9c437825ee33aee4c8ec0608fe54c41)): the [weirdnet-device-link](https://net.weirdbrains.com/crates/device-link) page lists the 0.3.3 additions and its guide has a "0.3.3" section ([docs.rs](https://docs.rs/weirdnet-device-link/0.3.3)): `offer_scheme`, `is_offer`, `known_relays`, `parse_relays`, `relays_from_env` and `link_node_config`. The page version stays 0.4.1, the newest release.

Checks run: `python3 tool/check_crates.py --strict` (30 of 30).

Not tested: no example was rebuilt; the guide's snippets are prose only.

Deployed: merged to main in `c5e79be` after weirdnet-device-link 0.3.3 was on [crates.io](https://crates.io/crates/weirdnet-device-link/0.3.3) and [docs.rs](https://docs.rs/weirdnet-device-link/0.3.3); the live page shows the 0.3.3 section and the home page still lists 30 crates.

What's left and next: nothing for this release.

## 2026-11-22: weirdnet-themes 0.2.0, weirdnet-mcp 0.6.1

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, `tool/examples/themes.rs`, `tool/examples/mcp.rs`, `tool/examples/examples.toml`, `lib/content/examples.dart`): the [weirdnet-themes](https://net.weirdbrains.com/crates/themes) page shows 0.2.0 ([docs.rs](https://docs.rs/weirdnet-themes/0.2.0), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-themes/blob/main/CHANGELOG.md)): the Bragi built-in, optional roles and their derived colours, NO_COLOR and `ColorDepth::None`, the terminal's own background in 16 colours, `UserDir` and the editor/switcher helpers, opt-in light/dark probes, and a "Moving to 0.2.0" section. The [weirdnet-mcp](https://net.weirdbrains.com/crates/mcp) page shows 0.6.1 ([docs.rs](https://docs.rs/weirdnet-mcp/0.6.1), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-mcp/blob/main/CHANGELOG.md)) with prompts and a "Moving to 0.6.1" section. Both examples were rewritten for the new APIs.

Checks run: `python3 tool/check_crates.py --strict`, `dart analyze`, `jaspr build`; the themes and mcp examples were built and run against the published crates.

Not tested: the other examples were not rebuilt.

What's left and next: nothing for these releases.

## 2026-11-21: weirdnet-mcp 0.6.0

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, `tool/examples/mcp.rs`, `tool/examples/examples.toml`, `lib/content/examples.dart`): the [weirdnet-mcp](https://net.weirdbrains.com/crates/mcp) page shows 0.6.0 ([docs.rs](https://docs.rs/weirdnet-mcp/0.6.0), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-mcp/blob/main/CHANGELOG.md)) with [MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28) support alongside the older protocol versions: `Tools::call_async`, object, enum, array and anyOf parameter schemas, resources, image and audio tool results, the `stdio-server` serve loop, and the `http-server`/`axum` route helper with bearer auth and Host/Origin checks. The guide has a "Serving it (0.6.0)" section and a "Moving to 0.6.0" migration section (`ParamType` is `#[non_exhaustive]`; `match` arms need a wildcard). The notes say 0.1.0 and 0.2.0 to 0.5.1 are yanked; 0.1.1 is live. The weirdnet-agent page no longer pins a weirdnet-mcp version in prose. The example now uses an enum parameter and a `call_async` image tool.

Checks run: `python3 tool/check_crates.py --strict` (30 of 30), `dart analyze`, `jaspr build`; the mcp example was built and run against weirdnet-mcp 0.6.0 from crates.io.

Not tested: the other examples were not rebuilt; the stdio and HTTP serving snippets in the guide are not compiled by the example harness.

What's left and next: nothing for this release.

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
