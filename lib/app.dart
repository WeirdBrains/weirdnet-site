import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/layout.dart';
import 'content/crates.dart';
import 'pages/crate.dart';
import 'pages/crates.dart';
import 'pages/home.dart';
import 'pages/morph.dart';
import 'pages/network.dart';
import 'pages/relay.dart';
import 'site.dart';

/// Every page of the site. Static mode renders each route to its own HTML file.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(
          path: '/',
          title: '$siteTitle: $siteTagline',
          builder: (_, _) => const Layout(active: '/', child: Home()),
        ),
        Route(
          path: '/network',
          title: 'How the network works · $siteTitle',
          builder: (_, _) => const Layout(active: '/network', child: NetworkPage()),
        ),
        Route(
          path: '/crates',
          title: 'The pieces · $siteTitle',
          builder: (_, _) => const Layout(active: '/crates', child: CratesPage()),
        ),
        for (final k in crates)
          Route(
            path: '/crates/${k.slug}',
            title: '${k.name} · $siteTitle',
            builder: (_, _) => Layout(
              active: '/crates',
              child: CratePage(crate: k),
            ),
          ),
        Route(
          path: '/relay',
          title: 'Run a relay · $siteTitle',
          builder: (_, _) => const Layout(active: '/relay', child: RelayPage()),
        ),
        Route(
          path: '/morph',
          title: 'Morph, the Weirdnet browser · $siteTitle',
          builder: (_, _) => const Layout(active: '/morph', child: MorphPage()),
        ),
      ],
      errorBuilder: (_, _) => Layout(
        active: '',
        child: section(classes: 'page-hero wrap', [
          h1([Component.text('Not found')]),
          p(classes: 'lede', [
            Component.text('That page is not on the net. '),
            a(href: '/', [Component.text('Back home')]),
          ]),
        ]),
      ),
    );
  }
}
