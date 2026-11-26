# Handoff

Running log for [weirdnet-site](https://github.com/WeirdBrains/weirdnet-site) ([net.weirdbrains.com](https://net.weirdbrains.com)), newest first. Shared rules: the collective `AGENTS.md` and this repo's [AGENTS.md](AGENTS.md).

## 2026-11-26: weirdnet-sync 0.8.3 type-scoped keys for service devices

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`; the commit that adds this entry):

- [weirdnet-sync](https://net.weirdbrains.com/crates/sync) shows 0.8.3 ([crates.io](https://crates.io/crates/weirdnet-sync/0.8.3), [docs.rs](https://docs.rs/weirdnet-sync/0.8.3)): service devices hold type-scoped keys for their granted types only, leases come automatically with any sync type, and devices refuse a service peer's requests outside its grant. New guide section "Type-scoped keys for service devices (0.8.3)", a new parts line, and the service-link wording in the device-link guide.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (34 of 34), `jaspr build` (ok), `python3 tool/check_links.py` (39 pages, 0 errors) and `--external` (170 external URLs, 0 errors).

Not tested: the examples were not rebuilt (the sync example's `"0.8.2"` requirement already takes 0.8.3).

What's left and next: nothing for this release.

## 2026-11-26: weirdnet-backends 0.4.7 and weirdnet-net 0.8.3

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`; the commit that adds this entry):

- [weirdnet-backends](https://net.weirdbrains.com/crates/backends) shows 0.4.7 ([crates.io](https://crates.io/crates/weirdnet-backends/0.4.7), [docs.rs](https://docs.rs/weirdnet-backends/0.4.7)): the uploads switch (`WritePolicy::with_uploads`, refused as `not-allowed` while pulls and removals keep working) and `StoredEntry` constructors and `StoredEntry::list`, in the notes, features and guide.
- [weirdnet-net](https://net.weirdbrains.com/crates/net) shows 0.8.3 ([crates.io](https://crates.io/crates/weirdnet-net/0.8.3), [docs.rs](https://docs.rs/weirdnet-net/0.8.3)): ended streams stop counting against `Limits::max_streams` right away; noted in the notes and the streams guide. The examples keep `"0.8.2"`, which takes 0.8.3.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (34 of 34), `jaspr build` (ok), `python3 tool/check_links.py` (39 pages, 0 errors) and `--external` (169 external URLs, 0 errors).

The first Pages run for [`656e3df`](https://github.com/WeirdBrains/weirdnet-site/commit/656e3dfc30d252032c0cd37fe5d5079cd7600e3e) failed at the crates.io page check on the runner while the same check passes locally (34 of 34), so the commit that adds this note runs the deploy again.

Not tested: the examples were not rebuilt (unchanged).

What's left and next: nothing for these releases.

## 2026-11-26: weirdnet-agent 0.5.6 jobs guide; weirdnet-sync 0.8.1 and 0.8.2

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, `lib/content/examples.dart`, `tool/examples/examples.toml`; the commit that adds this entry):

- [weirdnet-agent](https://net.weirdbrains.com/crates/agent) shows 0.5.6 ([crates.io](https://crates.io/crates/weirdnet-agent/0.5.6), [docs.rs](https://docs.rs/weirdnet-agent/0.5.6)) with a "Synced jobs" guide section (open and post, voters, claim, checkpoints and fencing, finish, fail and pause, policy defaults) and the `jobs` feature in the feature list.
- [weirdnet-sync](https://net.weirdbrains.com/crates/sync) guide covers job rules, pausing and notes (0.8.1) and the 0.8.2 owner-pause fix, with notes on moving to 0.8.1; its example uses 0.8.2.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (34 of 34), `jaspr build` (ok), `python3 tool/check_links.py` (39 pages, 0 errors) and `--external` (168 external URLs), the sync example built and run against the published 0.8.2.

Not tested: the jobs guide has no runnable example; it is prose from the crate's docs and tests.

What's left and next: nothing for this release.

## 2026-11-25: weirdnet-storage 0.1.2 page, guide and example

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, `tool/examples/storage.rs`, `tool/examples/examples.toml`, `lib/content/examples.dart`, [`6823bdb`](https://github.com/WeirdBrains/weirdnet-site/commit/6823bdb), merged into main with `git merge --no-ff`):

- The [weirdnet-storage](https://net.weirdbrains.com/crates/storage) page is at 0.1.2 ([crates.io](https://crates.io/crates/weirdnet-storage/0.1.2), [docs.rs](https://docs.rs/weirdnet-storage/0.1.2), tag [v0.1.2](https://github.com/WeirdBrains/weirdnet-storage/releases/tag/v0.1.2)) and lists the `replicate`, `replicate::service` and `retention` parts with a note on asynchronous replication and what retention can and can't stop.
- The guide adds "Replication and failover" (log, hot standby, fencing, failover with `Manual` or a weirdnet-sync lease, fail-back, standbys over weirdnet-service and weirdnet-net) and "Retention" (policies, seals, purge and archive, guard), and the four new features.
- The example now keeps a hot standby current and protects invoices for seven years, with `replication` and `retention` enabled.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (34 of 34), `jaspr build` (ok), `python3 tool/check_links.py` (39 pages, 0 errors) and `--external` (166 external URLs, 0 errors). The example was built and run from the generated harness against weirdnet-storage 0.1.2 from crates.io.

Not tested: the other examples in the harness were not rebuilt (unchanged).

What's left and next: nothing for this release.

## 2026-11-25: weirdnet-chart 0.1.0 guide

What changed (`lib/content/guides.dart`, `lib/content/crates.dart`, [`c95a327`](https://github.com/WeirdBrains/weirdnet-site/commit/c95a3279d7d2177a26923cebdd1b1d3670e0ade6), merged into main with `git merge --no-ff`):

- The [weirdnet-chart](https://net.weirdbrains.com/crates/chart) guide for 0.1.0 ([crates.io](https://crates.io/crates/weirdnet-chart/0.1.0), [docs.rs](https://docs.rs/weirdnet-chart/0.1.0), tag [v0.1.0](https://github.com/WeirdBrains/weirdnet-chart/releases/tag/v0.1.0)) now covers the `Series` ring buffer and `apply_trade` candles, panes and marks (`Line`, `Area`, `Bars`, `Candles`, `Ohlc`, `Volume`), the `Viewport` and following the newest data, `Chart::layout` to a `Scene`, `FrameThrottle`, the `ratatui` feature (braille `ChartWidget`, ratatui 0.30) and the `gpui` feature (`ChartView`, gpui 0.2.2 from crates.io, the `libc` 0.2.189 pin). The page lists the marks and links the tag.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (34 of 34), `jaspr build` (ok), `python3 tool/check_links.py` (39 pages, 0 errors) and `--external` (166 external URLs, 0 errors).

Not tested: the page has no example yet; the guide is prose only.

What's left and next: nothing for this release.

## 2026-11-25: weirdnet-accounts 0.2.0 page; weirdnet-chart and weirdnet-exchange pages

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, [`ae06556`](https://github.com/WeirdBrains/weirdnet-site/commit/ae065563efc10e265e6aa9a245ea7252a0d04b48), merged into main with `git merge --no-ff`):

- [weirdnet-accounts](https://net.weirdbrains.com/crates/accounts) shows 0.2.0 ([crates.io](https://crates.io/crates/weirdnet-accounts/0.2.0), [docs.rs](https://docs.rs/weirdnet-accounts/0.2.0), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-accounts/blob/main/CHANGELOG.md)), with a new guide: accounts, the role catalog, the `Authorizer`, the `Accounts` directory, invitations, API keys, storage, signed memberships and `ServiceAuth`, the 0.1 primitives, and the `sqlite`, `vendored-openssl`, `net` and `service` features.
- New [weirdnet-chart](https://net.weirdbrains.com/crates/chart) and [weirdnet-exchange](https://net.weirdbrains.com/crates/exchange) pages with 0.1.0 and guides from their READMEs. Both were published while this update was in progress, and without entries `tool/check_crates.py` would have failed the Pages build.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (34 of 34), `jaspr build` (ok), `python3 tool/check_links.py` (39 pages, 0 errors) and `--external` (165 external URLs, 0 errors).

Not tested: none of the three pages has an example yet; the guides are prose only.

What's left and next: nothing for these releases.

## 2026-11-25: weirdnet-backends 0.4.6, weirdnet-service 0.1.0 page; Pages deploy fixed

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, [`9f7380b`](https://github.com/WeirdBrains/weirdnet-site/commit/9f7380b34df18c3c6c273dcb5e49ae31888717ee)):

- [weirdnet-backends](https://net.weirdbrains.com/crates/backends) shows 0.4.6 ([crates.io](https://crates.io/crates/weirdnet-backends/0.4.6), [docs.rs](https://docs.rs/weirdnet-backends/0.4.6), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-backends/blob/main/CHANGELOG.md)): the `node` feature accepts weirdnet-sync 0.8 and needs weirdnet-agent 0.5.5; no API change. The backends and agent guides say weirdnet-sync 0.8 is supported.
- New [weirdnet-service](https://net.weirdbrains.com/crates/service) page in "Network" with 0.1.0 ([crates.io](https://crates.io/crates/weirdnet-service/0.1.0), [docs.rs](https://docs.rs/weirdnet-service/0.1.0)) and a guide from its README. It was published while the vault page was going out, and without an entry `tool/check_crates.py` failed the Pages build for the previous push (`32bdf50`), so that push didn't deploy.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (32 of 32), `jaspr build` (ok), `python3 tool/check_links.py` (37 pages, 0 errors) and `--external` (151 external URLs, 0 errors).

Not tested: weirdnet-service has no example on its page yet; the guide is prose only.

What's left and next: nothing for these releases.

## 2026-11-25: weirdnet-vault 0.1.0 page, weirdnet-agent 0.5.5

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, `tool/examples/vault.rs`, `tool/examples/examples.toml`, `lib/content/examples.dart`, [`e6b50c7`](https://github.com/WeirdBrains/weirdnet-site/commit/e6b50c7), merged into main with `git merge --no-ff`):

- New [weirdnet-vault](https://net.weirdbrains.com/crates/vault) page in "Keys and storage" with 0.1.0 ([crates.io](https://crates.io/crates/weirdnet-vault/0.1.0), [docs.rs](https://docs.rs/weirdnet-vault/0.1.0), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-vault/blob/main/CHANGELOG.md)), a guide (keys and sealing, the checks on every call, using and retrieving, rotation, the audit log, backups, features) and an example: a bot uses a credential without seeing it, a dry-run caller and an unapproved identity are refused, an approved operator retrieves it, and the audit log is verified.
- [weirdnet-agent](https://net.weirdbrains.com/crates/agent) shows 0.5.5 ([crates.io](https://crates.io/crates/weirdnet-agent/0.5.5), [docs.rs](https://docs.rs/weirdnet-agent/0.5.5)): the `pool` and `serve` features accept weirdnet-sync 0.8; no API change.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (31 of 31), `jaspr build` (ok), `python3 tool/check_links.py` (36 pages, 0 errors) and `--external` (146 external URLs, 0 errors). The vault example was built and run from the `tool/gen_examples.py` harness, outside the repository, against weirdnet-vault 0.1.0 from crates.io.

Not tested: the other examples weren't rebuilt.

What's left and next: nothing for these releases.

## 2026-11-25: weirdnet-agent 0.5.4, weirdnet-backends 0.4.5, weirdnet-openai 0.2.3 pages

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, [`98ba0e1`](https://github.com/WeirdBrains/weirdnet-site/commit/98ba0e1c063e90fe99e3cd53f57f71ebcfb1cd8c), merged into main with `git merge --no-ff`):

- [weirdnet-agent](https://net.weirdbrains.com/crates/agent) shows 0.5.4 ([crates.io](https://crates.io/crates/weirdnet-agent/0.5.4), [docs.rs](https://docs.rs/weirdnet-agent/0.5.4), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-agent/blob/main/CHANGELOG.md)): 0.5.3's `remote::pool_model::PoolModel` (a pool as one `ModelBackend`, with resume, rerouting and a local fallback), `PoolWatch`, `PoolStatus`, `CatalogNodes`, `ModelError::PoolUnreachable` and `ModelNotice`, and 0.5.4's `CatalogModel::origin` and `license` with the `ORIGIN_*` names. New guide sections "A pool as one model (0.5.3)" and "Origin and license (0.5.4)".
- [weirdnet-backends](https://net.weirdbrains.com/crates/backends) shows 0.4.5 ([crates.io](https://crates.io/crates/weirdnet-backends/0.4.5), [docs.rs](https://docs.rs/weirdnet-backends/0.4.5), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-backends/blob/main/CHANGELOG.md)): `ModelsService::on_placed`, `Placed`, `PlacedVia`, `with_node_info`, `ModelEntry::origin` and `license` and `NodeService::set_model_origin`, with a "Placement hooks, origin and license (0.4.5)" guide section.
- [weirdnet-openai](https://net.weirdbrains.com/crates/openai) shows 0.2.3 ([crates.io](https://crates.io/crates/weirdnet-openai/0.2.3), [docs.rs](https://docs.rs/weirdnet-openai/0.2.3), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-openai/blob/main/CHANGELOG.md)): `weirdnet.origin` and `weirdnet.license` in `/v1/models`.
- No other weirdnet crate on crates.io was ahead of the site.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (30 of 30), `jaspr build` (ok), `python3 tool/check_links.py` (35 pages, 0 errors) and `--external` (142 external URLs, 0 errors).

Not tested: no example was rebuilt; the new guide text is prose only.

What's left and next: nothing for these releases.

## 2026-11-24: weirdnet-model 0.5.3 and weirdnet-backends 0.4.4 pages

What changed ([`6a679d2`](https://github.com/WeirdBrains/weirdnet-site/commit/6a679d24d84f8ae6f5d9e22dadc0b9bbbb43f476), merged into main with `git merge --no-ff`):

- [weirdnet-model](https://net.weirdbrains.com/crates/model) shows 0.5.3 ([crates.io](https://crates.io/crates/weirdnet-model/0.5.3), [docs.rs](https://docs.rs/weirdnet-model/0.5.3), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-model/blob/main/CHANGELOG.md)): `artifact::inspect` and `Artifact`, `Provenance`, `ModelStore::import` and its variants with the safetensors, MLX and projector layouts, `GgufKind::Projector`, `free_bytes`, `disk_space` and `bytes_by_origin`, with an "Import local files (0.5.3)" guide section.
- [weirdnet-backends](https://net.weirdbrains.com/crates/backends) shows 0.4.4 ([crates.io](https://crates.io/crates/weirdnet-backends/0.4.4), [docs.rs](https://docs.rs/weirdnet-backends/0.4.4), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-backends/blob/main/CHANGELOG.md)): models/1 uploads in resumable 48 KiB chunks, `Fetch`, `Pull::from_peer` and `ModelsClient::replicate`, `WritePolicy` (write authorizer, `max_upload`, `quota`, `KeepFree`), the `Disk` report, provenance in `List`, stable refusal reasons, `ModelLaunch::with_mmproj` and `Supervisor::set_projector_live`, with "Uploads and copies (0.4.4)" and "Projectors (0.4.4)" guide sections.
- The agent example depends on weirdnet-agent 0.5.2 instead of 0.5.0.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (30 of 30), `jaspr build` (ok), `python3 tool/check_links.py` (35 pages, 0 errors) and `--external` (141 external URLs, 0 errors). The agent example was built and run from the `tool/gen_examples.py` harness, outside the repository, against weirdnet-agent 0.5.2.

Not tested: the other examples weren't rebuilt; the model and backends snippets are prose only.

What's left and next: nothing for these releases.

## 2026-11-24: agent 0.5.2, alerts 0.2.2, device-link 0.4.2, openai 0.2.2 pages; link check in CI

What changed ([`0376b80`](https://github.com/WeirdBrains/weirdnet-site/commit/0376b807bf5fe203121587e3778b1e9d90d39f18), merged into main with `git merge --no-ff`):

- [weirdnet-agent](https://net.weirdbrains.com/crates/agent) shows 0.5.2 ([crates.io](https://crates.io/crates/weirdnet-agent/0.5.2), [docs.rs](https://docs.rs/weirdnet-agent/0.5.2), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-agent/blob/main/CHANGELOG.md)): `Request::adapter_scale` / `with_adapter_scale` and `CatalogModel::base` / `with_base` / `is_adapter`, with a "LoRA adapters (0.5.2)" guide section.
- [weirdnet-alerts](https://net.weirdbrains.com/crates/alerts) shows 0.2.2 ([crates.io](https://crates.io/crates/weirdnet-alerts/0.2.2), [docs.rs](https://docs.rs/weirdnet-alerts/0.2.2), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-alerts/blob/main/CHANGELOG.md)): the `backends` feature takes weirdnet-backends 0.2 to 0.4. The notes said 0.2.0 while the page showed 0.2.1; they now cover 0.2.1 and 0.2.2.
- [weirdnet-device-link](https://net.weirdbrains.com/crates/device-link) shows 0.4.2 ([crates.io](https://crates.io/crates/weirdnet-device-link/0.4.2), [docs.rs](https://docs.rs/weirdnet-device-link/0.4.2), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-device-link/blob/main/CHANGELOG.md)): the 0.3.3 additions on the 0.4 line. The example uses the documentation address `192.0.2.5` instead of a private one and depends on 0.4.2.
- [weirdnet-openai](https://net.weirdbrains.com/crates/openai) shows 0.2.2 ([crates.io](https://crates.io/crates/weirdnet-openai/0.2.2), [docs.rs](https://docs.rs/weirdnet-openai/0.2.2), [CHANGELOG](https://github.com/WeirdBrains/weirdnet-openai/blob/main/CHANGELOG.md)): `"adapter_scale"` and `weirdnet.base` in `/v1/models`.
- The [weirdnet-backends](https://net.weirdbrains.com/crates/backends) notes link their weirdnet-agent 0.5.2 mentions to the agent page.
- New [`tool/check_links.py`](tool/check_links.py): internal links and fragments resolve, no bare-text URLs, every page links to [weirdbrains.com](https://weirdbrains.com); `--external` fetches external URLs with a browser-like User-Agent. The [Pages workflow](.github/workflows/pages.yml) runs it after the build; [README.md](README.md) and [AGENTS.md](AGENTS.md) document it.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py --strict` (30 of 30, no mismatches), `jaspr build` (ok), `python3 tool/check_links.py` (35 pages, 0 errors) and `--external` (141 external URLs, 0 errors, 0 warnings). The checker was also run on a copy of the build with a broken link, a missing fragment, a bare URL and a missing footer link, and it reported all four. The device-link example was built and run from the `tool/gen_examples.py` harness, outside the repository, against weirdnet-device-link 0.4.2.

Not tested: the other examples weren't rebuilt.

What's left and next: nothing for these releases.

## 2026-11-24: weirdnet-model 0.5.2 and weirdnet-backends 0.4.3 pages

What changed (`lib/content/crates.dart`, `lib/content/guides.dart`, [`9d7d3bb`](https://github.com/WeirdBrains/weirdnet-site/commit/9d7d3bbfecee54238c2838eb8edf71491c568f9a), merged into main with `git merge --no-ff`): the [weirdnet-model](https://net.weirdbrains.com/crates/model) page shows 0.5.2 ([crates.io](https://crates.io/crates/weirdnet-model/0.5.2), [docs.rs](https://docs.rs/weirdnet-model/0.5.2)) with LoRA adapter files (`gguf::read_header`, `GgufKind`, `Hub::adapters`, `download_adapter`, `StoredAdapter`) and a "LoRA adapters (0.5.2)" guide section. The [weirdnet-backends](https://net.weirdbrains.com/crates/backends) page shows 0.4.3 ([crates.io](https://crates.io/crates/weirdnet-backends/0.4.3), [docs.rs](https://docs.rs/weirdnet-backends/0.4.3)) with notes for 0.4.0 to 0.4.3, including the 0.4.0 breaking changes, and guide sections for LoRA adapters (`LoraAdapter`, `openai::Target`, `Supervisor::add_adapter`, `AdapterChange`, `ModelStatus::base`), live adapters and per-request scale (0.4.1), engine readiness (0.4.2) and node reservations (0.4.3). Its example depends on `"0.4"` and adds an adapter.

Checks run: `dart analyze` (clean), `python3 tool/check_crates.py` (30 of 30; `--strict` fails only on weirdnet-agent, weirdnet-alerts, weirdnet-device-link and weirdnet-openai, whose newer releases aren't on the site yet), `jaspr build` (ok), and a link check of the built site: no broken internal links, every page links to [weirdbrains.com](https://weirdbrains.com), and the crates.io and docs.rs links for these versions answer.

Not tested: no example was rebuilt; the guide's snippets are prose only.

What's left and next: pages for weirdnet-agent 0.5.2, weirdnet-alerts 0.2.2, weirdnet-device-link 0.4.2 and weirdnet-openai 0.2.2.

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
