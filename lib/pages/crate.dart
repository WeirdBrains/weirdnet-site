import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../content/crates.dart';
import '../site.dart';

String _html(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// One crate: what it is, its parts, an example, where it is used.
class CratePage extends StatelessComponent {
  const CratePage({required this.crate, super.key});

  final Crate crate;

  @override
  Component build(BuildContext context) {
    final k = crate;
    final deps = [for (final d in k.dependsOn) '<a href="/crates/$d">weirdnet-$d</a>'].join(', ');
    final body = StringBuffer()
      ..write('<h2 id="about">What it is</h2>')
      ..writeAll([for (final p in k.about) '<p>$p</p>'])
      ..write('<h2 id="parts">What is in it</h2><ul>')
      ..writeAll([for (final p in k.parts) '<li>$p</li>'])
      ..write('</ul>');
    if (k.example.isNotEmpty) {
      body.write('<h2 id="example">Example</h2><pre><code>${_html(k.example)}</code></pre>');
    }
    body.write('<h2 id="where">Where it fits</h2><ul>');
    if (k.dependsOn.isNotEmpty) body.write('<li>Builds on $deps.</li>');
    if (k.usedBy.isNotEmpty) body.write('<li>Used by ${k.usedBy.join(', ')}.</li>');
    if (k.origin.isNotEmpty) body.write('<li>Extracted from ${k.origin}.</li>');
    body.write('<li>License: BSD-3-Clause.</li></ul>');
    if (k.notes.isNotEmpty) body.write('<div class="callout warn">${k.notes}</div>');

    return Component.fragment([
      section(classes: 'page-hero wrap', [
        p(classes: 'crumbs', [
          a(href: '/crates', [Component.text('The pieces')]),
          Component.text(' / ${k.name}'),
        ]),
        h1([
          span(classes: 'gradient-text', [Component.text(k.name)]),
          if (k.status == Status.fresh) span(classes: 'tag new', [Component.text('new')]),
        ]),
        p(classes: 'lede', [Component.text(k.tagline)]),
        div(classes: 'facts', [
          a(href: repoUrl(k.name), [Component.text('GitHub')]),
          if (k.status == Status.shipped) ...[
            a(href: cratesIoUrl(k.name), [Component.text('crates.io')]),
            a(href: docsRsUrl(k.name), [Component.text('docs.rs')]),
          ] else
            span([Component.text('Not on crates.io yet')]),
          span(classes: 'mono', [Component.text('${k.name} = "0.1"')]),
        ]),
      ]),
      div(classes: 'doc wrap', [
        nav(classes: 'toc', [
          p([Component.text('On this page')]),
          a(href: '#about', [Component.text('What it is')]),
          a(href: '#parts', [Component.text('What is in it')]),
          if (k.example.isNotEmpty) a(href: '#example', [Component.text('Example')]),
          a(href: '#where', [Component.text('Where it fits')]),
          p(attributes: {'style': 'margin-top:1.4rem'}, [Component.text('Other crates')]),
          for (final o in crates.where((c) => c.slug != k.slug)) a(href: '/crates/${o.slug}', [Component.text(o.name)]),
        ]),
        article(classes: 'prose', [RawText(body.toString())]),
      ]),
    ]);
  }
}
