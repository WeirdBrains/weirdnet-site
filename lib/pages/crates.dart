import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/layout.dart';
import '../content/crates.dart';
import '../site.dart';

/// The order groups appear in; a group not listed here (a new entry's) comes last.
const crateGroups = ['Network', 'Keys and storage', 'Identity and access', 'Extensions and plugins', 'Building blocks'];

List<String> groupsInUse() => [
  ...crateGroups.where((g) => crates.any((c) => c.group == g)),
  ...{for (final c in crates) c.group}.where((g) => !crateGroups.contains(g)),
];

/// A card linking to one crate page, with its version.
Component crateCard(Crate k, {bool more = true}) => a(href: '/crates/${k.slug}', classes: 'card', [
  h3([
    span(classes: 'crate-name', [Component.text(k.name)]),
    if (k.status == Status.fresh) span(classes: 'tag new', [Component.text('new')]),
  ]),
  p(classes: 'crate-version', [Component.text(k.published ? 'v${k.version}' : 'not on crates.io yet')]),
  p([Component.text(k.tagline)]),
  if (more) span(classes: 'more', [Component.text('Guide →')]),
]);

class CratesPage extends StatelessComponent {
  const CratesPage({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      pageHero(
        eyebrow: 'The pieces',
        title: 'The Weirdnet crates',
        lede:
            'Each crate does one job, lives in a WeirdBrains repository and is BSD-3-Clause. '
            'Storage, policy and UI stay in the apps. ${crates.length} crates, each with a guide.',
      ),
      div(classes: 'wrap', [
        for (final g in groupsInUse()) ...[
          h2([Component.text(g)]),
          div(classes: 'grid', [for (final k in crates.where((c) => c.group == g)) crateCard(k)]),
          div(attributes: {'style': 'height: 2.5rem'}, []),
        ],
        h2(attributes: {'id': 'all'}, [Component.text('All crates')]),
        div(classes: 'table-wrap', [
          table(classes: 'crate-table', [
            thead([
              tr([
                th([Component.text('Crate')]),
                th([Component.text('Version')]),
                th([Component.text('What it does')]),
                th([Component.text('Links')]),
              ]),
            ]),
            tbody([
              for (final k in crates)
                tr([
                  td([
                    a(href: '/crates/${k.slug}', classes: 'mono', [Component.text(k.name)]),
                  ]),
                  td(classes: 'mono', [Component.text(k.published ? k.version : 'unpublished')]),
                  td([Component.text(k.tagline)]),
                  td(classes: 'links', [
                    a(href: repoUrl(k.repoName), [Component.text('repo')]),
                    if (k.published) ...[
                      Component.text(' · '),
                      a(href: cratesIoUrl(k.name), [Component.text('crates.io')]),
                      if (k.docsRs) ...[
                        Component.text(' · '),
                        a(href: docsRsUrl(k.name), [Component.text('docs.rs')]),
                      ],
                    ],
                  ]),
                ]),
            ]),
          ]),
        ]),
        div(attributes: {'style': 'height: 2.5rem'}, []),
      ]),
    ]);
  }
}
