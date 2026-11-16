import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/layout.dart';
import '../content/crates.dart';

const _groups = ['Network', 'Keys and storage', 'Building blocks'];

class CratesPage extends StatelessComponent {
  const CratesPage({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      pageHero(
        eyebrow: 'The pieces',
        title: 'The Weirdnet crates',
        lede:
            'Each crate does one job, lives in its own WeirdBrains repository and is BSD-3-Clause. '
            'Storage, policy and UI stay in the apps.',
      ),
      div(classes: 'wrap', [
        for (final g in _groups) ...[
          h2([Component.text(g)]),
          div(classes: 'grid', [
            for (final k in crates.where((c) => c.group == g))
              a(href: '/crates/${k.slug}', classes: 'card', [
                h3([
                  span(classes: 'crate-name', [Component.text(k.name)]),
                  if (k.status == Status.fresh) span(classes: 'tag new', [Component.text('new')]),
                ]),
                p([Component.text(k.tagline)]),
                span(classes: 'more', [Component.text('Details →')]),
              ]),
          ]),
          div(attributes: {'style': 'height: 2.5rem'}, []),
        ],
      ]),
    ]);
  }
}
