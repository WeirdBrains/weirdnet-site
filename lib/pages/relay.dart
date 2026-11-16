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
<div class="callout warn">weirdnet-relay is new and being finished. Commands and settings below are those of version 0.1.</div>
<h2 id="what">What a relay does</h2>
<ul>
<li><b>Circuit relay v2</b>: nodes behind NAT reserve a slot and are reachable through <code>…/p2p/RELAY/p2p-circuit/p2p/NODE</code>.
Circuits have no time or data cap unless you set one.</li>
<li><b>Hole punching</b>: peers that meet through the relay try DCUtR for a direct connection; the circuit is the fallback.</li>
<li><b>Bootstrap and DHT</b>: Kademlia in server mode, and the <code>/weirdnet/relay/1</code> provider record so nodes find it.</li>
<li><b>AutoNAT</b>: answers the probes nodes use to learn whether they are reachable.</li>
<li><b>Info page</b>: HTML and JSON with its name, peer id and addresses.</li>
</ul>
$relayDiagram

<h2 id="build">Build and install</h2>
<pre><code>git clone https://github.com/WeirdBrains/weirdnet-relay
cd weirdnet-relay
cargo build --release
sudo install -m 0755 target/release/weirdnet-relay /usr/bin/
sudo install -d /etc/weirdnet-relay
sudo install -m 0644 examples/relay.toml /etc/weirdnet-relay/relay.toml
sudo install -m 0644 packaging/systemd/weirdnet-relay.service /etc/systemd/system/</code></pre>
<p>Rust 1.99 or newer. SQLCipher is bundled; no system libraries are needed.</p>

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
bootstrap = []

[limits]            # no caps unless you set them
# max_circuit_duration_secs = 3600
# max_circuit_bytes = 0

[http]
listen = "127.0.0.1:4780"</code></pre>
<p>Every setting also has a flag and a <code>WEIRDNET_RELAY_*</code> environment variable; flags win over the environment,
which wins over the file. <code>weirdnet-relay check-config</code> validates a file and <code>weirdnet-relay id</code>
prints the peer id.</p>

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
<li>Self-hosted relays need a domain that follows the machine: tie one to it with Grindvakt dynamic DNS.</li>
<li>The info page listens on localhost; put it behind your web server with TLS to publish it.</li>
</ul>

<h2 id="info">The info page</h2>
<p><code>GET /</code> is a page for people. <code>GET /.well-known/weirdnet-relay.json</code> is for apps:</p>
<pre><code>{
  "v": 1,
  "name": "My relay",
  "contact": "abuse@example.com",
  "software": "weirdnet-relay/0.1.0",
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
settings. Morph and other Weirdnet apps can read the JSON above to fill them in; nodes behind NAT also find relays by
themselves through the DHT.</p>
''';
