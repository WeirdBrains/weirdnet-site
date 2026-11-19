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
        ('next', 'What has shipped'),
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
<tr><td>Request-response protocol</td><td><code>/weirdnet/net/2</code></td></tr>
<tr><td>Kademlia</td><td><code>/weirdnet/kad/1</code></td></tr>
<tr><td>Identify</td><td><code>/weirdnet/id/1</code></td></tr>
<tr><td>Relay provider key</td><td><code>/weirdnet/relay/1</code></td></tr>
<tr><td>Offer and answer tokens</td><td><code>wnet-x1-offer:</code>, <code>wnet-x1-answer:</code></td></tr>
<tr><td>Invitation and answer links</td><td>None: each app sets its own <code>weirdnet-&lt;app&gt;://join/</code> (weirdnet-net 0.7.0)</td></tr>
<tr><td>Signature domains</td><td><code>weirdnet/net/offer/v1</code>, <code>weirdnet/net/answer/v1</code>, <code>weirdnet-node-cert/1</code></td></tr>
<tr><td>Sealed message label</td><td><code>weirdnet/net/msg/v1</code></td></tr>
<tr><td>Default port</td><td>4747 (TCP and QUIC)</td></tr>
</table>
<p>Profiles never mix: tokens, signatures, sealed messages, certificates and sync keys made under one profile don’t verify
or open under another, and nodes on different protocol ids don’t talk at all. Apps share one network on the default
profile and keep their own traffic on their own protocol names (Morph uses <code>/morph/...</code>), so a node ignores
traffic it doesn’t understand. Invitation links use each app’s own scheme, such as <code>weirdnet-morph://join/</code>:
since weirdnet-net 0.7.0 the default profile has no link scheme, and links on the reserved bare <code>weirdnet://</code>
are never made or read.</p>
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
<h3 id="app-calls">App calls</h3>
<p>A <code>weirdnet-&lt;app&gt;://</code> URL names an app and a person (or a node), and an app call carries an HTTP-like
request to the node that serves it. A node serves an app with <code>Node::serve_app</code> and tells peers which apps it
serves through identify. A caller resolves the URL’s locator (a peer id, a user id, or a name bound by
<code>_weirdnet.&lt;name&gt;</code> TXT) to that user’s record on the names servers or in the DHT, keeps the peers that
serve the app, and calls one with <code>Node::app_call</code>. The call goes directly or by hole punching first, then
through the relay circuits in the record.</p>
<p>Each call is one libp2p stream on <code>/weirdnet/app/1</code>. A CBOR head <code>{v, app, method, path, headers}</code> comes first,
prefixed with its unsigned-varint length. The body follows as varint-length frames that end with an empty one. The answer
is a CBOR <code>{v, status, headers}</code> head, or <code>{v, error, message}</code>, followed by its own frames. Bodies stream both
ways with no size cap. Heads are capped at 16 KiB, and a call that goes 60 seconds without a byte ends. Dropping a call
resets its stream, which stops the server’s handler. Relays only forward the bytes, within their circuit limits. A node
that serves an app keeps its relay reservations, even in the background.</p>

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
<li><b>Turning discovery off</b> (weirdnet-net 0.6.0): <code>DiscoveryMode::Disabled</code> on <code>NodeConfig</code> turns off
mDNS and Kademlia (bootstrap, advertising, and learning peers from identify). Configured relays, listening, request-response,
app calls, content streams and manual peers still work; the DHT calls return “peer discovery is disabled”, and
<code>Status</code> reports whether discovery is on.</li>
<li><b>Manual peers</b> (weirdnet-net 0.6.0): <code>PeerHint</code>, <code>NodeConfig::peers</code> and
<code>Node::add_peer</code> / <code>remove_peer</code> / <code>peers</code>, with <code>encode_peers</code> /
<code>decode_peers</code> for the app to persist them. A hint is an address, not trust: the node certificate and the app’s
roster still decide who a peer is.</li>
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

<h2 id="next">What has shipped</h2>
<p>These pieces were built into Weirdnet following the design in Morph’s architecture, and all of them have shipped.
Each links to its crate guide.</p>
<ul>
<li><b>Discovery toggle and manual peers</b> <span class="tag shipped">shipped</span> (<a href="/crates/net">weirdnet-net 0.6.0</a>): run
without mDNS and the DHT and dial peers from an app-kept address book; see <a href="#discovery">Peer discovery</a>.</li>
<li><b>Device sync with key rotation</b> <span class="tag shipped">shipped</span> (<a href="/crates/sync">weirdnet-sync 0.5.0</a>):
revoking a device rotates to a random epoch key sealed to each remaining device, so a revoked device that holds the seed
cannot read later ops. 0.4.0 adds records over a page size (hash-checked chunks) and sealed records a revoked device cannot read. 0.5.0 moves to weirdnet-net 0.8 (protocol <code>/weirdnet/sync/2</code>, larger pages) and does not talk to 0.4 nodes.</li>
<li><b>Agent runtime</b> <span class="tag shipped">shipped</span> (<a href="/crates/agent">weirdnet-agent 0.2.0</a>): the shared
agent loop with streaming events and cancellation, tool sources, tiered approval policy, research budgets and traces with
citation checks; since 0.2.0, model turns and whole tasks can run on another of the user’s nodes. Morph’s Companions are its first user.</li>
<li><b>Data-carrying relays</b> <span class="tag shipped">shipped</span>: relay limits are configurable in <code>weirdnet-net</code>
(<code>NodeConfig::relay_limits</code>, <code>RelayLimits::unlimited()</code>; the library default stays libp2p’s), and
weirdnet-relay runs with no circuit time or data caps and no rate limiters by default.</li>
<li><b>Names and rendezvous</b> <span class="tag shipped">shipped</span>: signed, versioned peer records (current addresses
plus the home relay, chained to the user key by the node certificate) registered with the home relay’s names server
(<code>/weirdnet/names/2</code>) and put in the DHT only while a site is hosted, with signed withdrawal tombstones; every
storing node checks signatures, certificates, expiry and <code>seq</code>. Apps push records to trusted peers themselves.
Encrypted, daily-blinded locator records for private sites ship in weirdnet-net 0.4.0.</li>
<li><b>Key-only dialing</b> <span class="tag shipped">shipped</span>: <code>request_key</code> reaches a peer by its peer id
(the DHT, then circuits through shared relays), and <code>request_user</code> by user id through its record.</li>
<li><b>Streams and path switching</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0): byte
streams with no size cap and backpressure on each app’s own protocol ids (<code>Node::accept_streams</code>,
<code>Node::open_stream</code>), several apps on one node. A stream moves from the relay to a direct connection when one comes
up and back to the relay if it drops, without losing or repeating a byte.</li>
<li><b>Status events and app lifecycle</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0):
an event stream and status watch (connections and their path, listeners, relay reservations, NAT),
<code>pause</code>/<code>resume</code> for apps going to the background, <code>network_changed</code> for a new network,
lost reservations made again, async calls, and CI builds for Android and iOS.</li>
<li><b>WebSocket over TLS on 443</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0) for
networks that block UDP and odd ports: every node dials <code>/tls/ws</code> and <code>/wss</code> addresses, and a node with a
certificate listens on them. The relay listens on 443 from 0.2.0.</li>
<li><b>Public HTTPS forwarding</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0) by SNI
passthrough: TLS ends at the host, the ingress never holds a key, each name needs the owner’s signed grant and a
<code>_weirdnet</code> DNS binding, port 80 only passes ACME HTTP-01, and forwarding can be revoked per site or turned off.
The relay forwards from 0.2.0.</li>
<li><b>Names in DNS</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0):
<code>dnsaddr_record</code> builds the <code>_dnsaddr</code> TXT record a node is dialed by.</li>
<li><b>Content transfer</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0): files in
content-defined chunks addressed by BLAKE3, signed manifests, fetching from one or several peers with every chunk checked,
only the changed chunks for a new version, byte ranges, resuming after an interruption, and DHT provider records for
public content.</li>
<li><b>Membership and requests to join</b> <span class="tag shipped">shipped</span> (weirdnet-net 0.3.0):
memberships with a role, signed by the owner, and their revocations; presenting one on a stream, checked against the
sending node; signed requests to join with approvals, denials, rate limits and a host queue.</li>
<li><b>Tested on real networks</b> <span class="tag shipped">shipped</span>: CI runs nodes in network namespaces behind NAT
routers: relay reservations, hole punching from a relayed stream to a direct one, a symmetric NAT staying on the relay,
QUIC, mDNS and AutoNAT.</li>
<li><b>TLS certificates</b> <span class="tag shipped">shipped</span> (<a href="/crates/tls">weirdnet-tls 0.2.0</a>): ACME with TLS-ALPN-01, HTTP-01 and DNS-01, certificate stores, an SNI resolver that swaps certificates
without a restart, and renewal by the CA's renewal window with backoff. Muninn orders its certificates through it.</li>
<li><b>Sealed streams</b> <span class="tag shipped">shipped</span> (<a href="/crates/net">weirdnet-net 0.4.0</a>): byte
streams encrypted per direction and bound to the exchange and both peers, for private and members-only content.</li>
<li><b>App calls</b> <span class="tag shipped">shipped</span> (<a href="/crates/net">weirdnet-net 0.5.0</a>): HTTP-like
requests with streamed bodies to the node that serves an app, for <code>weirdnet-&lt;app&gt;://</code> URLs, found by peer id,
user id or name and reached directly or through relays (<a href="#app-calls">how</a>).</li>
<li><b>Access policy</b> <span class="tag shipped">shipped</span> (<a href="/crates/access">weirdnet-access 0.1.1</a>): private or
public and open or members-only as separate settings, a shared permission core apps extend, ranked roles, and the order
every request is checked in. A private resource is seen only by its owner and trusted users; members must be trusted too. Muninn's org roles use its catalog and rank rules.</li>
<li><b>Push wake-up</b> <span class="tag shipped">shipped</span> (<a href="/crates/push">weirdnet-push 0.1.0</a>): sealed wake
payloads through APNs and FCM that carry no content, and a self-hostable push server.</li>
<li><b>URL schemes</b> <span class="tag shipped">shipped</span> (<a href="/crates/schemes">weirdnet-schemes 0.1.0</a> and <a href="/crates/weirdnetctl">weirdnetctl 0.1.0</a>): signed scheme records, reserved <code>weirdnet…</code> prefixes on a signed canonical list, and a resolver that
never hands a link to an unknown app without asking.</li>
<li><b>Device linking</b> <span class="tag shipped">shipped</span> (<a href="/crates/device-link">weirdnet-device-link 0.1.0</a>): moving a user identity to another device over a QR offer, a 6-digit code check and a sealed transfer.</li>
<li><b>Sandboxed extensions</b> <span class="tag shipped">shipped</span> (<a href="/crates/ext">weirdnet-ext 0.1.0</a>, with weirdnet-ext-proto and weirdnet-ext-sdk): extensions
run out of process with no network or files beyond what the user grants (Landlock and seccomp on Linux, the sandbox on
macOS).</li>
<li><b>Relay wake-up path</b> <span class="tag shipped">shipped</span> (<a href="/crates/relay">weirdnet-relay 0.3.0</a>): phones without APNs or FCM keep a stream open to their home relay, and trusted peers or a push service wake them with sealed, fixed-size payloads the relay can't read.</li>
<li><b>Update announcements</b> <span class="tag shipped">shipped</span> (<a href="/crates/update">weirdnet-update 0.2.0</a>, carried by weirdnet-relay 0.4.0): signed news of an update, carried by relays for the orgs they trust and checked by every device against its own root before it fetches anything.</li>
<li><b>Dynamic DNS for your own relay</b> <span class="tag shipped">shipped</span> (<a href="/crates/relay">weirdnet-relay 0.5.0</a>): through Grindvakt, a self-hosted relay keeps its name and <code>_dnsaddr</code> records pointed at its public address on DigitalOcean or DNSimple, never deleting a record and changing nothing when the zone is ambiguous.</li>
</ul>

<h2 id="security">Security boundaries</h2>
<p>From <code>weirdnet-net</code>’s security notes. The crate enforces: signatures on offers, answers, certificates and
revocations; answers bound to their offer; sealed messages bound to their exchange, peers and direction; offers kept only
from the node that signed them; and profiles that don’t mix.</p>
<p>It leaves to the application: whether to answer an offer, who may do what over an exchange, which users are trusted,
what an invitation grants, every limit on what peers may store or ask for, and keeping secrets encrypted at rest.</p>
<div class="callout warn">Nobody has audited weirdnet-net yet. Read <code>SECURITY.md</code> in each repository before relying on it.</div>
''';
