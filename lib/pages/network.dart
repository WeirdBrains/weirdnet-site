import 'package:jaspr/jaspr.dart';

import '../components/diagrams.dart';
import '../components/layout.dart';

class NetworkPage extends StatelessComponent {
  const NetworkPage({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      pageHero(
        eyebrow: 'How it works',
        title: 'How the network works',
        lede:
            'Nodes, profiles, identities, invitations, sealed messages, discovery and relays: '
            'what each piece does on the wire, from the weirdnet-net source.',
      ),
      docBody(const [
        ('nodes', 'Nodes'),
        ('profiles', 'Profiles'),
        ('apps', 'Apps on Weirdnet'),
        ('identities', 'Identities and certificates'),
        ('exchange', 'Offers and invitations'),
        ('automation', 'Invitation automation'),
        ('sealed', 'Sealed messaging'),
        ('discovery', 'Peer discovery'),
        ('relays', 'Relays and hole punching'),
        ('next', 'Being built now'),
        ('security', 'Security boundaries'),
      ], _html),
    ]);
  }
}

final _html =
    '''
<h2 id="nodes">Nodes</h2>
<p>A Weirdnet node is a <code>weirdnet_net::Node&lt;Q, R&gt;</code>: a libp2p swarm over TCP and QUIC, IPv4 and IPv6, with Noise
for encryption and authentication and Yamux for multiplexing. Each node runs identify, ping, Kademlia, mDNS (optional),
AutoNAT, a relay client, DCUtR hole punching and, when asked, a relay server.</p>
<p>The application brings its own request and response types. They travel as CBOR over request-response on the profile’s
protocol id, and a <code>Handler</code> answers requests on a blocking pool. The peer id a handler sees is the one Noise
authenticated, so an answer always knows who asked. Requests may be up to 8 MiB and answers up to 256 MiB, with a
60-second timeout.</p>
<pre><code>let cfg = NodeConfig { listen: NodeConfig::default_listen(4747), mdns: true, ..Default::default() };
let node = Node::start(&amp;WEIRDNET, keypair, cfg, Arc::new(MyHandler))?;
let answer = node.request(peer, &amp;addrs, MyRequest::Hello)?;</code></pre>

<h2 id="profiles">Profiles</h2>
<p>Every identifier a node puts on the wire or under a signature comes from a <code>Profile</code>: protocol ids, token
prefixes, link schemes, signature domains and derivation labels. <code>WEIRDNET</code> is the default:</p>
<table>
<tr><th>What</th><th>Weirdnet value</th></tr>
<tr><td>Request-response protocol</td><td><code>/weirdnet/net/1</code></td></tr>
<tr><td>Kademlia</td><td><code>/weirdnet/kad/1</code></td></tr>
<tr><td>Identify</td><td><code>/weirdnet/id/1</code></td></tr>
<tr><td>Relay provider key</td><td><code>/weirdnet/relay/1</code></td></tr>
<tr><td>Offer and answer tokens</td><td><code>wnet-x1-offer:</code>, <code>wnet-x1-answer:</code></td></tr>
<tr><td>Signature domains</td><td><code>weirdnet/net/offer/v1</code>, <code>weirdnet/net/answer/v1</code>, <code>weirdnet-node-cert/1</code></td></tr>
<tr><td>Sealed message label</td><td><code>weirdnet/net/msg/v1</code></td></tr>
<tr><td>Default port</td><td>4747 (TCP and QUIC)</td></tr>
</table>
<p>Profiles never mix: tokens, signatures, sealed messages, certificates and sync keys made under one profile don’t verify
or open under another, and nodes on different protocol ids don’t talk at all. Apps share one network on the default
profile and keep their own traffic on their own protocol names (Morph uses <code>/morph/...</code>), so a node ignores
traffic it doesn’t understand. Invitation links use each app’s own scheme, such as <code>weirdnet-morph://join/</code>.</p>
<h2 id="apps">Apps on Weirdnet</h2>
<p>Each app joins Weirdnet under its own name, <code>weirdnet-&lt;app&gt;</code>, and keeps its own protocol ids for its own
traffic. What the apps share is Weirdnet itself: identities and keys (a user key backed up as 24 words, node keys
certified by it), the crates, and the relays.</p>
<table>
<tr><th>App</th><th>On Weirdnet as</th><th>Its protocol ids</th><th>Relays</th></tr>
<tr><td><a href="/morph">Morph</a></td><td><code>weirdnet-morph</code> (links on <code>weirdnet-morph://</code>)</td><td><code>/morph/...</code> on the default Weirdnet profile</td><td>Weirdnet relays, found by address or through the DHT</td></tr>
<tr><td><a href="https://github.com/WeirdBrains/muninn">Muninn</a></td><td><code>weirdnet-muninn</code> <span class="tag wip">in progress</span></td><td><code>/muninn/...</code>, unchanged</td><td>Weirdnet relays, by address</td></tr>
</table>
<p>Relaying doesn’t depend on an app’s protocol ids: circuit relay v2, DCUtR hole punching and AutoNAT are libp2p’s
standard protocols, so a node on any ids can reserve a slot on a <a href="/relay">weirdnet-relay</a> given the relay’s full
address (<code>…/p2p/&lt;relay peer id&gt;</code>), and be reached through it. weirdnet-relay’s tests run nodes on Muninn’s
<code>/muninn/...</code> ids through a relay. The Kademlia DHT and relay discovery are per protocol id, so an app on its own
ids lists its relays by address instead of finding them in the DHT.</p>

<h2 id="identities">Identities and certificates</h2>
<p>There are two kinds of key. A <b>node key</b> is an Ed25519 keypair per device, made on first use; its public key is
the libp2p peer id. The application keeps it wherever it keeps secrets, through the <code>IdentityStore</code> trait.
A <b>user key</b> is the person’s Ed25519 signing key, separate from node keys, and the same across Weirdnet apps.</p>
<p>The user key signs a <code>NodeCert</code> for each node it links (a signature over the node’s peer id) and can revoke it
later. A <code>Card</code> is what a node says about its user: the user’s public key and the node certificates and
revocations, never a secret. Peers check cards before treating a node as acting for a user.</p>
$identityDiagram
<p>Linking a new device uses a <code>link</code>-scope exchange and a link grant that hands the user key to the new node,
sealed under that exchange. Linked nodes sync their data under a <code>sync_key</code> derived from the user key, which only
the user’s own nodes hold.</p>

<h2 id="exchange">Offers and invitations</h2>
<p>Two nodes become peers through a key exchange. The offering node signs an <b>offer</b> with its node key: its peer id,
a fresh X25519 public key, its addresses, a label, a <b>scope</b> (what the exchange is for: <code>node</code>, <code>link</code>,
or an <code>invite</code> into something the app names, with a role) and an expiry, a week unless asked otherwise.</p>
<p>The offer travels as a token (<code>wnet-x1-offer:</code> plus base64url JSON, holding only public keys and signatures)
or as an invitation link. The other node verifies the signature, the scope and the expiry, and signs an <b>answer</b> with
its own fresh X25519 key, bound to the SHA-256 of the signed offer. The node that made an offer can’t answer it.</p>
$exchangeDiagram
<p>Both sides then derive the same <b>exchange key</b> with HKDF over the X25519 shared secret and the transcript of both
signed messages, plus a ten-digit <b>short code</b> (<code>12345-67890</code>) and a fingerprint. Comparing the short code out of
band, in person or over a call, is what rules out a man in the middle; the crate can’t do that for you.</p>

<h2 id="automation">Invitation automation</h2>
<p>The <code>invite</code> module lets nodes run exchanges themselves. <code>connect</code> sends a hello, then delivers a signed
offer over the node; the other side answers on the spot when the application’s <code>decide</code> says so, or keeps the offer
for its owner (only after the host’s <code>admit</code>, and only a bounded number wait). The offerer can <code>poll</code> for the
answer later, and an answerer can deliver an answer it made while the offerer was away (<code>settle</code>).</p>
<p>Two nodes that offer to each other at once settle on one exchange. A node <i>is</i> its key: the first completed exchange
pins it (trust on first use), a name shared by several nodes resolves to the pinned one, and a node using a pinned node’s
name is flagged as a possible impostor for the app to show.</p>

<h2 id="sealed">Sealed messaging</h2>
<p>Once an exchange is complete, requests between the two nodes can travel sealed: XChaCha20-Poly1305 under the exchange
key, with the profile’s message label, the exchange id and both peer ids, in order, as associated data. A message can’t
be moved to another exchange or turned around.</p>
$sealedDiagram
<p><code>sealed::call</code> seals a request into the application’s own envelope and opens the sealed answer.
<code>sealed::serve</code> opens a request only when the exchange is known, active (complete and not revoked) and belongs to
the Noise-authenticated sender. What is inside, and what each request may reach, stays the application’s.</p>

<h2 id="discovery">Peer discovery</h2>
<ul>
<li><b>Local network</b>: with mDNS on, nodes announce themselves and dial the peers they find.</li>
<li><b>Kademlia</b>: nodes start from bootstrap addresses (<code>/ip4/…/tcp/…/p2p/…</code>) and keep a routing table; relays
run Kademlia in server mode.</li>
<li><b>Identify</b>: every connection exchanges the protocols a peer speaks. A peer is listed with the profile’s capability,
<code>relay</code> if it relays, and <code>kad</code> if it serves the DHT.</li>
<li><b>Relays by provider key</b>: relays provide the profile’s relay key (<code>/weirdnet/relay/1</code>) in the DHT, and
nodes look it up every minute, so they find relays they were not configured with.</li>
</ul>
$discoveryDiagram

<h2 id="relays">Relays and hole punching</h2>
<p>Phones on cellular sit behind carrier NAT and can only dial out. AutoNAT tells a node whether it is publicly reachable.
A node that is not reserves a slot on a relay (libp2p circuit relay v2) and becomes reachable at
<code>/…/p2p/RELAY/p2p-circuit/p2p/NODE</code>. A node behind NAT that meets a relay through identify reserves on it by itself.</p>
<p>When a peer connects through the circuit, DCUtR coordinates a simultaneous dial so the two can switch to a direct
connection. That works most of the time, not always; when it fails, the relayed connection stays. Relays are the fallback
that always works, as long as the device can make one outbound connection.</p>
$relayDiagram
<p>Anyone can run a relay with <a href="/relay">weirdnet-relay</a>. WeirdBrains runs public relays and bootstrap nodes;
running your own is optional and needs a domain tied to the machine through Grindvakt dynamic DNS.</p>
<div class="callout">The WeirdBrains public relay is <code>relay.net.weirdbrains.com</code>
<span class="tag shipped">live</span>: <a href="https://relay.net.weirdbrains.com/">its info page</a>. See
<a href="/relay#public">Run a relay</a> for its addresses.</div>

<h2 id="next">Being built now <span class="tag wip">in progress</span></h2>
<p>These pieces are being built into Weirdnet now, following the design in Morph’s architecture:</p>
<ul>
<li><b>Data-carrying relays</b> <span class="tag shipped">shipped</span>: relay limits are configurable in <code>weirdnet-net</code>
(<code>NodeConfig::relay_limits</code>, <code>RelayLimits::unlimited()</code>; the library default stays libp2p’s), and
weirdnet-relay runs with no circuit time or data caps and no rate limiters by default.</li>
<li><b>Names and rendezvous</b> <span class="tag shipped">shipped</span>: signed, versioned peer records (current addresses
plus the home relay, chained to the user key by the node certificate) registered with the home relay’s names server
(<code>/weirdnet/names/1</code>) and put in the DHT only while a site is hosted, with signed withdrawal tombstones; every
storing node checks signatures, certificates, expiry and <code>seq</code>. Apps push records to trusted peers themselves.
Encrypted, daily-blinded locator records for private sites are still to come.</li>
<li><b>Key-only dialing</b> <span class="tag shipped">shipped</span>: <code>request_key</code> reaches a peer by its peer id
(the DHT, then circuits through shared relays), and <code>request_user</code> by user id through its record.</li>
<li><b>Path switching</b>: app streams that survive moving between the relay and a direct path.</li>
<li><b>WebSocket over TLS on 443</b> for networks that block UDP and odd ports.</li>
<li><b>Public HTTPS forwarding</b> by SNI passthrough: TLS ends at the host, the relay never holds a key, each name needs the
owner’s signed grant, and forwarding can be revoked per site.</li>
<li><b>Push wake-up</b>, <b>update announcements</b>, <b>access policy</b> (<code>weirdnet-access</code>), <b>device linking</b>,
<b>TLS certificates</b> and <b>URL schemes</b> as their own crates.</li>
</ul>

<h2 id="security">Security boundaries</h2>
<p>From <code>weirdnet-net</code>’s security notes. The crate enforces: signatures on offers, answers, certificates and
revocations; answers bound to their offer; sealed messages bound to their exchange, peers and direction; offers kept only
from the node that signed them; and profiles that don’t mix.</p>
<p>It leaves to the application: whether to answer an offer, who may do what over an exchange, which users are trusted,
what an invitation grants, every limit on what peers may store or ask for, and keeping secrets encrypted at rest.</p>
<div class="callout warn">Nobody has audited weirdnet-net yet. Read <code>SECURITY.md</code> in each repository before relying on it.</div>
''';
