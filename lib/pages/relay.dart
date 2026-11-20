import 'package:jaspr/jaspr.dart';

import '../components/diagrams.dart';
import '../components/layout.dart';

class RelayPage extends StatelessComponent {
  const RelayPage({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      pageHero(
        eyebrow: 'Run a relay',
        title: 'Run a Weirdnet relay',
        lede:
            'weirdnet-relay is a relay and bootstrap node for the Weirdnet network: it carries traffic for devices '
            'behind NAT, serves the DHT, and tells people and apps how to reach it.',
      ),
      docBody(const [
        ('what', 'What a relay does'),
        ('public', 'The WeirdBrains public relay'),
        ('build', 'Build and install'),
        ('key', 'The database key'),
        ('config', 'Configure'),
        ('systemd', 'Run it with systemd'),
        ('network', 'Ports and DNS'),
        ('info', 'The info page'),
        ('apps', 'Adding a relay to an app'),
      ], _html),
    ]);
  }
}

final _html =
    '''
<div class="callout">weirdnet-relay 0.6 is out: <a href="https://github.com/WeirdBrains/weirdnet-relay">github.com/WeirdBrains/weirdnet-relay</a>. It runs weirdnet-net 0.8, so its names server and info request are <code>/2</code> and answer 0.8 nodes only. The commands and settings below work the same in 0.6; later versions add the optional sections in the <a href="/crates/relay">crate guide</a>.</div>
<h2 id="what">What a relay does</h2>
<ul>
<li><b>Circuit relay v2</b>: nodes behind NAT reserve a slot and are reachable through <code>…/p2p/RELAY/p2p-circuit/p2p/NODE</code>.
Circuits have no time or data cap unless you set one.</li>
<li><b>Hole punching</b>: peers that meet through the relay try DCUtR for a direct connection; the circuit is the fallback.</li>
<li><b>Bootstrap and DHT</b>: Kademlia in server mode, and the <code>/weirdnet/relay/1</code> provider record so nodes find it.</li>
<li><b>AutoNAT</b>: answers the probes nodes use to learn whether they are reachable.</li>
<li><b>Names server</b>: devices register signed peer records with their home relay (<code>/weirdnet/names/2</code>) and others
look them up by user id. Records are checked and kept in the relay’s encrypted database until they expire.</li>
<li><b>Info page</b>: HTML and JSON with its name, peer id and addresses.</li>
</ul>
$relayDiagram

<h2 id="public">The WeirdBrains public relay</h2>
<p><a href="https://weirdbrains.com">WeirdBrains</a> runs public relays. The first is <code>relay.net.weirdbrains.com</code>
<span class="tag shipped">live</span>. Its info page is <a href="https://relay.net.weirdbrains.com/">relay.net.weirdbrains.com</a>
(JSON at <a href="https://relay.net.weirdbrains.com/.well-known/weirdnet-relay.json"><code>/.well-known/weirdnet-relay.json</code></a>).
Use it as a bootstrap node and relay:</p>
<pre><code>/dns4/relay.net.weirdbrains.com/tcp/4747/p2p/12D3KooWHp56KezbVCubjuznJGqyn9xTe8PWePfuwv4YQUGxaRBB
/dns4/relay.net.weirdbrains.com/udp/4747/quic-v1/p2p/12D3KooWHp56KezbVCubjuznJGqyn9xTe8PWePfuwv4YQUGxaRBB</code></pre>
<p>Abuse reports go to <a href="mailto:michael+relay@weirdbrains.com">michael+relay@weirdbrains.com</a>. How it is
installed is in <a href="https://github.com/WeirdBrains/weirdnet-relay/blob/main/DEPLOY.md">DEPLOY.md</a>.</p>

<h2 id="build">Install</h2>
<p>Each <a href="https://github.com/WeirdBrains/weirdnet-relay/releases">release</a> has a <code>.deb</code> for amd64 and
arm64 (Debian 12+, Ubuntu 24.04+) and <code>tar.gz</code> builds, with a <code>SHA256SUMS</code> file:</p>
<pre><code>V=0.6.0; ARCH=\$(dpkg --print-architecture)
curl -fLO https://github.com/WeirdBrains/weirdnet-relay/releases/download/v\$V/weirdnet-relay_\$V-1_\$ARCH.deb
sudo apt-get install ./weirdnet-relay_\$V-1_\$ARCH.deb</code></pre>
<p>It installs the binary, the hardened systemd unit and <code>/etc/weirdnet-relay/relay.toml</code>, and starts nothing
until the database key below exists. SQLCipher is built in; no other libraries are needed. To build from source
instead: <code>cargo deb --locked</code> (Rust 1.99 or newer, cargo-deb).</p>

<h2 id="key">The database key</h2>
<p>The relay keeps its node key and its state in one SQLCipher database, <code>relay.db</code>, encrypted with a 32-byte key
you supply. It never stores that key. Make one and hand it to systemd as a credential, so it never sits in the config or
the environment:</p>
<pre><code>weirdnet-relay gen-key | sudo systemd-creds encrypt --name=db-key - /etc/weirdnet-relay/db-key.cred</code></pre>
<p>The unit loads it with <code>LoadCredentialEncrypted=db-key:/etc/weirdnet-relay/db-key.cred</code>, and the relay reads
<code>\$CREDENTIALS_DIRECTORY/db-key</code>. Outside systemd, pass <code>--db-key-file</code> (64 hex characters or 32 raw
bytes, readable only by the relay). Keep a backup of the key: without it the relay gets a new identity.</p>

<h2 id="config">Configure</h2>
<pre><code>name = "My relay"
operator = "Me"
contact = "abuse@example.com"

[network]
port = 4747
external = ["/dns4/relay.example.com/tcp/4747", "/dns4/relay.example.com/udp/4747/quic-v1"]
bootstrap = ["/dns4/relay.net.weirdbrains.com/tcp/4747/p2p/12D3KooWHp56KezbVCubjuznJGqyn9xTe8PWePfuwv4YQUGxaRBB"]

[limits]
preset = "unlimited"  # the default: no caps, no rate limiters; "libp2p" for libp2p's
# max_circuit_duration_secs = 3600
# max_circuit_bytes = 0  # 0: no limit

[http]
listen = "127.0.0.1:4780"</code></pre>
<p>Every setting also has a flag and a <code>WEIRDNET_RELAY_*</code> environment variable; flags win over the environment,
which wins over the file. <code>weirdnet-relay check-config</code> validates a file and opens the database,
<code>weirdnet-relay id</code> prints the peer id, and <code>weirdnet-relay info</code> prints the info document.
The full example is <a href="https://github.com/WeirdBrains/weirdnet-relay/blob/main/examples/relay.toml">examples/relay.toml</a>.</p>

<h2 id="systemd">Run it with systemd</h2>
<pre><code>sudo systemctl daemon-reload
sudo systemctl enable --now weirdnet-relay
journalctl -u weirdnet-relay -f</code></pre>
<p>The unit runs as a dynamic user with <code>StateDirectory=weirdnet-relay</code>, a read-only system
(<code>ProtectSystem=strict</code>), no home, private <code>/tmp</code> and devices, no new privileges, a system-call filter and
no capabilities.</p>

<h2 id="network">Ports and DNS</h2>
<ul>
<li>Open TCP and UDP 4747 (TCP and QUIC).</li>
<li>Set <code>external</code> to the addresses people reach you at; a relay only announces routable ones.</li>
<li>Self-hosted relays need a domain that follows the machine. From 0.5.0 the relay keeps it current itself through Grindvakt: set <code>[ddns]</code> (DigitalOcean or DNSimple, the token in the <code>dns-token</code> credential) and check with <code>weirdnet-relay ddns</code>.</li>
<li>The info page listens on localhost; put it behind your web server with TLS to publish it.</li>
</ul>

<h2 id="info">The info page</h2>
<p><code>GET /</code> is a page for people. <code>GET /.well-known/weirdnet-relay.json</code> is for apps (CORS open),
<code>GET /healthz</code> is for monitoring, and peers can ask for the same document over <code>/weirdnet/relay/info/2</code>:</p>
<pre><code>{
  "v": 1,
  "name": "My relay",
  "contact": "abuse@example.com",
  "software": "weirdnet-relay/0.6.0",
  "peer_id": "12D3KooW…",
  "addrs": ["/dns4/relay.example.com/tcp/4747/p2p/12D3KooW…",
            "/dns4/relay.example.com/udp/4747/quic-v1/p2p/12D3KooW…"],
  "transports": ["tcp", "quic-v1"],
  "protocols": ["/libp2p/circuit/relay/0.2.0/hop", "/libp2p/dcutr", "/weirdnet/kad/1", "/weirdnet/id/1", "…"],
  "roles": ["relay", "bootstrap", "kad-server", "autonat"],
  "limits": { "max_circuit_duration_secs": null, "max_circuit_bytes": null }
}</code></pre>

<h2 id="apps">Adding a relay to an app</h2>
<p>Give the full address, with <code>/p2p/&lt;peer id&gt;</code>, to the node’s <code>relays</code> and <code>bootstrap</code>
settings (the <a href="https://weirdbrains.com">WeirdBrains</a> relay’s, above, once it is online). Morph and other Weirdnet apps can read the JSON above to fill them in; nodes behind NAT also find relays by
themselves through the DHT.</p>
''';
