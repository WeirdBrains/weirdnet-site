import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../site.dart';

const _nav = [
  ('/network', 'How it works'),
  ('/crates', 'The pieces'),
  ('/relay', 'Run a relay'),
  ('/morph', 'Morph'),
];

/// Header, main and footer around a page.
class Layout extends StatelessComponent {
  const Layout({required this.active, required this.child, super.key});

  final String active;
  final Component child;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      a(href: '#content', classes: 'skip-link', [Component.text('Skip to content')]),
      header(classes: 'site-header', [
        div(classes: 'header-inner wrap', [
          a(href: '/', classes: 'logo', [img(src: '/images/weirdnet-logo.svg', alt: siteTitle)]),
          nav(classes: 'site-nav', [
            for (final (href, label) in _nav)
              a(href: href, classes: active == href ? 'active' : null, [Component.text(label)]),
            a(
              href: orgUrl,
              target: Target.blank,
              attributes: {'rel': 'noopener noreferrer'},
              [Component.text('GitHub')],
            ),
          ]),
        ]),
      ]),
      Component.element(tag: 'main', id: 'content', children: [child]),
      footer(classes: 'site-footer', [
        div(classes: 'footer-inner wrap', [
          p([
            Component.text('Weirdnet is a '),
            a(href: mainSiteUrl, [Component.text('Weird Brains')]),
            Component.text(' project. Crates are BSD-3-Clause.'),
          ]),
          div(classes: 'footer-links', [
            a(href: orgUrl, [Component.text('GitHub')]),
            a(href: 'https://crates.io/search?q=weirdnet', [Component.text('crates.io')]),
            a(href: morphSiteUrl, [Component.text('Morph')]),
            a(href: mainSiteUrl, [Component.text('weirdbrains.com')]),
          ]),
        ]),
      ]),
    ]);
  }
}

/// A page title block.
Component pageHero({required String eyebrow, required String title, required String lede}) {
  return section(classes: 'page-hero wrap', [
    span(classes: 'eyebrow', [Component.text(eyebrow)]),
    h1([
      span(classes: 'gradient-text', [Component.text(title)]),
    ]),
    p(classes: 'lede', [Component.text(lede)]),
  ]);
}

/// A docs body: a table of contents beside prose written as HTML.
Component docBody(List<(String, String)> toc, String html) {
  return div(classes: 'doc wrap', [
    nav(classes: 'toc', [
      p([Component.text('On this page')]),
      for (final (id, label) in toc) a(href: '#$id', [Component.text(label)]),
    ]),
    article(classes: 'prose', [RawText(html)]),
  ]);
}
