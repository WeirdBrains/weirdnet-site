import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/layout.dart';
import '../content/crates.dart';
import '../content/examples.dart';
import '../content/guides.dart';
import '../site.dart';

String _html(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

/// How to add the crate: a dependency line, or `cargo install` for programs.
String installLine(Crate k) {
  if (k.binary) return 'cargo install ${k.name}';
  if (k.published) return '${k.name} = "${k.version}"';
  return '${k.name} = { git = "${repoUrl(k.repoName)}" }';
}

/// One crate: what it brings, how it works, its parts, feature flags, usage, where it fits.
class CratePage extends StatelessComponent {
  const CratePage({required this.crate, super.key});

  final Crate crate;

  @override
  Component build(BuildContext context) {
    final k = crate;
    final g = guides[k.slug];
    final ex = examples[k.slug];
    final deps = [for (final d in k.dependsOn) '<a href="/crates/$d">${crateNameOf(d)}</a>'].join(', ');
    final toc = <(String, String)>[];
    final body = StringBuffer();
    void add(String id, String title, String html) {
      toc.add((id, title));
      body.write('<h2 id="$id">$title</h2>$html');
    }

    if (g != null) add('brings', 'What it brings', g.brings);
    add('about', 'What it is', [for (final p in k.about) '<p>$p</p>'].join());
    if (g != null) add('works', 'How it works', g.works);
    add('parts', 'Key types and modules', '<ul>${[for (final p in k.parts) '<li>$p</li>'].join()}</ul>');
    if (g != null) {
      add(
        'features',
        'Feature flags',
        g.features.isEmpty
            ? '<p>None: everything is on by default.</p>'
            : '<ul>${[for (final f in g.features) '<li>$f</li>'].join()}</ul>',
      );
    }
    final usage = StringBuffer();
    if (g != null && g.install.isNotEmpty) {
      usage.write('<p>Install:</p><pre><code>${_html(g.install)}</code></pre>');
    }
    if (ex != null) {
      usage
        ..write('<p>In <code>Cargo.toml</code>:</p><pre><code>${_html(ex.deps)}</code></pre>')
        ..write('<p>Then (built and run against the published crate when this page was made):</p>')
        ..write('<pre><code>${_html(ex.code)}</code></pre>');
    } else if (k.example.isNotEmpty) {
      usage
        ..write('<pre><code>${_html('[dependencies]\n${installLine(k)}')}</code></pre>')
        ..write('<pre><code>${_html(k.example)}</code></pre>');
    } else if (usage.isEmpty) {
      usage.write('<pre><code>${_html(k.binary ? installLine(k) : '[dependencies]\n${installLine(k)}')}</code></pre>');
    }
    add('usage', k.binary ? 'Install and use' : 'Usage', usage.toString());

    final fits = StringBuffer('<ul>');
    if (k.dependsOn.isNotEmpty) fits.write('<li>Builds on $deps.</li>');
    if (k.usedBy.isNotEmpty) fits.write('<li>Used by ${k.usedBy.join(', ')}.</li>');
    if (k.origin.isNotEmpty) fits.write('<li>Extracted from ${k.origin}.</li>');
    fits.write('<li>License: BSD-3-Clause.</li></ul>');
    add('where', 'Where it fits', fits.toString());
    if (k.notes.isNotEmpty) body.write('<div class="callout warn">${k.notes}</div>');
    if (g != null && g.todo.isNotEmpty) {
      toc.add(('todo', 'Notes wanted'));
      body.write('<div class="callout todo" id="todo"><b>Notes wanted</b><ul>');
      body.writeAll([for (final t in g.todo) '<li>$t</li>']);
      body.write('</ul></div>');
    }

    return Component.fragment([
      _hero(k),
      div(classes: 'doc wrap', [
        nav(classes: 'toc', [
          p([Component.text('On this page')]),
          for (final (id, title) in toc) a(href: '#$id', [Component.text(title)]),
          p(attributes: {'style': 'margin-top:1.4rem'}, [Component.text('Other crates')]),
          for (final o in crates.where((c) => c.slug != k.slug)) a(href: '/crates/${o.slug}', [Component.text(o.name)]),
        ]),
        article(classes: 'prose', [RawText(keepPre(body.toString()))]),
      ]),
    ]);
  }

  Component _hero(Crate k) => section(classes: 'page-hero wrap', [
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
      if (k.published) span(classes: 'tag version', [Component.text('v${k.version}')]),
      a(href: repoUrl(k.repoName), [Component.text('GitHub')]),
      if (k.published) ...[
        a(href: cratesIoUrl(k.name), [Component.text('crates.io')]),
        if (k.docsRs) a(href: '${docsRsUrl(k.name)}/${k.version}', [Component.text('docs.rs')]),
      ] else
        span([Component.text('Not on crates.io yet')]),
      span(classes: 'mono', [Component.text(installLine(k))]),
    ]),
  ]);
}
