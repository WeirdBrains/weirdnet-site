import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../components/diagrams.dart';
import '../content/crates.dart';
import '../site.dart';

class Home extends StatelessComponent {
  const Home({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      section(classes: 'hero wrap', [
        img(src: '/images/weirdnet-mark.svg', alt: '', classes: 'hero-mark'),
        span(classes: 'eyebrow', [Component.text('Open source · Rust · libp2p')]),
        h1([
          span(classes: 'gradient-text', [Component.text('The peer-to-peer net under WeirdBrains apps')]),
        ]),
        p(classes: 'lede', [
          Component.text(
            'Weirdnet is a set of crates for apps that talk to each other directly: a libp2p node, '
            'signed invitations and key exchanges, sealed messages, identities that work across apps, '
            'and relays for the devices NAT hides.',
          ),
        ]),
        div(classes: 'actions', [
          a(href: '/network', classes: 'button solid', [Component.text('How the net works')]),
          a(href: '/relay', classes: 'button b2', [Component.text('Run a relay')]),
          a(href: orgUrl, classes: 'button b3', [Component.text('GitHub')]),
        ]),
      ]),
      section(classes: 'section band', [
        div(classes: 'wrap', [
          div(classes: 'section-head', [
            h2([
              span(classes: 'gradient-text', [Component.text('What Weirdnet is')]),
            ]),
            p([
              Component.text(
                'The apps keep their own data, storage and policy. The crates bring the wire and the cryptography, '
                'so every WeirdBrains app speaks the same network.',
              ),
            ]),
          ]),
          RawText(overviewDiagram),
        ]),
      ]),
      section(classes: 'section', [
        div(classes: 'wrap', [
          div(classes: 'section-head', [
            h2([
              span(classes: 'gradient-text', [Component.text('How the net holds together')]),
            ]),
            p([Component.text('Five ideas carry everything else. Each links to the details.')]),
          ]),
          div(classes: 'grid', [
            _idea(
              'Identities',
              'A user key for the person, a node key per device, certificates that tie them together.',
              'identities',
            ),
            _idea(
              'Invitations',
              'Signed offers and answers. Both sides derive one key and a short code to compare.',
              'exchange',
            ),
            _idea(
              'Sealed messages',
              'Requests sealed under the exchange key, bound to the exchange, the peers and the direction.',
              'sealed',
            ),
            _idea(
              'Discovery',
              'mDNS on the local network, Kademlia from bootstrap nodes, relays found by provider key.',
              'discovery',
            ),
            _idea(
              'Relays',
              'Devices behind NAT reserve a slot. Hole punching first, the relay circuit as the fallback.',
              'relays',
            ),
          ]),
        ]),
      ]),
      section(classes: 'section band', [
        div(classes: 'wrap', [
          div(classes: 'section-head', [
            h2([
              span(classes: 'gradient-text', [Component.text('The pieces')]),
            ]),
            p([Component.text('Each crate does one job and lives in its own WeirdBrains repository.')]),
          ]),
          div(classes: 'grid', [
            for (final k in crates)
              a(href: '/crates/${k.slug}', classes: 'card', [
                h3([
                  span(classes: 'crate-name', [Component.text(k.name)]),
                  if (k.status == Status.fresh) span(classes: 'tag new', [Component.text('new')]),
                ]),
                p([Component.text(k.tagline)]),
              ]),
          ]),
        ]),
      ]),
      section(classes: 'section', [
        div(classes: 'wrap', [
          div(classes: 'section-head', [
            h2([
              span(classes: 'gradient-text', [Component.text('Built on Weirdnet')]),
            ]),
            p([
              Component.text(
                'Each app joins as weirdnet-<app> (Morph as weirdnet-morph, Muninn as weirdnet-muninn) and keeps its own '
                'protocol ids (/morph/..., /muninn/...), while sharing Weirdnet identities, keys and relays.',
              ),
            ]),
            a(href: '/network#apps', classes: 'more', [Component.text('Apps on Weirdnet →')]),
          ]),
          div(classes: 'grid', [
            _app(
              'Morph',
              'weirdnet-morph. A distributed web browser with local AI. Identity, device linking and peer sites on Weirdnet, its own /morph/... protocols.',
              '/morph',
            ),
            _app(
              'Muninn',
              'weirdnet-muninn. The data ingestor most of Weirdnet’s crates were extracted from. Keeps its /muninn/... protocols and uses Weirdnet relays.',
              '/morph#muninn',
            ),
            _app(
              'TAUR',
              'An alternative Arch user repository server, on weirdnet-accounts and weirdnet-mcp.',
              repoUrl('taur'),
            ),
            _app(
              'Salty Gull',
              'Signed, consent-first over-the-air updates, on weirdnet-update.',
              repoUrl('salty-gull'),
            ),
          ]),
        ]),
      ]),
    ]);
  }

  static Component _idea(String title, String text, String anchor) => a(href: '/network#$anchor', classes: 'card', [
    h3([Component.text(title)]),
    p([Component.text(text)]),
    span(classes: 'more', [Component.text('Read more →')]),
  ]);

  static Component _app(String title, String text, String href) => a(href: href, classes: 'card', [
    h3([Component.text(title)]),
    p([Component.text(text)]),
  ]);
}
