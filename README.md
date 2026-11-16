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
from each crate's README) and `lib/components/diagrams.dart` (inline SVG diagrams). Theme:
`web/styles.css`, after www.weirdbrains.com. The Weirdnet logo is `web/images/weirdnet-logo.svg`
(mark: `weirdnet-mark.svg`). Inter is self-hosted under the SIL Open Font License
(`web/fonts/LICENSE-Inter.txt`).

## Hosting

GitHub Pages with Source: GitHub Actions and the custom domain `net.weirdbrains.com`
(`web/CNAME`). DNS: a `CNAME` record `net` → `weirdbrains.github.io.`

## License

BSD-3-Clause.
