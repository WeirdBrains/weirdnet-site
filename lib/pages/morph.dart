import 'package:jaspr/jaspr.dart';

import '../components/layout.dart';
import '../site.dart';

class MorphPage extends StatelessComponent {
  const MorphPage({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      pageHero(
        eyebrow: 'Built on Weirdnet',
        title: 'Morph, the Weirdnet browser',
        lede: 'Morph is a distributed web browser with local AI, built on a Rust 2024 core and Weirdnet.',
      ),
      docBody(const [
        ('what', 'What Morph is'),
        ('uses', 'How it uses Weirdnet'),
        ('muninn', 'Alongside Muninn'),
        ('status', 'Status'),
      ], _html),
    ]);
  }
}

const _html =
    '''
<h2 id="what">What Morph is</h2>
<p>The browser is one part of the app, next to local AI, projects, notes and a peer-to-peer web. The desktop shell is
GPUI (Linux first, then macOS and Windows); Flutter is the mobile shell for Android and iOS. Both sit on the same Rust
crates.</p>
<h2 id="uses">How it uses Weirdnet</h2>
<ul>
<li><b>Identity</b>: each Morph profile has a user key made or restored at onboarding, backed up as 24 words
(<code>weirdnet-keys</code>), with a node key per device certified by it (<code>weirdnet-net</code>).</li>
<li><b>Storage</b>: its store is a SQLCipher database through <code>weirdnet-storage</code>.</li>
<li><b>Device linking</b>: moving an identity to another device over a QR offer, a short-code check and a sealed transfer
(<a href="/crates/device-link">weirdnet-device-link</a>).</li>
<li><b>Sync between linked devices</b> (Morph 0.2.0, <a href="/crates/sync">weirdnet-sync</a>): bookmarks, folders and tags,
history (visits, deletes, clear-all), and the search engine, home page and theme sync over Weirdnet, soon after unlock and
every 30 seconds.</li>
<li><b>Linked devices</b> (Morph 0.2.0): Settings &gt; Linked devices lists linked devices and revokes one, on desktop and
the phone app.</li>
<li><b>Key rotation on revoke</b> <span class="tag wip">in progress</span> (on Morph main, unreleased, on weirdnet-sync 0.3.1):
revoking a linked device changes the sync key, so that device can’t read anything synced afterwards, even with the recovery
words. Keys also rotate once by themselves after the first link, and Linked devices warns before a revoke about devices
that would be left out of the new key.</li>
<li><b>Discovery off and manual peers</b> (Morph 0.2.0, <a href="/crates/net">weirdnet-net 0.6.0</a>): Settings &gt; Relays
can turn Weirdnet discovery off and add peers by hand, and an admin policy can lock discovery off.</li>
<li><b>App calls</b> (Morph 0.2.0): <code>weirdnet-&lt;app&gt;://</code> links call the app over Weirdnet and show its answer,
with a clear page for each failure.</li>
<li><b>One network</b>: Morph joins Weirdnet as <code>weirdnet-morph</code>. It uses the default Weirdnet profile and its own <code>/morph/...</code> protocols, and links on
<code>weirdnet-morph://</code>, such as <code>weirdnet-morph://join/</code> for invitations.</li>
<li><b>Relays</b>: Morph nodes start with WeirdBrains relays and bootstrap nodes; desktops with a domain can run their own.
Phones dial out and keep a slot on a home relay.</li>
<li><b>Companions</b>: Morph’s local AI agents run on <a href="/crates/agent">weirdnet-agent</a> (0.1.0 on crates.io): the agent loop,
approvals with per-site grants, research budgets and traces with footnotes. <span class="tag wip">in progress</span></li>
</ul>
<h2 id="muninn">Alongside Muninn</h2>
<p><a href="https://github.com/WeirdBrains/muninn">Muninn</a>, the data ingestor most Weirdnet crates came from, joins
Weirdnet the same way, as <code>weirdnet-muninn</code> <span class="tag wip">in progress</span>. Like Morph it keeps its own
protocol ids (<code>/muninn/...</code>, where Morph has <code>/morph/...</code>) and shares Weirdnet identities, keys and
relays: Muninn nodes can use <a href="/relay">weirdnet-relay</a>, given the relay’s address. See
<a href="/network#apps">Apps on Weirdnet</a>.</p>
<h2 id="status">Status</h2>
<p>Morph is in alpha; the latest release is 0.2.1 (November 18, 2026), on weirdnet-net 0.6.0. See <a href="$morphSiteUrl">morph.weirdbrains.com</a> and the
<a href="https://github.com/WeirdBrains/morph">source on GitHub</a>.</p>
''';
