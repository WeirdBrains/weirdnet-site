# weirdnet-site

The Weirdnet docs site, [net.weirdbrains.com](https://net.weirdbrains.com): what Weirdnet is,
how the network works, a page per crate, running a relay, and Morph. Built with
[Jaspr](https://jaspr.site) in static mode and deployed to GitHub Pages by
`.github/workflows/pages.yml` on every push to `main`.

## Develop

Dart 3.14 and the Jaspr CLI:

```sh
dart pub global activate jaspr_cli 0.24.0-beta.1
dart pub get
jaspr serve            # http://localhost:8080
```

## Build

```sh
jaspr build --sitemap-domain https://net.weirdbrains.com
python3 -m http.server 8080 --directory build/jaspr
```

Content lives in `lib/pages/` (page prose), `lib/content/crates.dart` (one entry per crate,
from each crate's README), `lib/content/guides.dart` (each crate page's guide: what it brings,
how it works, feature flags), `lib/content/examples.dart` and
`lib/components/diagrams.dart` (inline SVG diagrams). Theme:
`web/styles.css`, after www.weirdbrains.com. The Weirdnet logo is `web/images/weirdnet-logo.svg`
(mark: `weirdnet-mark.svg`). Inter is self-hosted under the SIL Open Font License
(`web/fonts/LICENSE-Inter.txt`).

### Crate examples

Each crate page's usage example is a real program in `tool/examples/<slug>.rs`, with its
dependencies in `tool/examples/examples.toml`. `lib/content/examples.dart` is generated from them:

```sh
python3 tool/gen_examples.py                      # rewrite lib/content/examples.dart
python3 tool/gen_examples.py --harness /tmp/ex    # also one cargo package per example
sh /tmp/ex/check.sh                               # build them all, run the runnable ones
```

Build the harness in a scratch directory outside the repository, never inside it. Every
example builds against the published crates.

### Crate coverage

`tool/check_crates.py` asks crates.io for every `weirdnet*` crate and fails if a published one
has no entry in `lib/content/crates.dart` (a version that differs is a warning; `--strict`
fails on it). The Pages workflow runs it on every push.

## Hosting

GitHub Pages with Source: GitHub Actions and the custom domain `net.weirdbrains.com`
(`web/CNAME`). DNS: a `CNAME` record `net` → `weirdbrains.github.io.`

## License

BSD-3-Clause.
