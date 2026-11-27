/// The long-form guide on each crate page: what the crate brings, how it works, its feature
/// flags, and how to install it when it is a program. Written from each crate's README,
/// CHANGELOG, Cargo.toml and source (see the crate's repository). Usage examples live in
/// `tool/examples/` and are generated into `examples.dart`.
///
/// Don't list gaps, planned work or "coming soon" items here: public pages describe what has
/// shipped (WeirdBrains public-content rules, 2026-11-20).
library;

class Guide {
  const Guide({
    required this.brings,
    required this.works,
    this.features = const [],
    this.install = '',
  });

  /// What problems it solves, when to use it (HTML).
  final String brings;

  /// Architecture, data flow, protocols and crypto (HTML).
  final String works;

  /// Cargo feature flags (HTML bullets). Empty: the crate has none.
  final List<String> features;

  /// Shell commands for crates that are programs (escaped by the page).
  final String install;
}

const guides = <String, Guide>{
  'net': Guide(
    brings: r'''
<p>Use weirdnet-net when devices need to find each other and talk without a server in the middle. It covers what every
peer-to-peer app would otherwise build itself:</p>
<ul>
<li><b>Reaching a device anywhere</b>: direct connections, hole punching, and relay circuits as the fallback, with streams
that move between them without losing a byte.</li>
<li><b>Inviting someone safely</b>: a signed offer as a link or QR code, an answer, and a ten-digit short code both people
compare. After that, messages are sealed to that exchange.</li>
<li><b>Identities that span devices</b>: one user key per person, one node key per device, certificates and revocations.</li>
<li><b>Finding a person by who they are</b>: signed peer records by user id, <code>_weirdnet.&lt;name&gt;</code> DNS
bindings, and private-site locators only trusted peers can read.</li>
<li><b>App traffic</b>: request/response with the app's own types, unbounded byte streams, HTTP-like app calls for
<code>weirdnet-&lt;app&gt;://</code> URLs, content transfer by BLAKE3 hash, membership and requests to join.</li>
</ul>
<p>The app keeps its own records, storage and policy: who to trust, what an invitation grants, what peers may store.</p>
''',
    works: r'''
<h3>The node</h3>
<p><code>Node&lt;Q, R&gt;</code> runs a libp2p swarm on its own thread; the handle is blocking, with
<code>request_async</code>, <code>connect_async</code> and <code>dial_async</code> for async callers on any executor.
Transports: TCP, QUIC, WebSocket over TLS on 443 (<code>/tls/ws</code>, <code>/wss</code>) and an in-memory transport for
tests, with Noise and Yamux. Behaviours: mDNS, Kademlia, identify, ping, a relay client, an opt-in relay server
(<code>NodeConfig::relay_limits</code>), DCUtR hole punching and AutoNAT. Requests are the app's <code>Q</code> and answers its
<code>R</code>, CBOR on the wire, answered by a <code>Handler</code>.</p>
<p>Every identifier on the wire or under a signature comes from a <code>Profile</code>. <code>WEIRDNET</code> is the default
(<code>/weirdnet/net/2</code>, <code>wnet-x1-offer:</code>, port 4747). An app with nodes already in the field passes its own
profile, so nothing changes for them. Apps share the network and add their own protocol ids
(<code>/morph/...</code>, <code>/muninn/...</code>).</p>

<h3>Discovery and reachability</h3>
<ol>
<li>With <code>DiscoveryMode::Enabled</code> (the default) a node finds peers by mDNS on the LAN and Kademlia from bootstrap
nodes, and finds relays by the <code>/weirdnet/relay/1</code> provider key. <code>DiscoveryMode::Disabled</code> (0.6.0) turns
mDNS and Kademlia off; the node still listens, uses configured relays and dials <code>PeerHint</code>s
(<code>NodeConfig::peers</code>, <code>Node::add_peer</code>). A hint is an address book entry, not trust; the app stores the
list with <code>encode_peers</code>/<code>decode_peers</code>.</li>
<li>AutoNAT tells the node whether it is reachable. If not, it reserves a slot on a relay and is reachable at
<code>…/p2p/RELAY/p2p-circuit/p2p/NODE</code>.</li>
<li>When a peer connects through the circuit, DCUtR tries a direct path. Streams move to it, and back to the relay if it
drops (<code>Stream::path</code>, <code>Stream::moves</code>, <code>Node::paths</code>).</li>
<li><code>Node::events()</code> and <code>Node::watch_status()</code> report listeners, connections and their path,
reservations and the NAT verdict. Apps call <code>pause</code>/<code>resume</code> around the background and
<code>network_changed</code> on a new network.</li>
</ol>

<h3>Identity, invitations and sealing</h3>
<p>Each device has an Ed25519 node key; a person's user key certifies it (<code>NodeCert</code>) and can revoke it. An
invitation is an offer signed by the node key with a fresh X25519 key, a scope and an expiry; the answer carries the other
side's X25519 key. Both derive the exchange key (through <code>weirdnet-keys</code>), a ten-digit short code and a
fingerprint to compare out of band. Sealed messages are bound to the exchange, the two peers and the direction, and
<code>sealed::serve</code> answers only the exchange's own, Noise-authenticated peer. <code>invite</code> automates the
flow: offers answered on the spot or kept for the owner, crossing offers settled on one exchange, trust on first use and
impostor warnings.</p>
<p>Invitation links go on the app's own scheme. <code>WEIRDNET</code> has no link scheme (0.7.0), so
<code>Profile::link</code> returns an error until the app sets <code>join_link</code>, <code>answer_link</code> and
<code>link_mark</code> to its <code>weirdnet-&lt;app&gt;://</code> scheme. Bare <code>weirdnet://</code> is reserved
(<code>RESERVED_LINK_SCHEME</code>): <code>link</code> never makes a link on it and <code>parse_token</code> refuses one.
Tokens (<code>wnet-x1-offer:…</code>) work with any profile. Upgrading from 0.6: set the app's scheme and handle the
<code>Result</code> from <code>link</code>.</p>

<h3>Names and locators</h3>
<p>A <code>PeerRecord</code> (addresses, relay circuits, home relay, <code>seq</code>, at most a day's expiry) is signed by the
node key and chained to the user key by the certificate. It goes to the home relay's names server
(<code>/weirdnet/names/2</code>) and, only while the device hosts something, to the DHT under
<code>SHA-256("weirdnet/peer/" + user id)</code>. Storing nodes accept it only with a valid signature, an unrevoked
certificate, no expiry and a higher <code>seq</code>; a signed <code>Withdrawal</code> removes it. Private sites publish a
<code>LocatorRecord</code> instead: sealed under per-site locator keys, signed by the locator key (never the user key), under a
DHT key that changes every UTC day, so storing nodes learn nothing about owner, site or addresses.</p>

<h3>App calls, streams and content</h3>
<ul>
<li><b>App calls</b> (<code>/weirdnet/app/1</code>): <code>Node::serve_app</code>, <code>resolve_app</code> (names servers, then
the DHT) and <code>app_call</code>. One stream per call: a CBOR head (method, path, headers), body frames ending with an empty
one, and a response head. Heads are capped at 16 KiB, bodies are uncapped unless <code>app_body_max</code> is set, and a call
idle for 60 s ends.</li>
<li><b>Streams</b>: <code>Node::accept_streams(protocol, Limits)</code> and <code>open_stream</code>; a <code>Stream</code> is
<code>AsyncRead</code>/<code>AsyncWrite</code> and blocking <code>Read</code>/<code>Write</code>, with a window of
unacknowledged bytes and per-protocol limits; a stream both sides have ended stops counting against
<code>Limits::max_streams</code> (0.8.3). Sealed streams are bound to an exchange.</li>
<li><b>Content</b> (<code>/weirdnet/content/1</code>): content-defined chunks of 16 to 256 KiB addressed by BLAKE3; a file's
root is the hash of its index, so an edit moves only the chunks around it. A user-signed <code>Manifest</code> maps paths to
roots. <code>fetch</code> pulls from one or several sources and checks every chunk; <code>fetch_range</code> gets a byte range;
public content goes in the DHT as provider records.</li>
<li><b>Membership</b>: owner-signed <code>Membership</code>s with a role, <code>MemberRevocation</code>s, presenting one on a
stream (<code>check_presented</code> ties it to the node speaking), and signed <code>JoinRequest</code>s on
<code>/weirdnet/join/1</code> with rate limits and a host queue.</li>
<li><b>Public HTTPS</b>: <code>Ingress</code> forwards TLS by SNI to hosts without a public address over
<code>/weirdnet/ingress/1</code>; TLS ends on the host, and each name needs the owner's signed grant and a
<code>_weirdnet</code> DNS binding. <code>dnsaddr_record</code> builds the <code>_dnsaddr</code> TXT record for Grindvakt.</li>
</ul>
<p>Settings on <code>NodeConfig</code>: <code>request_max</code> (8 MiB), <code>response_max</code> (256 MiB),
<code>request_timeout</code> (60 s), <code>relay_limits</code>, <code>discovery</code>, <code>peers</code>, <code>wss</code>,
<code>names_server</code>, <code>dns_servers</code>, <code>app_header_max</code>, <code>app_body_max</code>,
<code>app_idle_timeout</code>. CI runs nodes in Linux network namespaces behind NAT routers (<code>harness/netns.sh</code>).</p>

<h3>Android (0.8.1)</h3>
<p>On Android, hickory-resolver (libp2p's DNS transport inside the node) reads the system DNS servers from the ConnectivityManager
through <code>ndk-context</code>, and panics if nothing initialized it, which takes down any node that dials a real network.
The app initializes it once at startup, before any node starts, from a Kotlin <code>external fun</code> that the
<code>android_context_init!</code> macro exports:</p>
<pre><code>// Rust, in the app's bridge crate (expands to nothing off Android):
weirdnet_net::android_context_init!(Java_org_example_myapp_RustContext_nativeInit);

// Kotlin, org.example.myapp.RustContext, called before anything touches Rust:
object RustContext {
    init { System.loadLibrary("myapp_bridge") }
    @JvmStatic external fun nativeInit(context: Context)
}</code></pre>
<p>The macro takes the full JNI name (<code>Java_</code>, the package with <code>_</code> for <code>.</code>, the class, the method).
<code>android::init_context(env, context)</code> does the work: it keeps a global reference to the application Context for the
life of the process, acts only on the first call, and returns whether the context is set. Other crates that reach Android
services through <code>ndk-context</code> (a keystore, say) rely on the same call.</p>

<h3>Moving to 0.8.0</h3>
<p>0.8.0 changes the wire. Requests and responses (<code>Node&lt;Q, R&gt;</code> and the names protocol) are written by a codec
of the crate's own, <code>wire</code> (<code>to_vec</code>, <code>from_slice</code>, <code>Codec</code>). Every byte field,
whether a <code>Vec&lt;u8&gt;</code>, a <code>[u8; N]</code> or any non-empty sequence of <code>u8</code>, is one CBOR byte string
instead of an array of integers, with or without <code>serde_bytes</code>; everything else is laid out as before. A 240 KiB byte
field takes 245,771 bytes on the wire instead of 468,352, about half. Reading refuses truncated input, trailing bytes, lengths
past the end, indefinite lengths, tags and nesting deeper than <code>MAX_DEPTH</code>.</p>
<p><b>Old and new nodes cannot talk to each other.</b> <code>WEIRDNET</code> moves to <code>/weirdnet/net/2</code> and
<code>/weirdnet/names/2</code> (were <code>/1</code>), so a 0.8 node and an older one fail to negotiate instead of failing to
decode. Upgrade every node that talks to the others together. An app with its own <code>Profile</code> bumps its
<code>protocol</code> and <code>names</code> ids (for example <code>/myapp/net/1</code> to <code>/myapp/net/2</code>) in the
same release.</p>
<p>Types that already use <code>serde_bytes</code> or a bytes visitor keep working. A <code>PeerId</code> (or another type that only
accepts <code>visit_bytes</code>) inside an internally tagged, adjacently tagged or untagged enum, or a <code>flatten</code>ed
struct, cannot be read: carry it as a string there. Nothing under a signature changes: certificates, records and tokens are
signed over JSON. weirdnet-sync 0.5.0, weirdnet-relay 0.6.0 and weirdnet-device-link 0.2.0 are on net 0.8, and the <a href="https://weirdbrains.com">WeirdBrains</a> public
relay runs weirdnet-relay 0.6.0, so its names server answers 0.8 nodes only.</p>
''',
  ),
  'service': Guide(
    brings: r'''
<p>Use weirdnet-service when one server should serve many apps: typed calls and live feeds that desktop, terminal, mobile
and MCP clients reach over <a href="/crates/net">weirdnet-net</a> streams, with every call and subscription authorized
first. The pattern comes from the model-node protocol in <a href="/crates/backends">weirdnet-backends</a>.</p>
''',
    works: r'''
<h3>Services</h3>
<p>Implement <code>Service</code> with request and response types shared by server and clients. <code>access</code> names
the <code>Access</code> a request needs (a permission, optionally <code>on</code> a resource such as an account), and
<code>call</code> gets the <code>Admitted</code> caller. A session is one stream: credentials once, then concurrent calls
with ids, cancellation, per-call deadlines, and a bounded queue that answers <code>Busy</code> when full.</p>
<h3>Authorization</h3>
<p>The hook returns who was admitted: the user, device roles and the role on the resource. <code>RosterAuth</code>
(<code>roster</code>) admits the user's own linked devices with the device roles the user granted them, from the
<a href="/crates/sync">weirdnet-sync</a> 0.8 roster. <code>MembershipAuth</code> (<code>access</code>) checks
owner-signed memberships from weirdnet-net and roles from <a href="/crates/access">weirdnet-access</a> in its
enforcement order. <code>AllOf</code>, <code>AnyOf</code>, <code>AllowAll</code> or a closure combine or replace them.</p>
<h3>Live feeds</h3>
<p>A <code>Hub</code> keeps each topic's state and a sequence number. Subscribers get a snapshot, then deltas; after a
reconnect they resume from their last position, or get a fresh snapshot when the gap is too old or the server restarted.
Publishing never waits: slow subscribers have their deltas coalesced by key and are re-snapshotted (or told to resume)
when their queue overflows. Throttling, heartbeats and periodic re-authorization are optional, so a revoked device loses
its stream. <code>Live</code> is a local copy of a topic's state that reconnects and resumes on its own.</p>
<h3>Protocols</h3>
<p><code>ProtocolId</code> (<code>/myapp/api/2</code>) versions are served side by side, and
<code>Client::session_any</code> picks the newest the server has. The core runs over any <code>Channel</code>; the
<code>net</code> feature adds <code>Server</code>, <code>NetDialer</code> and stream channels. The
<a href="https://github.com/WeirdBrains/weirdnet-service/blob/main/docs/protocol.md">protocol notes</a> describe the
messages.</p>
''',
    features: [
      '<code>net</code> (default): <code>Server</code>, <code>NetDialer</code>, stream channels and credential helpers over weirdnet-net 0.8.',
      '<code>roster</code>: <code>RosterAuth</code> (weirdnet-sync 0.8).',
      '<code>access</code>: <code>MembershipAuth</code> (weirdnet-access).',
    ],
  ),
  'relay': Guide(
    brings: r'''
<p>weirdnet-relay is the program <a href="https://weirdbrains.com">WeirdBrains</a> runs at <code>relay.net.weirdbrains.com</code>, and the one you run if you want
your own. It gives phones and machines behind NAT a slot to be reached at, gives new nodes a DHT to bootstrap from, and
carries the small things a sleeping phone needs: names, wake-ups and update news.</p>
<p>Running your own relay is optional; Weirdnet apps start with the <a href="https://weirdbrains.com">WeirdBrains</a> relays. See <a href="/relay">Run a relay</a>
for the packages and the step-by-step setup.</p>
''',
    works: r'''
<ul>
<li><b>Circuit relay v2 with no caps by default</b>: no reservation or circuit counts, no duration or byte limit, no rate
limiters. <code>limits.preset = "libp2p"</code> starts from libp2p's defaults (2 minutes and 128 KiB per circuit).</li>
<li><b>Bootstrap</b>: Kademlia in server mode, identify, ping, AutoNAT and DCUtR on the Weirdnet profile
(<code>/weirdnet/kad/1</code>, <code>/weirdnet/id/1</code>, port 4747), and the <code>/weirdnet/relay/1</code> provider key so
nodes find relays they weren't configured with. Muninn nodes, which keep <code>/muninn/...</code> protocols, can still reserve
slots given the relay's full address.</li>
<li><b>One encrypted database</b>: the node key, peers seen and the names server's records, in SQLCipher through
<code>weirdnet-storage</code>. The 32-byte key comes from <code>--db-key-file</code> or the systemd credential
<code>db-key</code>; lose it and the relay gets a new peer id.</li>
<li><b>Names server</b> (<code>/weirdnet/names/2</code>): signed peer records and withdrawals, checked by weirdnet-net, kept
until they expire.</li>
<li><b>Wake path</b> (<code>[wake]</code>, on by default): phones without APNs or FCM keep a stream open on
<code>/weirdnet/wake/1</code> (weirdnet-push's <code>relaywake</code>); sealed payloads are passed on unread, held briefly, and
capped per handle.</li>
<li><b>Update announcements</b> (<code>[updates]</code>, from 0.4.0): the latest signed announcement per org, app and channel
on <code>/weirdnet/updates/1</code>, only for orgs in <code>roots</code>, following <code>upstream</code> relays and kept across
restarts. A relay can withhold news but can't make an update acceptable.</li>
<li><b>WebSocket over TLS and site forwarding</b> (<code>[wss]</code>, <code>[forwarding]</code>, off by default): HTTPS-only
networks dial <code>/tls/ws</code> on 443, and the relay can be a public SNI-passthrough ingress; <code>revoke-site</code>
stops a site.</li>
<li><b>Dynamic DNS</b> (<code>[ddns]</code>, from 0.5.0, off by default): through grindvakt-core, keeps <code>A</code>,
<code>AAAA</code> and <code>_dnsaddr</code> records current at DigitalOcean or DNSimple; never deletes records, and changes
nothing when the zone is ambiguous.</li>
<li><b>Info page</b>: HTML at <code>/</code>, JSON at <code>/.well-known/weirdnet-relay.json</code>, <code>/healthz</code>, and
the same document on <code>/weirdnet/relay/info/2</code>.</li>
</ul>
<p>Commands: <code>run</code> (default), <code>id</code>, <code>info</code>, <code>check-config</code>, <code>gen-key</code>,
<code>ddns [--apply]</code>, <code>revoke-site</code>, <code>unrevoke-site</code>, <code>revoked-sites</code>. Every config key
has a flag and a <code>WEIRDNET_RELAY_*</code> variable; flags win over the environment, which wins over the file. The
systemd unit runs it as a dynamic user with no capabilities and a <code>@system-service</code> syscall filter. 0.6.0 is built
on weirdnet-net 0.8.0.</p>
<h3>Moving to 0.6.0</h3>
<p>0.6.0 moves to weirdnet-net 0.8, whose requests carry byte fields as CBOR byte strings. The names server is now
<code>/weirdnet/names/2</code> and the info request <code>/weirdnet/relay/info/2</code> (were <code>/1</code>), so nodes on
weirdnet-net 0.7 or earlier can no longer register or look up names on a 0.6 relay; they fail to negotiate rather than
misread. Circuits, Kademlia, identify, the wake path and update announcements are unchanged, so older nodes still reserve
slots and bootstrap. Upgrade the relay with your 0.8 apps. The config, the database and the peer id carry over.</p>
''',
    install: r'''# Packages for Debian/Ubuntu, Fedora/openSUSE and Arch are on each GitHub release (see Run a relay).
cargo install weirdnet-relay
umask 077; weirdnet-relay gen-key > db-key
weirdnet-relay --db-key-file db-key --state-dir ./state \
    --external /dns4/relay.example.com/tcp/4747 --contact abuse@example.com''',
  ),
  'tls': Guide(
    brings: r'''
<p>Certificates for any Weirdnet host without each app writing its own ACME client. It replaces the ACME code that was
separate in Mouser, Muninn, itcmdr and TAUR, and it never trades availability for a certificate: a failed order keeps the
last certificate in service and never falls back to plain HTTP.</p>
<p>Use it when an app terminates TLS itself with rustls: a relay on 443, a self-hosted site behind Weirdnet forwarding, a
service like TAUR. HTTP servers and port forwarding stay in the app. Muninn orders its certificates through it.</p>
''',
    works: r'''
<ol>
<li><b>Order</b>: <code>Acme</code> keeps an account per directory in the store (Let's Encrypt production or staging, or any
RFC 8555 directory), with several names per certificate, wildcards and ACME profiles. From 0.2.0,
<code>AcmeConfig::profile_optional</code> orders with the CA's default when the profile is refused. From 0.3.0, names a
public CA refuses (<code>localhost</code>, IP addresses, all-digit top labels) fail validation unless
<code>AcmeConfig::private_names</code> is set for a private CA.</li>
<li><b>Challenge</b>: TLS-ALPN-01 is answered by the resolver on your port 443; HTTP-01 from an <code>Http01Board</code>
(served by <code>serve_http01</code> or your router); DNS-01 through the <code>DnsChallenge</code> trait: a hook command
(it gets <code>WEIRDNET_TLS_ACTION</code>, <code>WEIRDNET_TLS_DOMAIN</code>, <code>WEIRDNET_TLS_NAME</code> and
<code>WEIRDNET_TLS_TXT</code>, and from 0.3.0 the same under an app's own prefix with <code>HookDns::with_prefix</code>), a
manual prompt, or a grindvakt-core provider. While the app's own listener isn't running, <code>Acme::serve_challenge</code>
answers TLS-ALPN-01 or HTTP-01 on a listener of its own.</li>
<li><b>Store</b>: the <code>CertStore</code> trait with <code>FileStore</code> (files 0600 in directories 0700, atomic
writes), <code>MemoryStore</code>, or <code>SqlStore</code> in an encrypted weirdnet-storage database.
<code>Acme::import</code> copies an app's earlier account, certificate and state in, never overwriting.</li>
<li><b>Serve</b>: the <code>Resolver</code> picks a certificate per name, in the order pinned (internal names, a private
CA), the user's own, ACME, then self-signed, skipping expired ones, with a default for handshakes without SNI (the ACME certificate with <code>Acme::with_default_cert</code>). It swaps
certificates without a restart; <code>server_config</code> hands a rustls config to tokio-rustls or hyper.</li>
<li><b>Renew</b>: at a point in the CA's ACME Renewal Information window (RFC 9773) with <code>replaces</code>, else two
thirds into the lifetime, so shorter certificate lifetimes need no change. Failures back off from an hour to a day; a forced
renewal within a day of the last issue is refused (<code>Acme::trigger_renewal</code> asks the running renewer for one).
<code>Acme::watch</code> gives a typed <code>Status</code>, and <code>acme::schedule</code> reads the next renewal from the
store alone, for status commands.</li>
</ol>
<p>Linux, macOS and Windows are tested in CI; Android (aarch64, API 26) and iOS (aarch64) build.</p>
''',
    features: [
      '<code>ring</code> (default): rustls, rcgen and instant-acme on ring.',
      '<code>aws-lc-rs</code>: the same on aws-lc-rs; wins when both are on.',
      '<code>grindvakt</code>: DNS-01 through grindvakt-core providers. They can’t delete records, so the <code>_acme-challenge</code> TXT is overwritten on each order and left in place.',
      '<code>storage</code>: <code>SqlStore</code> in a weirdnet-storage (SQLCipher) database.',
      '<code>testing</code>: <code>testing::MockCa</code>, an in-process ACME CA that checks the real HTTP-01, TLS-ALPN-01 and DNS-01 answers and serves ARI.',
    ],
  ),
  'keys': Guide(
    brings: r'''
<p>One reviewed place for key material, so apps don't each pick their own KDFs, ciphers and backup formats. It covers the
whole life of a key: making it, showing it as 24 words, splitting it among custodians, deriving and sealing with it,
wrapping a database key under it, rotating and recovering. Everything is built on RustCrypto, dalek, BIP39, vsss-rs and age;
nothing invents a cipher, KDF or format.</p>
''',
    works: r'''
<h3>Profiles</h3>
<p>Every label (HKDF info, associated data, shard prefix, claim salt) comes from a <code>Profile</code>;
<code>Profile::WEIRDNET</code> is the default. Envelopes record their format, so a file written under one profile is refused
under another. An app with existing data defines a profile with its old labels; nothing is migrated or rewrapped
automatically.</p>
<h3>Primitives</h3>
<ul>
<li><code>Key32</code>: 256 bits, wiped on drop, never printed (<code>hex</code> returns a zeroizing string).</li>
<li><code>words</code>: BIP39, 24 words. <code>shards</code>: Shamir k-of-n with a checksummed text form (the checksum
catches typos, not forgery; a forged share combines into a wrong key that verification rejects).</li>
<li><code>kdf</code>: HKDF-SHA256 and Argon2id. <code>aead</code>: XChaCha20-Poly1305 <code>Sealed</code> with associated data.
<code>password</code>: Argon2id password sealing and claim tags. <code>mac</code>: HMAC-SHA256 with constant-time checks.
<code>exchange</code>: X25519 agreement with a contributory check, and HKDF exchange keys (what weirdnet-net's invitations
use).</li>
</ul>
<h3>The keyring</h3>
<p>Envelope encryption for a database key (the DEK). The DEK is wrapped twice: by a versioned service key and by a key
derived from the master key; the service key is in turn wrapped by a password. Operations: init, unlock, rotate, rekey (with
undo on failure), recover from the master key, verify and export. Files and the database come in through the
<code>KeyFiles</code> and <code>EncryptedDatabase</code> traits the app implements, so this crate never opens a database
(weirdnet-storage applies the key).</p>
<h3>Custody and exports</h3>
<p><code>dark</code> seals shards with a shard password for custodians, with a claim tag to find them again (weirdnet-net
carries the blobs as opaque bytes). <code>agefile</code> writes password age files for exports; from 0.1.1 reading
(<code>decrypt</code>, <code>read_maybe_age</code>, <code>is_age</code>) accepts ASCII-armored files as well as binary ones.</p>
''',
    features: ['<code>age</code> (default): password-encrypted (scrypt) age files, for keyring exports and <code>read_maybe_age</code>.'],
  ),
  'storage': Guide(
    brings: r'''
<p>Encrypted SQLite for apps that bring their own schema. It does the parts that are easy to get subtly wrong: applying a
raw SQLCipher key and proving it worked, never silently opening unencrypted, private file modes, migrations in one
transaction, nested savepoints, online snapshots, and converting an old plaintext file in place.</p>
<p>It knows no schema and no brand, and it never derives, wraps, stores or exports a key: key management is the caller's
(for example <a href="/crates/keys">weirdnet-keys</a>' keyring).</p>
<p>Optional features add a hot standby with failover, for a database that has to survive losing a machine, and
long-term retention, for records that must be kept for years and shown to be unchanged.</p>
''',
    works: r'''
<ul>
<li><b>Open</b>: <code>open</code>, <code>open_readonly</code> and <code>open_in_memory</code> take a raw 32-byte key
(<code>RawKey</code>), apply it with <code>PRAGMA key</code> and verify it: a wrong key is <code>StorageError::WrongKey</code>,
and SQLite built without SQLCipher is <code>StorageError::NoCipher</code>, so a key is never ignored. Folders are 0700, files
0600, and key literals are zeroized.</li>
<li><b>Migrate</b>: <code>migrate(conn, migrations, upto, applied)</code> applies the ones not yet recorded in
<code>schema_version</code>, all in one transaction, calling <code>applied</code> after each for data upgrades. Every call sets
the pragma policy: foreign keys on, WAL, <code>synchronous = NORMAL</code>.</li>
<li><b>Units of work</b>: <code>savepoint</code> and <code>begin</code>/<code>release</code>/<code>rollback</code>, which
nest.</li>
<li><b>Keys over time</b>: <code>rekey</code> re-encrypts in place; <code>encrypt_plaintext_in_place</code> converts a
plaintext file and verifies the copy before it replaces the original.</li>
<li><b>Files and copies</b>: <code>files</code> writes private files through a side file and a rename;
<code>snapshot_to</code> makes an online copy keyed the same way.</li>
<li><b>Row change log</b> (<code>sync</code> feature): triggers on the tables you register keep a change log; rows are read
and written by primary key with a codec and hash, and a three-way take/keep/conflict decision. This is a local log, not the
<a href="/crates/sync">weirdnet-sync</a> protocol.</li>
</ul>
<h3>Replication and failover</h3>
<ul>
<li><b>Log</b>: <code>Primary::write</code> runs a transaction and records every row change it made (SQLite's session
extension) as one log entry in the same transaction, so the data and the log never disagree. Entries are hash-chained and
the log is append-only. Schema changes go through <code>Primary::schema</code> and <code>Primary::migrate</code>.</li>
<li><b>Hot standby</b>: a <code>Standby</code> pulls entries from the primary or another standby, checks the chain and
applies each page in one transaction; a conflict stops it rather than letting it drift. Every node has its own SQLCipher
key, and the log lives inside the encrypted database.</li>
<li><b>Fencing</b>: every entry carries the epoch of the primary that wrote it. A standby accepts only the epoch it has
applied, or an epoch entry that raises it, and refuses a source older than the newest epoch it has seen. A primary checks
its <code>Leadership</code> before and after each write, so once its term is gone it can't commit.</li>
<li><b>Failover</b>: <code>Manual</code> for operator-driven failover, or a <a href="/crates/sync">weirdnet-sync</a>
majority-vote lease (<code>lease</code> feature) whose term becomes the epoch. <code>Replica::tick</code> promotes a standby
that gains leadership and steps a primary down when it loses it.</li>
<li><b>Fail-back</b>: a returning ex-primary finds where it diverged, rewinds its unreplicated entries (kept for audit)
and follows the new primary.</li>
<li><b>Over the network</b> (<code>replication-service</code> feature): <code>ReplicationService</code> serves the log as a
<a href="/crates/service">weirdnet-service</a> service, and <code>follow</code> and <code>rejoin</code> drive a standby over
a session. On <a href="/crates/net">weirdnet-net</a>, <code>RosterAuth</code> admits linked devices or roster grants with
the <code>storage.replicate</code> permission.</li>
</ul>
<p>Replication is asynchronous: a failover can lose the old primary's last unreplicated writes, which that node rewinds
and keeps. Replicated tables need a primary key, app triggers should be guarded with <code>REPLAYING</code> so a standby
doesn't run them twice, and a rewind past a schema change is refused (reseed that node from a snapshot).</p>
<h3>Retention</h3>
<ul>
<li><b>Policies</b>: <code>retention::protect</code> stores a minimum age, for example <code>Period::years(7)</code>, and
adds triggers: deleting a younger row aborts, and so does updating one in an immutable table. Policies can only be
strengthened.</li>
<li><b>Seals</b>: <code>seal</code> hashes new rows into an append-only, hash-chained ledger; <code>verify</code>
recomputes the chain and every row and reports changed, missing and unsealed rows; <code>head</code> gives the chain head
to publish or sign.</li>
<li><b>Purge and archive</b>: <code>purge_expired</code> removes only rows past the minimum age and records them.
<code>archive_to</code> copies sealed rows into a separate SQLCipher file with its own key for cold storage, refusing rows
that no longer match their seal; the archive keeps the policy, and <code>verify_archive</code> checks it later.</li>
<li><b>Guard</b>: <code>guard</code> makes a connection refuse <code>DROP</code> and <code>ALTER</code> of protected tables,
their triggers and the internal tables.</li>
</ul>
<p>With replication, apply a policy through <code>Primary::schema</code> and seal inside <code>Primary::write</code>; the
policy and the ledger reach every standby. Triggers and the guard stop the app's own code and SQL; someone holding the key
can still rewrite the file, which <code>verify</code>, replicas and archives make evident.</p>
<p>CI tests Linux, macOS and Windows, builds Android (aarch64, armv7, x86_64, API 26) and iOS, and reports binary size: on
x86_64 Linux the vendored build adds about 5.4 MiB, the system-crypto build about 1.1 MiB.</p>
''',
    features: [
      '<code>sync</code> (default): the row change log; adds serde, serde_json, sha2 and base64.',
      '<code>replication</code>: the <code>replicate</code> module; adds SQLite\'s session extension, serde and sha2.',
      '<code>replication-service</code>: <code>replicate::service</code>; adds <a href="/crates/service">weirdnet-service</a> without default features.',
      '<code>lease</code>: <code>Leadership</code> for weirdnet-sync\'s <code>Elector</code>; adds <a href="/crates/sync">weirdnet-sync</a>.',
      '<code>retention</code>: the <code>retention</code> module; adds SQLite\'s authorizer hooks and sha2.',
      '<code>vendored-openssl</code> (default): SQLCipher with OpenSSL built from source and linked statically (Android has no system libcrypto for apps). Without it SQLCipher uses CommonCrypto on Apple targets and the system libcrypto elsewhere. For iOS: <code>default-features = false, features = ["sync"]</code> and set <code>IPHONEOS_DEPLOYMENT_TARGET</code>.',
    ],
  ),
  'vault': Guide(
    brings: r'''
<p>Use weirdnet-vault when a server holds other people's credentials: exchange or provider API keys for many accounts,
tokens, passwords. It keeps them sealed at rest, lets code use a credential without ever handing it back, lets several
approved identities retrieve one when they need to, rotates without downtime, keeps dry-run callers away from live
credentials, and records every attempt in an audit log you can verify.</p>
<p>The API is generic: scopes, environments, roles and grants are yours to name. Key management comes from
<a href="/crates/keys">weirdnet-keys</a> and the database from <a href="/crates/storage">weirdnet-storage</a>.</p>
''',
    works: r'''
<h3>Keys and sealing</h3>
<p>The vault is a SQLCipher database keyed by a data key. Inside it, a random entry key is wrapped by a key derived
from the data key, and every version of every value is sealed with XChaCha20-Poly1305 under the entry key, with the
secret id, version, environment and scope as associated data, so a sealed value copied into another row won't open.
A rekey wraps the entry key again; values aren't resealed. The data key comes from a password keyring
(<code>Vault::init</code>, then <code>unlock</code> or <code>unlock_with_master</code>, with recovery words and shards),
a <code>KeyStore</code> (<code>open_with_keystore</code>), or a key you hold (<code>open_with_key</code>).
<code>open_in_memory</code> is for tests. Plaintext is a zeroizing <code>Plaintext</code> that can't be cloned, printed
or serialized; <code>SecretMeta</code> (name, kind, labels, scope, versions) is the only secret type that serializes.</p>
<h3>Checks on every call</h3>
<ol>
<li><b>Environment</b>: a caller bound to <code>Environment::Test</code> may only list and read metadata of a live
secret.</li>
<li><b>Grant</b>: <code>Use</code> and <code>Reveal</code> need an unexpired grant for that identity on the secret or a
scope above it.</li>
<li><b>Authorize</b>: your hook (any <code>Fn(&amp;AccessRequest) -&gt; Decision</code>, or <code>RolePolicy</code>).</li>
<li><b>Options</b>: <code>VaultOptions</code> can turn <code>Reveal</code> off for the whole vault.</li>
<li><b>Audit</b>: allowed, denied and failed calls are all recorded.</li>
</ol>
<p><code>RolePolicy::with_example_roles()</code> defines viewer (list and metadata), trader (viewer plus
<code>Use</code>), auditor (viewer plus <code>Audit</code>) and admin (every action), assigned per scope; define your
own with <code>define_role</code>.</p>
<h3>Using and retrieving</h3>
<p><code>use_secret</code> passes the value to a closure inside the process and returns only the closure's result.
<code>reveal</code> returns it to an approved identity, and <code>reveal_sealed</code> seals it to the recipient's X25519
key. Admins add and remove grants with <code>grant</code> and <code>revoke</code>; several identities can hold
<code>Reveal</code> on the same secret, and a revoke takes effect at once.</p>
<h3>Rotation</h3>
<p><code>stage_rotation</code> adds a pending version while readers keep the active one. Try it with
<code>use_version(…, Which::Pending, …)</code>, then <code>promote</code> it (the old value stays as previous) or
<code>discard_pending</code>; after promoting, <code>revert</code> rolls back and <code>retire_previous</code> removes
the old value. Every step is audited.</p>
<h3>Audit log</h3>
<p>Each record holds the actor, scope, secret id and version, action, outcome and time, and never a value. Records are
chained with BLAKE3 and the table refuses updates and deletes. <code>audit</code> queries by time range, scope, actor,
action and outcome; <code>verify_audit</code> checks the whole chain and returns its head.</p>
<h3>Backups</h3>
<p><code>snapshot_to</code> writes an online copy keyed with the same or a new key.</p>
''',
    features: [
      '<code>tokio</code> (default): <code>AsyncVault</code>.',
      '<code>vendored-openssl</code> (default): builds SQLCipher\'s OpenSSL from source (weirdnet-storage).',
      '<code>keychain</code>: <code>KeychainStore</code> for the macOS Keychain, Windows Credential Manager and Secret Service.',
      '<code>sync</code>: <code>SyncSecrets</code> over any <a href="/crates/sync">weirdnet-sync</a> <code>SecretStore</code>; the vault\'s key stores implement <code>SecretStore</code>.',
      '<code>access</code>: <code>access::AccessAuthorizer</code> over <a href="/crates/access">weirdnet-access</a> and its <code>vault.*</code> permissions.',
      '<code>mcp</code>: <code>mcp::VaultTools</code>, <a href="/crates/mcp">weirdnet-mcp</a> tools for metadata, grants and rotation that never take or return a value.',
    ],
  ),
  'update': Guide(
    brings: r'''
<p>The trust and policy half of over-the-air updates, with no transport and no UI. An app that uses it can take updates from
anywhere (a CDN, a peer, a relay) and still install only what its publisher signed, never roll back to an older release,
roll out in stages without an install id, and never install without the user's consent. Salty Gull is built on it; nothing
here is Flutter-specific.</p>
''',
    works: r'''
<h3>The chain of trust</h3>
<ol>
<li>The app ships a <code>RootPin</code>: a BLAKE3 fingerprint of the first root's keys and threshold.</li>
<li>A <code>Root</code> lists k-of-n Ed25519 root keys (independent of Weirdnet user keys), release-key
<code>Delegation</code>s scoped to apps and channels with an expiry, and zero or more timestamp keys. Rotating a root needs the
old and the new threshold.</li>
<li>An <code>UpdateManifest</code> is signed by delegated release keys: app, channel, update id, <code>seq</code>, kind,
version, base releases, per-file size and BLAKE3, client-version range, requested capabilities, security and "recommended"
labels, targeting, a staged rollout, an optional rollback target, notes and an expiry.</li>
<li>When the root lists timestamp keys, a short-lived <code>Freshness</code> record names the latest manifest, revocations and
a rollout cap (a pause).</li>
</ol>
<p>Each is a <code>Signed</code> envelope: signatures over the exact CBOR payload with a domain string
(<code>weirdnet-update/v1/root</code>, <code>…/manifest</code>, <code>…/freshness</code>, <code>…/announcement</code>), checked
before decoding. Duplicate and untrusted signatures don't count toward a threshold.</p>
<h3>On the device</h3>
<ul>
<li><code>Client::verify</code> applies the acceptance rule and keeps <code>ClientState</code>: the trusted root chain, the
last <code>seq</code> and manifest hash per channel, installed versions and updates marked bad (anti-rollback).</li>
<li>Targeting rules are evaluated on the device; rollout stages are in basis points, bucketed by a keyed hash of a
device-local secret and the update id.</li>
<li><code>policy::decide</code>: ask for each update by default, opt-in automatic installs, notify only, or off (the F-Droid
default). New capabilities always ask. <code>Flavor</code>s gate kinds: no full updates on Play, App Store, Mac App Store or
F-Droid builds.</li>
<li><code>health</code>: trial boots, commit on ready, local rollback after two failed boots.</li>
</ul>
<p>Kinds: assets (including Remote Flutter Widgets files), Wasm with a host ABI version, a full signed package (platform,
arch, format, signing identity), store notices, and a reserved Dart patch kind clients refuse by default.</p>
<h3>Announcements (0.2.0)</h3>
<p>Small signed notices that a manifest exists (app, channel, seq, manifest hash, fetch hints), so devices behind NAT hear
about updates. A <code>Carrier</code> keeps the latest per org, app and channel for the orgs it trusts (weirdnet-relay is one),
and <code>Client::verify_announcement</code> checks one on the device; the full bundle is still fetched and verified.
Transport, installers and UI are not here: those are weirdnet-net and Salty Gull's <code>salty-client</code>.</p>
<h3>Unsigned file sets (0.2.1)</h3>
<p>A plain tar.gz or zip with no platform signature names <code>UNSIGNED</code> (<code>"unsigned"</code>) as its signing
identity: its integrity rests on the root chain, the release key and the per-file BLAKE3 hashes. Validation refuses it for any
other format (an <code>.app</code>, <code>.exe</code> or anything with a platform installer must name its real identity).
<code>FullPackage::signing_identity_matches(running)</code> needs equal identities, so an update can't strip a platform signature
from a signed install or add one silently; <code>platform_signed()</code> tells the two apart.</p>
''',
    features: ['<code>wire</code>: the announcement stream protocol <code>/weirdnet/updates/1</code> (subscribe, publish), carried by weirdnet-relay.'],
  ),
  'accounts': Guide(
    brings: r'''
<p>Use weirdnet-accounts when one server serves many accounts and many people: each account (a tenant) has an owner, several
identities hold roles in it, and one identity can belong to many accounts. The crate decides who may do what on which
account, handles invitations and removals, and binds API keys to an account and a role. Roles and the decision itself come
from <a href="/crates/access">weirdnet-access</a>; identities are Weirdnet user ids from <a href="/crates/net">weirdnet-net</a>.</p>
<p>It also keeps the account rules a web service needs, with the cryptography done once: password hashing, bearer tokens that
are never stored in the clear, name rules, rate limits that can't be dodged with a spoofed header, and org-scoped API keys.
TAUR uses them from v1.10.0; they are unchanged in 0.2, so moving from 0.1 is changing the requirement to
<code>"0.2"</code>.</p>
''',
    works: r'''
<h3>Accounts</h3>
<p>An <code>Account</code> has an id (1 to 64 of <code>a-z 0-9 . _ -</code>), a name, an owner (a Weirdnet user id), a status
(active, suspended or closed) and its own weirdnet-access <code>RoleSet</code>. A <code>Member</code> holds one role in one
account, with who added them, when, and an optional expiry. Only the owner acts as the builtin <code>owner</code> role; no
membership can make someone the owner. Times are Unix milliseconds, as in weirdnet-net.</p>
<h3>The role catalog</h3>
<p><code>catalog::catalog()</code> is the weirdnet-access core (<code>read</code>, <code>members.*</code>,
<code>roles.manage</code>) plus <code>account.view</code>, <code>account.edit</code>, <code>account.suspend</code>,
<code>account.close</code>, <code>audit.view</code> and <code>keys.manage</code>. Apps add their own permissions to it.
<code>catalog::tiered</code> builds a ranked role set under the owner (rank 100) from your own names, ranks and permissions;
<code>catalog::standard</code> is a generic preset: owner, admin (80), member (50), viewer (20) and auditor (10), with
invitees joining as viewer.</p>
<h3>The Authorizer</h3>
<p><code>authz::Authorizer</code> answers one question: may this caller use this permission on this account? It works in
weirdnet-access's order:</p>
<ol>
<li><b>Identity</b>: the user id the caller's node cert resolves to. A missing or revoked identity sees nothing.</li>
<li><b>Account</b>: a missing or closed account is "not found". A suspended one allows only <code>read</code>,
<code>members.list</code> and <code>account.view</code> (configurable).</li>
<li><b>Role</b>: the owner, or a current membership that no revocation voids. <code>MembershipPolicy</code> decides which
memberships count: <code>Recorded</code> (the server's records), <code>Signed</code> (an owner-signed membership the caller
presented) or <code>Either</code>.</li>
<li><b>Decision</b>: weirdnet-access <code>enforce::decide</code> with the account's role set.</li>
</ol>
<p>Accounts are private: anyone who isn't the owner or a member gets "not found", so account ids don't leak. The
<code>Authorize</code> trait is implemented for closures too, and <code>Authorizer::facts</code> returns the weirdnet-access
<code>Facts</code> for hooks that take them, such as an access-based <a href="/crates/vault">weirdnet-vault</a> authorizer.</p>
<h3>The Accounts directory</h3>
<p><code>directory::Accounts</code> holds the checked operations: create, rename, suspend, resume and close accounts; replace
the role set (owner only); add members, change roles and remove members; list members; and invitations and key bindings. Each
operation goes through the <code>Authorizer</code> and the weirdnet-access rank rules: nobody grants a role at or above
their own or acts on someone ranked at or above them. Only the owner acts on a suspended account, and a closed account
can't reopen. Removing a member records a <code>Revocation</code> that voids every membership issued up to then; adding
them again later works.</p>
<h3>Invitations</h3>
<p><code>Accounts::invite</code> (<code>members.invite</code>) creates an invitation to a role ranked below the inviter's,
by default the account's invite role, open for up to 30 days and optionally only for one user. The code is 256 random bits,
shown once and stored only as SHA-256. <code>accept</code> turns it into a membership; unknown, used, withdrawn and expired
codes all give the same error. <code>withdraw_invitation</code> closes an open one.</p>
<h3>API keys</h3>
<p>The <code>apikeys</code> module issues the keys themselves. <code>Accounts::bind_key</code> (<code>keys.manage</code>)
ties a key to its maker, one account and a role no higher than the maker's, and never the owner role.
<code>Authorizer::authorize_key</code> lets the key act with the lower of that role and its maker's current role, so a key
loses power when its maker does and stops working when they leave.</p>
<h3>Storage</h3>
<p>Everything goes through the <code>store::Store</code> interface: apps that keep accounts in their own database implement
it over their own tables. <code>MemoryStore</code> serves tests and small tools. With the <code>sqlite</code> feature,
<code>SqliteStore</code> keeps the records in a <a href="/crates/storage">weirdnet-storage</a> SQLCipher database of its own
(for example <code>accounts.db</code>, keyed from the app's keyring), applies its own versioned migrations there, and writes
encrypted snapshots.</p>
<h3>Signed memberships and ServiceAuth</h3>
<p>With the <code>net</code> feature the owner signs memberships and removals with their user key
(<code>net::sign_member</code>, <code>net::sign_revocation</code>, on weirdnet-net's <code>Membership</code> and
<code>MemberRevocation</code>), for the resource <code>&lt;app&gt;/account/&lt;id&gt;</code>. A member's node presents its
membership, and <code>net::caller_from_presented</code> checks it with <code>check_presented</code> against the
authenticated peer.</p>
<p>With the <code>service</code> feature, <code>service::ServiceAuth</code> implements <a href="/crates/service">weirdnet-service</a>'s
<code>Authorize</code>. It checks the caller's user card against the peer, maps the resource (a bare account id, or
<code>&lt;app&gt;/account/&lt;id&gt;</code> with <code>for_app</code>) to an account, and lets the <code>Authorizer</code>
resolve account plus identity to a role from the store, counting presented memberships under the <code>Signed</code> and
<code>Either</code> policies. The admitted caller carries the user id, the resource and the role. weirdnet-service's own
<code>MembershipAuth</code> fits resources held in memory; <code>ServiceAuth</code> fits accounts kept in a
<code>Store</code>.</p>
<h3>The 0.1 primitives</h3>
<ul>
<li><code>password</code>: Argon2id hashes as PHC strings (the <code>argon2</code> defaults: v1.3, m = 19 MiB, t = 2, p = 1),
verification, and a minimum-length rule.</li>
<li><code>token</code>: 256-bit random bearer tokens for sessions, email links and invitations. Only the SHA-256 is stored,
and hashes are compared in constant time.</li>
<li><code>names</code>: <code>NamePolicy::AUR</code> (3 to 16 of <code>[A-Za-z0-9._-]</code>, alphanumeric at both ends) and a
light email check.</li>
<li><code>ratelimit</code>: in-memory fixed-window limits per client and per app-defined class, with bounded key tables.
<code>X-Forwarded-For</code> is honoured only from trusted proxies and walked from the right, so spoofed entries are
ignored.</li>
<li><code>apikeys</code>: org-scoped keys <code>&lt;service&gt;_&lt;org&gt;_&lt;64 hex&gt;</code>, shown once and stored as SHA-256,
with <code>resource:verb</code> scopes, optional app and channel bindings, expiry and revocation.</li>
</ul>
''',
    features: [
      'No feature is on by default: the primitives and the accounts model build without a database or network stack.',
      '<code>sqlite</code>: <code>SqliteStore</code>, the accounts store in its own SQLCipher database (<a href="/crates/storage">weirdnet-storage</a>), with versioned migrations and encrypted snapshots.',
      '<code>vendored-openssl</code>: <code>sqlite</code>, building SQLCipher\'s OpenSSL from source.',
      '<code>net</code>: owner-signed memberships and revocations and callers from node certs or presented memberships (<a href="/crates/net">weirdnet-net</a>).',
      '<code>service</code>: <code>ServiceAuth</code>, a <a href="/crates/service">weirdnet-service</a> <code>Authorize</code> hook over the <code>Authorizer</code> (includes <code>net</code>).',
    ],
  ),
  'chart': Guide(
    brings: r'''
<p>Use weirdnet-chart for live charts in a desktop or terminal app: prices with volume below, indicators, anything
time-ordered that keeps arriving. One chart model drives both a <a href="https://crates.io/crates/gpui">GPUI</a> view and a
<a href="https://crates.io/crates/ratatui">Ratatui</a> widget, so a GUI and a TUI show the same chart. The core has no GUI
dependencies.</p>
''',
    works: r'''
<h3>Series</h3>
<p>A <code>Series</code> is a time-ordered ring buffer of points or candles. Appending is O(1), the oldest samples drop off
at capacity, and a push with the newest timestamp replaces it in place, which is how a live candle updates.
<code>Chart::apply_trade(series, time, price, size, interval)</code> folds trades into fixed-interval candles: it updates the
open candle or starts the next one. Timestamps are milliseconds since the Unix epoch.</p>
<h3>Panes and marks</h3>
<p>A <code>Chart</code> stacks any number of panes over one time axis, each with a weight and its own y axis
(<code>YRange</code>: auto, auto from zero, or fixed), for example price above volume. Each series has a <code>Mark</code>
that says how it is drawn:</p>
<ul>
<li><code>Line</code>: a polyline through points.</li>
<li><code>Area</code>: a polyline with the area under it filled.</li>
<li><code>Bars</code>: a bar from zero per point.</li>
<li><code>Candles</code>: candlesticks.</li>
<li><code>Ohlc</code>: OHLC bars, a high-low line with open and close ticks.</li>
<li><code>Volume</code>: volume bars taken from another candle series, coloured by direction
(<code>add_volume(pane, candles)</code>).</li>
</ul>
<p>Value axes use "nice" ticks with compact labels. Time ticks are calendar-aware from milliseconds to decades and land on
whole local minutes, hours, days, months and years for a fixed UTC offset
(<code>set_time_zone(TimeZone::Fixed(seconds))</code>); charts carry no time-zone database.</p>
<h3>Viewport</h3>
<p>The <code>Viewport</code> is the visible time window. It pans (by time, a fraction or pixels), zooms around a point, and
keeps the span within limits (<code>set_span_limits</code>). While it is following, new data scrolls the view so the newest
sample stays at the right edge with a small margin; panning away stops following, and panning or zooming back to the live
edge resumes it. <code>Chart::show_latest(span)</code> shows the last <code>span</code> milliseconds and follows.</p>
<h3>Layout to a Scene</h3>
<p><code>Chart::layout</code> turns the chart into a <code>Scene</code> for a given size: the plot area, the time scale, each
pane's layout, and backend-neutral primitives (rectangles, lines, polylines, areas and text) in clip layers, back to front.
Only the visible range is laid out. Lines are reduced to the first, lowest, highest and last point per pixel column, so
spikes and gaps survive, and candles merge into wider bars when they would be thinner than three pixels. A new backend only
has to draw those five primitives.</p>
<h3>FrameThrottle</h3>
<p><code>FrameThrottle</code> turns a burst of updates into one frame now and at most one more after the frame interval, so
live data redraws at the frame rate instead of on every tick. In a terminal event loop, pair <code>FrameThrottle::poll</code>
with <code>FrameThrottle::timeout</code>.</p>
<h3>Ratatui</h3>
<p>With the <code>ratatui</code> feature, <code>ratatui::ChartWidget</code> draws the scene with braille dots (two across and
four down per cell) on ratatui-core, so it works with ratatui 0.30. <code>pan_columns</code> and <code>zoom_columns</code>
pan and zoom by terminal columns, and <code>render_scene</code> draws a laid-out scene into a buffer.</p>
<h3>GPUI</h3>
<p>With the <code>gpui</code> feature, <code>gpui::ChartView</code> is a view that owns the chart, draws it with paths, quads
and shaped text, pans on drag and horizontal scroll, and zooms on vertical scroll. Feed it from a task with
<code>update_chart</code>, which coalesces redraws to 60 frames per second (<code>set_fps</code> changes that);
<code>gpui::paint_scene</code> draws a scene in your own element or <code>canvas</code>.</p>
<p>The backend builds against gpui 0.2.2 from crates.io. An app that pins GPUI to a git revision can point this crate at the
same revision with <code>[patch.crates-io]</code>, as long as that revision's gpui is semver-compatible. On Linux, GPUI needs
the X11, Wayland, xkbcommon, Vulkan, fontconfig and freetype development packages. gpui 0.2.2 also pulls in
<code>xattr</code> 0.2.3, which needs <code>libc</code> 0.2.189 or older on Linux; the
<a href="https://github.com/WeirdBrains/weirdnet-chart">weirdnet-chart repository</a>'s <code>Cargo.lock</code> pins it
there.</p>
''',
    features: [
      'No feature is on by default: the core has no GUI dependencies.',
      '<code>ratatui</code>: <code>ratatui::ChartWidget</code> (braille, ratatui 0.30 through ratatui-core), <code>render_scene</code>, column-based pan and zoom.',
      '<code>gpui</code>: <code>gpui::ChartView</code> and <code>paint_scene</code>, against gpui 0.2.2 from crates.io.',
      '<code>gpui-test-support</code>: GPUI\'s headless test platform, for the crate\'s own tests.',
    ],
  ),
  'exchange': Guide(
    brings: r'''
<p>Use weirdnet-exchange to write trading code once and run it against any venue: real adapters implement its traits, and
the in-memory <code>Paper</code> exchange stands in for tests and dry runs. Prices and sizes are exact decimals, never
floats.</p>
''',
    works: r'''
<ul>
<li><b>Numbers</b>: <code>Price</code> and <code>Qty</code> wrap a decimal and serialize as strings; rounding to a
product's increments is explicit (<code>Rounding::Down</code>, <code>Up</code>, <code>Nearest</code>).</li>
<li><b>Instruments</b>: <code>Market</code> (venue and product) and <code>Product</code> with increments, size and notional
limits, status and kind (spot, dated future, perpetual); <code>Product::check_order</code> makes the checks a venue
would.</li>
<li><b>Orders</b>: market, limit (with post-only), stop-limit and stop-market orders; GTC, GTD, IOC and FOK; validated
<code>ClientOrderId</code>s; an <code>Order</code> state machine that refuses impossible transitions and overfills and
ignores replayed fills.</li>
<li><b>Accounts</b>: <code>Fill</code>, <code>Balance</code>, <code>FeeTier</code>, <code>Position</code> and
<code>PositionBook</code> (weighted-average entry, realized and unrealized PnL, flips), <code>MarginSummary</code>.</li>
<li><b>Market data</b>: trades, tickers, book snapshots and deltas, an <code>OrderBook</code> that reports sequence gaps,
<code>Candle</code> and <code>CandleBuilder</code>.</li>
<li><b>Adapters</b>: <code>MarketData</code> and <code>Trading</code> (balances, fees, preview, idempotent placement,
cancel, queries, positions, user streams) with <code>Capabilities</code>; <code>Exchange</code> is both. Errors say whether
a retry is safe.</li>
<li><b>Helpers</b>: <code>CostModel</code> and <code>BookCostModel</code>, and a shared token-bucket
<code>RateLimiter</code>.</li>
<li><b>Credentials</b>: <code>Credential&lt;Live&gt;</code> and <code>Credential&lt;Test&gt;</code> are checked against
their source's environment, so a live adapter can't be built from test credentials.</li>
<li><b>Paper</b>: matches market, limit, post-only, IOC, FOK, GTC and GTD orders against the books and trades you give it,
holds funds, charges fees and tracks positions. Resting orders fill optimistically (no queue position) and margin is not
modelled.</li>
</ul>
''',
    features: [
      '<code>vault</code>: <code>vault::VaultSecret</code>, credentials from <a href="/crates/vault">weirdnet-vault</a>, scoped per account and venue, test and live kept apart.',
      '<code>service</code>: <code>feeds::MarketHubs</code>, books, trades, tickers and candles as <a href="/crates/service">weirdnet-service</a> hub topics.',
    ],
  ),
  'mcp': Guide(
    brings: r'''
<p>A Model Context Protocol server for an app's tools and resources, so AI clients can call them, plus the stdio bridge behind
<code>&lt;app&gt;ctl mcp</code>. It is stateless: the app decodes the request (or lets the crate's stdio or HTTP server do it),
the crate speaks MCP. TAUR uses it from v1.10.0, Salty Gull for its server and <code>saltyctl mcp</code>, and Ymir and Bragi
for their MCP servers.</p>
<p>Since 0.6.2 the client keeps image and audio blocks in tool results, so an app can use tools that return pictures or
sound, such as frames taken from a video.</p>
<p>Since 0.6.1 apps can also offer prompts: templates the user picks, such as slash commands.</p>
<p>Since 0.6.0 tools can be async and return images and audio, input schemas can nest objects, enums, arrays and
<code>anyOf</code>, apps can serve resources, and the crate brings the stdio loop and a streamable HTTP endpoint with bearer
auth and DNS-rebinding protection. It answers both the <code>initialize</code>-based protocol versions (2024-11-05 to
2025-11-25) and <a href="https://modelcontextprotocol.io/specification/2026-07-28">MCP 2026-07-28</a>, where every request
carries its version in <code>_meta</code>.</p>
<p>From 0.2.0 it also works the other way round: with the <code>client</code> feature an app talks to any MCP server, and with
<code>agent</code> that server's tools become a tool source for <a href="/crates/agent">weirdnet-agent</a>, under the
agent's approval policy.</p>
''',
    works: r'''
<ol>
<li>The app declares a <code>const</code> table of <code>ToolSpec</code>s: name, description, <code>Param</code>s, whether a
bearer token is needed, and the <code>readOnlyHint</code>, <code>destructiveHint</code> and <code>openWorldHint</code>
annotations. Tools that need auth say "Requires a bearer token." in their description. A <code>ParamType</code> is a string,
integer, number, boolean or string array, or since 0.6.0 <code>Any</code>, <code>Enum(&amp;[..])</code>,
<code>Array(&amp;type)</code>, <code>Object(&amp;[params])</code>, <code>AnyOf(&amp;[types])</code> or a raw
<code>Json</code> schema. <code>ToolSpec::check</code> reports empty or duplicate names, empty enums and bad raw schemas in a
unit test.</li>
<li>Each decoded JSON-RPC 2.0 message or batch, with the caller's token, goes to <code>Server::handle</code> (sync) or
<code>Server::handle_async</code>.</li>
<li>The server answers <code>initialize</code> (negotiating 2025-11-25, 2025-06-18, 2025-03-26 or 2024-11-05),
<code>server/discover</code>, <code>ping</code>, <code>tools/list</code> and <code>tools/call</code>, and with resources
<code>resources/list</code>, <code>resources/templates/list</code> and <code>resources/read</code>. It returns nothing for
notifications.</li>
<li>A request whose <code>_meta</code> carries <code>io.modelcontextprotocol/protocolVersion</code> is served as 2026-07-28: an
unsupported version gets <code>-32022</code> with the supported list, missing client capabilities <code>-32602</code>, and
results carry <code>resultType</code>, the server's identity and, for discovery, lists and reads, <code>ttlMs</code> and
<code>cacheScope</code> from <code>Tools::cache_hint</code>.</li>
<li><code>tools/call</code> reaches the app's <code>Tools::call</code> (sync, returns JSON shown as pretty text plus
<code>structuredContent</code>) or <code>Tools::call_async</code> (returns a <code>CallToolResult</code> of
<code>Content</code>: text, image, audio, resource links, embedded resources). Auth, permissions and hiding internal errors
are the app's; a <code>ToolError</code> becomes an <code>isError</code> result. <code>args</code> has getters with uniform
messages.</li>
<li>Resources come from optional <code>Tools</code> methods: <code>has_resources</code>, <code>list_resources</code>,
<code>resource_templates</code> and <code>read_resource</code>, which returns <code>ResourceError::NotFound</code> for an
unknown URI.</li>
<li><a href="https://modelcontextprotocol.io/specification/2026-07-28/server/prompts">Prompts</a> (0.6.1) come from
<code>Tools::prompts</code>, a <code>const</code> table of <code>PromptSpec</code>s (name, optional title and description,
<code>PromptArg::required</code> / <code>optional</code> arguments; <code>PromptSpec::check</code> finds empty or duplicate names),
and <code>Tools::get_prompt</code>, which returns a <code>GetPromptResult</code>: an optional description and user or assistant
<code>PromptMessage</code>s holding any <code>Content</code>. The <code>prompts</code> capability appears in
<code>initialize</code> and <code>server/discover</code> only when the table is not empty. The server answers a missing or
unknown name and missing or non-string arguments with <code>-32602</code> before the app runs; <code>PromptError::NotFound</code>
hides a prompt from a caller, <code>InvalidArguments</code> gives <code>-32602</code> and <code>Failed</code>
<code>-32603</code>. 2026-07-28 <code>prompts/list</code> results carry the caching hints.</li>
</ol>
<h3>Serving it (0.6.0)</h3>
<ul>
<li><b>stdio</b>: <code>stdio::serve_blocking(&amp;server, stdin, stdout)</code> for sync tools, or
<code>stdio::serve(Arc::new(server), tokio::io::stdin(), tokio::io::stdout())</code> (feature <code>stdio-server</code>), which
runs requests concurrently, stops a request on <code>notifications/cancelled</code>, and answers lines over 32 MiB with a parse
error without buffering them.</li>
<li><b>Streamable HTTP</b> (feature <code>http-server</code>): <code>Guard</code> checks, before the body is read, the
<code>Host</code> and any <code>Origin</code> (<code>403</code>; <code>Guard::loopback</code> allows <code>localhost</code>,
<code>127.0.0.1</code> and <code>[::1]</code>, and <code>allow_host</code> / <code>allow_origin</code> add public names), that
the method is POST (<code>405</code>), and the bearer token (<code>401</code> with <code>WWW-Authenticate: Bearer</code>):
<code>Auth::Token</code> compared in constant time, <code>Auth::Check</code>, or <code>Auth::PassThrough</code> for per-tool
auth. 2026-07-28 requests must also send <code>MCP-Protocol-Version</code>, <code>Mcp-Method</code> and, for tool calls, resource reads and <code>prompts/get</code>,
<code>Mcp-Name</code> matching the body (<code>400</code> with <code>-32020</code> otherwise). Notifications get
<code>202</code>, unknown 2026-07-28 methods <code>404</code>, and no sessions are minted. <code>respond</code> works with any
framework on the <code>http</code> crate.</li>
<li><b>axum</b> (feature <code>axum</code>): <code>http::router("/mcp", Arc::new(server), Guard::loopback(Auth::token(secret)))</code>,
or <code>http::route(..)</code> to mount it on an existing router.</li>
</ul>
<p><code>stdio::bridge</code> is the loop for a CLI that talks to a remote server: read JSON-RPC lines on stdin, forward them to
the remote <code>/mcp</code>, write the replies.</p>
<h3>The client (0.2.0, feature <code>client</code>)</h3>
<ol>
<li><code>Client::connect(transport, ClientOptions)</code> runs <code>initialize</code>; then <code>list_tools</code> follows
cursors, and <code>call_tool</code> or <code>call_tool_until(name, args, cancel)</code> calls a tool.</li>
<li><b>Images and audio (0.6.2).</b> <code>call_tool</code> returns text, with a <code>[image content omitted]</code> note for
each non-text block. <code>call_tool_content</code> and <code>call_tool_content_until</code> return the whole
<code>CallToolResult</code>: every text, image, audio, resource-link and embedded-resource block in the server's order, plus
<code>structuredContent</code> and <code>isError</code>. <code>CallToolResult::from_json</code> and <code>Content::from_json</code>
parse the same JSON without a client. Images and audio are base64 <code>data</code> plus <code>mimeType</code>, as MCP sends
them:
<pre><code>{"content": [
  {"type": "text", "text": "frame at 1.5s"},
  {"type": "image", "data": "iVBORw0KGgo=", "mimeType": "image/png"},
  {"type": "audio", "data": "UklGRiQAAABXQVZF", "mimeType": "audio/wav"}
], "isError": false}</code></pre>
<code>Content::decoded_bytes</code> decodes the base64 (<code>None</code> if it is not valid), <code>mime_type</code>,
<code>is_image</code>, <code>is_audio</code> and <code>as_text</code> describe a block, <code>format</code> gives the short audio
format and <code>data_url</code> the <code>data:</code> URL that weirdnet-agent content parts take. Optional
<code>annotations</code> and <code>_meta</code> on a block are ignored, and blocks of unknown types are skipped.</li>
<li>Every request has a timeout. A timeout or a cancel sends <code>notifications/cancelled</code> to the server.</li>
<li>Transports: <code>StdioTransport</code> (<code>spawn(&amp;StdioCommand)</code> or <code>from_io</code>) for a local command,
and <code>HttpTransport</code> (<code>HttpConfig</code>) for streamable HTTP: JSON or SSE responses, the
<code>Mcp-Session-Id</code> and <code>MCP-Protocol-Version</code> headers, and no redirects.</li>
<li><b>Line cap (0.3.0).</b> The stdio transport reads each server line (one JSON message) with a cap, <code>DEFAULT_MAX_LINE</code>:
4 MiB. A longer line is discarded without being buffered, so a misbehaving server cannot exhaust memory, and a request waiting
for that reply times out. <code>StdioTransport::spawn_limited</code> and <code>from_io_limited</code> set a different limit;
<code>spawn</code> and <code>from_io</code> keep their signatures and use the default.</li>
<li>Local-command servers run with the user's permissions: show <code>StdioCommand::warning()</code> before starting one.
Environment values and bearer tokens are <code>Secret</code>s, redacted in <code>Debug</code>; keep them in a per-machine
store, never in synced settings.</li>
</ol>
<h3>As an agent tool source (feature <code>agent</code>)</h3>
<p><code>agent::McpSource</code> implements <code>weirdnet_agent::ToolSource</code>. Tool annotations map to the agent's tiers
with MCP's defaults (undeclared means not read-only, destructive and open world): destructive is <code>Interact</code>,
read-only and closed-world <code>Read</code>, read-only and open-world <code>Research</code>, anything else
<code>Navigate</code>. Each is raised to <code>SourceOptions::tier_floor</code>, which defaults to <code>Research</code>
because a server's hints are untrusted, so an outside tool never counts as reading only what the user attached. The agent's
cancel token stops a running call.</p>
<h3>Moving to 0.3.0</h3>
<ul>
<li><b>Server API and <code>client</code> feature</b>: unchanged; no code changes, just the version.</li>
<li><b>Apps with the <code>agent</code> feature</b> (breaking for them only): 0.3.0 depends on weirdnet-agent <code>=0.2.0</code>
(0.2.0 used <code>=0.1.0</code>), so <code>McpSource</code> implements the 0.2.0 <code>ToolSource</code>. Move to
<a href="/crates/agent">weirdnet-agent</a> 0.2.0 together with it; then the app has a single copy of the trait. No source changes
were needed in this crate for the move.</li>
<li><b>Stdio client</b>: a server that prints a line over 4 MiB now has it dropped and the waiting call times out; raise the limit
with <code>spawn_limited</code> if a server legitimately sends more.</li>
</ul>
<h3>Moving to 0.5.0</h3>
<ul>
<li><b>Server API and <code>client</code> feature</b>: unchanged.</li>
<li><b>Apps with the <code>agent</code> feature</b> (breaking for them only): 0.5.0 depends on weirdnet-agent <code>=0.4.0</code>
(0.4.0 used <code>=0.3.0</code>). Move to <a href="/crates/agent">weirdnet-agent</a> 0.4.0 together with it. No source changes were
needed in this crate.</li>
</ul>
<h3>Moving to 0.6.2</h3>
<p>Nothing to change: servers answer exactly as in 0.6.1, and <code>call_tool</code> and <code>McpSource</code> are unchanged. A
client that wants images and audio calls <code>call_tool_content</code> instead of <code>call_tool</code>.</p>
<h3>Moving to 0.6.1</h3>
<p>Nothing to change: servers without prompts answer exactly as in 0.6.0, and the new <code>Tools</code> methods have defaults.
To offer prompts, implement <code>prompts</code> and <code>get_prompt</code>. <code>Content</code> now converts from
<code>&amp;str</code> and <code>String</code>.</p>
<h3>Moving to 0.6.0</h3>
<ul>
<li><b>Sync apps</b>: no code changes. <code>Tools::call</code>, <code>Server::handle</code>, <code>ServerInfo</code> and
<code>stdio::bridge</code> are unchanged, and the <code>initialize</code>-era output is byte for byte what 0.5 produced, except
that a client asking for 2025-11-25 (or an unknown version) now gets 2025-11-25.</li>
<li><b>Breaking</b>: <code>ParamType</code> has new variants and is <code>#[non_exhaustive]</code>, so a <code>match</code> on it
outside the crate needs a <code>_</code> arm.</li>
<li><b>Async tools</b>: implement <code>call_async</code> instead of driving async work with <code>block_on</code> inside
<code>call</code>, and serve with <code>Server::handle_async</code>, <code>stdio::serve</code> or the HTTP route. Return
<code>CallToolResult::json(&amp;v)</code> for the old output, or <code>CallToolResult::new(vec![..])</code> with
<code>Content::from_data_url(..)</code> or <code>Content::audio_format(data, "wav")</code> for media.</li>
<li><b>Hand-patched schemas</b>: replace post-processing of <code>tools/list</code> with <code>ParamType::Array</code>,
<code>Object</code>, <code>Enum</code> and <code>AnyOf</code>.</li>
<li><b>Own stdio loop or HTTP route</b>: replace with <code>stdio::serve</code> and <code>http::router</code>; keep refusing
non-loopback bind addresses in the app, since <code>Guard</code> checks the <code>Host</code> and <code>Origin</code> headers,
not the listen address. Rejections now carry JSON-RPC error bodies.</li>
</ul>
''',
    features: [
      '<code>stdio-server</code> (off by default, 0.6.0): <code>stdio::serve</code> and <code>serve_with</code>. Pulls in tokio.',
      '<code>http-server</code> (off by default, 0.6.0): the <code>http</code> module (<code>Guard</code>, <code>Auth</code>, <code>respond</code>). Pulls in the <code>http</code> crate.',
      '<code>axum</code> (off by default, 0.6.0, implies <code>http-server</code>): <code>http::route</code> and <code>http::router</code> for axum 0.8.',
      '<code>client</code> (off by default): the MCP client with stdio and streamable HTTP transports, timeouts and cancel, and <code>Secret</code>. Pulls in tokio and reqwest (rustls).',
      '<code>agent</code> (off by default, implies <code>client</code>): <code>agent::McpSource</code> for <a href="/crates/agent">weirdnet-agent</a> 0.4 or 0.5.',
      'None is needed for <code>Server</code>, <code>Tools</code>, content, resources, prompts, <code>stdio::serve_blocking</code> or <code>stdio::bridge</code>.',
    ],
  ),
  'agent': Guide(
    brings: r'''
<p>The agent loop for <a href="https://weirdbrains.com">WeirdBrains</a> apps, with the safety rules built in rather than left to each app. Morph's Companions are
its first user. The app brings a model, its tools and an approval UI; the crate runs each task, decides when to ask the user,
enforces research budgets and records a trace that every citation has to match.</p>
''',
    works: r'''
<h3>One task</h3>
<ol>
<li><code>AgentSession::run(task, events, cancel)</code> asks the <code>ModelBackend</code> for a turn (text and tool
calls), streaming text deltas as <code>AgentEvent</code>s.</li>
<li>Each tool call is checked against the <code>Policy</code> for this agent, the tool's tier and the site. When the policy
says ask, the app's <code>Approver</code> answers (once, or for the task).</li>
<li>The call is charged to the <code>Budget</code>, run with a timeout and the task's <code>CancelToken</code>, and its result
goes back to the model wrapped as untrusted data, with the trace step ids it may cite. Nothing in a tool result can widen a
permission.</li>
<li>The loop ends when the model stops calling tools, the budget runs out or the task is cancelled; the
<code>Outcome</code> has the text, the stop reason and the <code>Trace</code>.</li>
</ol>
<h3>Policy</h3>
<p>Tiers: <code>Read</code> (attached content), <code>Navigate</code>, <code>Research</code>, <code>Interact</code>,
<code>Never</code>. Per-agent, per-site levels <code>Off</code>, <code>Ask</code>, <code>Act</code>. Revocable standing allows
("Always allow") for navigate (one site or everywhere) and research (optionally one provider), for one agent or all. Off always
wins, signed-in research is never covered by a standing allow, and an all-agents allow covers an external agent only after its
first approval. Tools come from <code>ToolSource</code>s in a <code>ToolRegistry</code> (<code>LocalTools</code> in process
now), with per-source and per-tool switches; tier overrides can only make a tool stricter.</p>
<h3>Budgets and traces</h3>
<p><code>Budget</code> defaults: 3 searches, 12 pages (+5 on extension), 2 at a time, 15 s per page, 90 s of tool time per task, 4k
tokens kept per page, and a cap on model steps. Since 0.3.0, <code>per_task</code> counts only time inside tool calls (a
<code>ToolTimer</code> from <code>BudgetTracker::time_tool</code> wraps each one, and overlapping calls count once): model turns and
waiting for the user to answer an approval card don't use it, and a model turn is no longer cut off when it runs out
(<code>max_steps</code> and cancellation bound turns). <code>BudgetTracker::wall_elapsed</code> gives the task's wall-clock time for display. Every search, fetch, tool call, approval and notice is a <code>TraceStep</code> with its
agent, node and session (logged out or signed in). <code>validate_citations</code> rejects a cited URL that none of its steps
fetched, and <code>retain_valid</code> drops such citations before display. Everything stored or synced implements serde.</p>
<h3>Media limits (0.5.7)</h3>
<p>A client that sizes images, audio or a video's frames for one model needs that model's limits. Catalog entries carry them
as <code>CatalogModel::limits</code>, a <code>MediaLimits</code>: <code>max_images</code> per request, <code>image_tokens</code> (what
one image costs, or with <code>image_patch</code> the most it costs), <code>image_patch</code> (pixels per token edge for models whose
cost grows with size), <code>image_edge</code> (the longest edge the model uses), <code>audio_max_seconds</code>,
<code>audio_tokens_per_minute</code> and <code>max_request_bytes</code>. Each is absent when the node doesn't know it, never
defaulted, so a client asks the user rather than guessing. <code>image_cost(w, h)</code> and <code>audio_cost(ms)</code> give token
costs, <code>tightest</code> merges copies field by field and <code>or</code> puts an operator's numbers over measured ones. The
context window stays in <code>CatalogModel::context</code>. Entries without limits look as before on the wire.</p>
<h3>Speech to text (0.5.8)</h3>
<p>A video's soundtrack can become text for a model that doesn't take audio. A speech-to-text model's catalog entry has purpose
<code>transcribe</code> (<code>Purpose::Transcribe</code>, the same name as <a href="/crates/model">weirdnet-model</a> 0.5.4's role); it is
never picked for chat. <code>Catalog::route_transcribe(model)</code> picks one: a named model must transcribe, and with none named the
best one is taken (warm first, then more replicas); otherwise it is a <code>BadRequest</code>.</p>
<p>The request goes over infer/2 as <code>ClientFrame::Transcribe(TranscribeRequest)</code>: the audio as raw bytes (a CBOR byte
string, not base64) with its <code>format</code> (<code>wav</code>, <code>mp3</code>, ...), and optionally <code>model</code>,
<code>language</code>, <code>prompt</code> (names and terms to guide spelling) and <code>timestamps</code>. It queues like any request;
the node answers <code>Accepted</code>, a <code>Working</code> frame every few seconds while the model runs, one <code>Transcript</code>
(<code>text</code>, <code>language</code>, <code>duration_ms</code> and, when asked and the backend can, <code>Segment</code>s with
<code>start_ms</code> and <code>end_ms</code>) and <code>Done</code> with usage. Apps call <code>Pool::transcribe</code>, which fails over
between nodes and returns a <code>Transcription</code>; hosts implement <code>InferHost::open_transcribe</code> with a
<code>TranscribeBackend</code>. A node before 0.5.8 closes the stream, which the pool counts as unsupported. The whole request must fit
in one 32 MiB message, so long soundtracks go in pieces.</p>
<p>Peers before 0.5.8 can't read a <code>transcribe</code> entry, so a node leaves those entries out of their catalog;
<code>catalog::query</code> and <code>catalog::subscribe</code> from 0.5.8 ask for everything, and an entry they can't read is skipped
rather than failing the whole catalog.</p>
<h3>Native video (0.5.10)</h3>
<p>A model that reads video natively can take a whole clip instead of frames sampled by the client. <code>ContentPart::video(url)</code>
builds a <code>video_url</code> part, <code>{"type": "video_url", "video_url": {"url": "data:video/mp4;base64,..."}}</code>, the same in
infer/2 CBOR and in JSON (the part vLLM and mistral.rs take); <code>ContentPart::video_bytes(&amp;bytes, "video/mp4")</code> makes the
<code>data:</code> URL for you. Only <code>data:video/...</code> URLs are accepted (<code>Content::check</code>); remote URLs are never
fetched. <code>VideoUrl::data_len()</code> gives the decoded size without decoding. The clip travels inside the request, so it must fit
in one 32 MiB stream message with everything else.</p>
<p>A request with a video part needs <code>Modalities::VIDEO</code>. Catalog entries say <code>inputs.video</code> when the model reads
video (<code>Modalities::with_video(true)</code>); entries from nodes before 0.5.10 lack it and count as not reading video, and older
peers simply ignore it. <code>Catalog::route</code> and the pool send a clip only to a chat model that reads video: a named model that
doesn't, or a pool with none, is a <code>BadRequest</code> whose message ends with <code>catalog::VIDEO_FALLBACK</code>, "send the video
as frames (image_url parts) instead", so a client can fall back to sampling frames. <code>PoolModel</code> reroutes a chosen model that
can't read the clip, as for images.</p>
<p><code>MediaLimits</code> carries the model's video limits when the node knows them: <code>video_max_seconds</code>,
<code>video_max_bytes</code> (decoded) and <code>video_frames_per_minute</code> (per minute so 0.5 frames a second stays exact;
<code>video_frame_rate()</code> gives frames per second). Each is absent when unknown, never defaulted. <code>video_frames(ms)</code>
says how many frames the model reads from a clip, <code>check_video(ms, bytes)</code> names the first known limit a clip exceeds, and
<code>tightest</code> and <code>or</code> merge them like the other limits.</p>
<h3>Speech out (0.5.11)</h3>
<p>A model can speak: text in, audio out. Its catalog purpose is <code>speak</code> (<code>Purpose::Speak</code>, the same name as
<a href="/crates/model">weirdnet-model</a>'s role) and its entry carries a <code>SpeechProfile</code> (<code>CatalogModel::speech</code>)
that says what it does: named <code>presets</code>, <code>design</code> (a voice from a description), <code>instructions</code> (style or
emotion), <code>clone</code> (a voice from a reference clip, with a <code>CloneMode</code> saying whether the clip's transcript is
unused, optional or required), <code>script_speakers</code> (multi-speaker scripts), <code>raw</code> engine input, <code>speed</code> and
<code>streaming</code>; what it takes: <code>languages</code>, <code>formats</code> (<code>AudioFormat</code>: <code>wav</code>,
<code>pcm16</code>, <code>mp3</code>, <code>opus</code>, <code>flac</code>) and <code>sample_rate</code>; and its limits
(<code>max_input_chars</code>, <code>max_reference_seconds</code>, <code>max_reference_bytes</code>, <code>max_output_seconds</code>).
A feature is on only when the node knows the model has it, and a list or limit is absent when nobody reported it.
<code>SpeechProfile::tightest</code> merges copies across nodes (a feature only when every copy has it), and
<code>narrowed_by</code> applies an operator's overrides, refusing anything that would widen what the engine reports.</p>
<p>The request is <code>ClientFrame::Speak(SpeakRequest)</code>: <code>SpeakInput::Text</code>, a <code>Script</code> of
<code>ScriptTurn { speaker, text }</code> or <code>Raw</code> input; an optional <code>Voice</code> (<code>Preset { name }</code>,
<code>Design { description }</code> or <code>Clone { audio, format, text, consent }</code>, the clip as raw bytes, never stored);
per-speaker voices, <code>instructions</code>, <code>language</code>, <code>speed</code> in per mille, <code>seed</code>,
<code>format</code>, <code>sample_rate</code> and <code>stream</code>. <code>SpeakRequest::check</code> refuses empty input, a clone
without <code>consent</code> and a reference over 30 MiB before any backend opens. <code>SpeakRequest::needs()</code> gives the
<code>SpeechNeeds</code> that <code>SpeechProfile::covers</code> and <code>Catalog::route_speak</code> check, and a refusal names what the
model lacks, such as the list of presets when a voice like <code>alloy</code> isn't one of them (no voice is ever swapped for another).</p>
<p>The node answers <code>Accepted</code>, a <code>Working</code> frame every few seconds until the audio starts, one
<code>SpeechStart { format, sample_rate, channels }</code>, then <code>Audio { offset, data }</code> chunks of at most 256 KiB in order,
then <code>Done</code> with <code>Usage::input_chars</code> and <code>audio_ms</code> (and <code>Meta::ignored</code> naming fields the
model doesn't use, such as a reference transcript). <code>Pool::speak</code> returns the whole <code>Speech</code>;
<code>Pool::speak_stream</code> returns a <code>SpeechStream</code> once the audio has started. Both fail over to another node only
before <code>SpeechStart</code>: after that a failure is final, because another node would start again with another voice. Hosts
implement <code>InferHost::open_speak</code>, which sees the whole request (so a host can refuse a guest's voice clone), with a
<code>SpeakBackend</code> that returns an <code>AudioStream</code>: <code>AudioStream::from_file</code> for a finished file, or
<code>AudioStream::channel</code> and its <code>AudioSink</code> to stream. Speech goes through the same authorization as chat, so a
guest of a shared pool needs the <code>infer</code> scope for it too. Askers before 0.5.8 get catalogs without <code>speak</code>
entries, askers from 0.5.8 to 0.5.10 skip them, and a node before 0.5.11 closes the stream, which the pool counts as unsupported.</p>
<h3>Sharing a pool with another identity (0.5.9)</h3>
<p>Someone with a different Weirdnet identity, or your own identity in another app, can use your pool (for example
<a href="https://github.com/WeirdBrains/ymir">Ymir</a>) without its root identity: the guest presents its own device certificate
and gets catalog/1 and infer/2 (chat, embeddings, transcription, and since 0.5.11 speech out) only, never synced data, task/1 or anything else.</p>
<p>The owner hands out a <code>PoolShare</code> link: the owner's user id, an optional name and expiry, and the inference nodes'
peer ids with addresses to dial them (direct or relay circuit). It reads <code>wnet-pool1:&lt;base64url JSON&gt;</code> or
<code>weirdnet-pool://share/&lt;base64url JSON&gt;</code> and holds no secret: it only says where to dial. The guest's app calls
<code>pool::connect_shared(node, &amp;share, &amp;user_key, &amp;cert)</code>, which gives a <code>Pool</code> over the share's nodes in
order (failover as usual, no roster discovery) that presents a guest credential with every request:
<code>encode_credential</code>, the device's <code>NodeCert</code> plus its user's public key, since a certificate names its user only
by id.</p>
<p>On the owner's inference nodes, <code>serve::GuestAuth::new(profile, &amp;owner_key, policy)</code> checks the credential as
strictly as the roster checks the owner's own devices: the key must hash to the certificate's user id, the signature must verify,
the certificate must be for the peer on the connection, not revoked and not issued in the future. Then the host's policy, a
closure over its synced guest list, sees the <code>Guest</code> and a <code>GuestScope</code> (<code>Catalog</code> or
<code>Infer</code>) and decides, on every request. <code>SharedPoolAuth::new(roster_auth).with_guests(guests)</code> puts it next
to <code>RosterAuth</code>: <code>authorize_for(caller, GuestScope::Infer)</code> in <code>InferHost::authorize</code>,
<code>identify</code> to tell a guest from an own device (for example to refuse it server-side context), and
<code>scoped(GuestScope::Catalog)</code> for a <code>CatalogFeed</code>. Without <code>with_guests</code>, and on every node before
0.5.9, guests are refused.</p>
<p>Revoking is immediate: take the guest off the list and its next request is refused. <code>CatalogFeed::rechecking()</code>
(<code>CatalogHost::recheck</code>) re-checks a catalog subscription before each update and every 5 seconds and closes it with the
refusal; an answer already streaming finishes. Refusals reach the guest as <code>RemoteError::Refused</code> with the reason
(<code>not-shared</code>, <code>wrong-peer</code>, <code>guest-bad-cert</code>, <code>revoked</code> and so on).</p>
<h3>Synced jobs (0.5.6, feature <code>jobs</code>)</h3>
<p>A long job, such as training a model, should survive the device running it: another of the user's devices picks it up from
its last checkpoint. <code>JobBoard&lt;P&gt;</code> is a typed layer over the <a href="/crates/sync">weirdnet-sync</a> 0.8.2 job
log and leases, not a second log: every job is signed events in the op log, sealed and synced like any other record, and every
device folds them into the same <code>JobRecord&lt;P&gt;</code>. The app brings only its payload type <code>P</code>.</p>
<ol>
<li><b>Open and post</b>: <code>JobBoard::open(&amp;sync, "ymir.train")</code> with a <code>SyncHandle</code> (the sync node and
state, or <code>Leases</code>). <code>post(NewJob::new(id, base_revision, dataset, payload).with_policy(policy))</code> needs a
policy with a role (<code>JobPolicy::for_role</code>) or candidates. Payloads are up to 64 KiB.</li>
<li><b>Voters</b>: every device with the role votes, with limits that allow the job's claim time:
<code>policy.configure_voter(voter, kind)</code>, or <code>policy.voter(kind)</code> for a new one.</li>
<li><b>Claim</b>: <code>claim(id, |job| ...).await</code> takes the job's majority-vote lease (<code>kind/id</code>), with the
app's own check on top of the role and candidates. The <code>Claim</code> renews in the background and gives the
<code>term</code>, the checkpoint to <code>resume_from</code>, and <code>lost().await</code>, which says why the claim ended
(lease lost, superseded, paused or cancelled by the owner, released).</li>
<li><b>Work</b>: <code>checkpoint(CheckpointRef)</code> records a pointer (a content hash, its size and the devices holding a
copy; the app moves the bytes), <code>set_holders</code> updates who holds a copy, and <code>progress</code> keeps a small value,
written at most every 30 s. <code>fence()</code> gives a token to check against a resource's <code>FenceGuard</code>, so a holder
that lost its claim can't write.</li>
<li><b>End</b>: <code>finish(result)</code>, <code>fail(reason, retry)</code> or <code>pause()</code>. Dropping a claim releases it.</li>
</ol>
<p><code>JobPolicy</code> defaults: 60 s claims renewed every 20 s, a 300 s takeover wait, 3 attempts and a 60 s retry backoff. If a
holder disappears, voters wait out the takeover wait after its claim lapsed before another device may claim, so a short network
drop doesn't move a long job; the holder can renew back inside the wait. A failure with <code>retry</code> reopens the job after
the backoff until the attempts run out (lapsed claims count); pauses never count. The owner's <code>pause</code> and
<code>cancel</code> reach the holder, which stops and lets go; <code>resume</code> reopens a paused job. <code>get</code>, <code>list</code> (with a
<code>JobFilter</code>; jobs that ended more than 30 days ago are left out unless asked for), <code>checkpoints</code> (the last
eight) and <code>watch</code> (a stream of changes) read the board.</p>
<h3>More pages (0.3.0)</h3>
<p>When a task's page budget runs out, the session asks <code>Approver::extend_pages(&amp;PagesPrompt)</code> (the "+5 pages" card).
<code>PagesPrompt</code> has the agent, the task id, the pages used so far and the extension size (<code>Budget::page_extension</code>).
An answer of <code>true</code> adds one extension and the page is read; the next time the extended limit runs out it asks again, and
after a <code>false</code> it never asks again in that task. Waiting for the answer does not use the task's time. The default
implementation answers no, so existing approvers behave as before. <code>remote::task</code> does not forward this question yet, so a
remote task still stops at its page budget.</p>
<h3>Remote inference and remote tasks (0.2.0)</h3>
<p>The <code>remote</code> module has two protocols between one user's own nodes. The app supplies the transport: a
<code>Dialer</code> opens a <code>Channel</code> (a <code>FrameTx</code> and a <code>FrameRx</code>) to a node for a protocol id, and
the serving app must check that the caller is one of the user's linked devices before it calls <code>serve</code>. Messages are
JSON; <code>remote::codec</code> frames them on byte streams (a big-endian <code>u32</code> length, messages up to 32 MiB since 0.5.0, 8 MiB before), and
<code>MemoryDialer</code> and <code>memory_pair</code> are in-process channels for tests. Failures are a <code>RemoteError</code>:
unreachable, busy, refused, unavailable, failed, protocol, closed or timed out.</p>
<ul>
<li><b>Remote inference</b> (<code>remote::infer</code>, <code>/weirdnet-agent/infer/1</code>): offload one model turn. The asker
sends the messages and tool specs (and optionally a model id); the node answers <code>Accepted</code> with the model it
chose, streams <code>Delta</code> text, then <code>Done</code> with the turn, or <code>Failed</code> or <code>Cancelled</code>. A
<code>Cancel</code> can go the other way at any time. The serving app implements <code>InferHost</code> to open a
<code>ModelBackend</code> for the requested model, and <code>Admission::new(n)</code> limits concurrent turns; more are
answered <code>Busy</code>. If the asker goes away the turn is cancelled.</li>
<li><b><code>RemoteModel</code></b> is a <code>ModelBackend</code> over that protocol:
<code>RemoteModel::new(dialer, nodes).with_model(..).with_fallback(local).with_accept_timeout(..)</code>. It tries the nodes in
order, then the local fallback, whenever a node fails <em>before any token has streamed</em>: unreachable, busy, no such model, an
error, or no <code>Accepted</code> within the accept timeout (default 10 s). Once tokens have streamed, a failure is returned as
is, because the text already shown cannot be taken back. <code>last_route()</code> says where the last turn ran
(<code>Route::Node</code> with the node and model, or <code>Route::Fallback</code>), and the backend name in traces reads
<code>model@node</code>.</li>
<li><b>Remote tasks</b> (<code>remote::task</code>, <code>/weirdnet-agent/task/1</code>): run a whole agent task on another node
(Node companions). <code>task::run(dialer, node, request, events, approver, cancel)</code> sends a <code>TaskRequest</code> (the
companion's <code>AgentId</code>, the input and the conversation so far) and the node's <code>AgentSession</code> runs it, under
that node's tools, budget and policy. Its events come back as ordinary <code>AgentEvent</code>s, so an app's panel code is the
same as for a local session. When the session needs approval, the node sends an <code>Ask</code> and the card is answered by the
<code>Approver</code> on the asking device; a lost asker denies. The <code>CancelToken</code> stops the task there (the asker
waits 5 s for the node to wind down). The result is a <code>RemoteOutcome</code> with the <code>Outcome</code> and the updated
conversation: the history lives with the asker, which sends it with each task. The serving app implements <code>TaskHost</code>
to build a session for the companion, and refuses companions that do not run there.</li>
</ul>
<p>Inference (weirdnet-model) and MCP client transports (weirdnet-mcp) implement this crate's traits in their own crates. Since
0.4.0 the <code>pool</code> and <code>serve</code> features wire the protocols to weirdnet-net streams; apps can still supply
their own <code>Dialer</code>.</p>
<h3>Inference v2 (0.4.0)</h3>
<p><code>/weirdnet-agent/infer/2</code> (<code>remote::infer::v2</code>) carries CBOR frames; <code>/weirdnet-agent/infer/1</code>
stays JSON and is still served, so 0.3 nodes keep working. A <code>Request</code> has an id, an optional <code>job_id</code> and
<code>attempt</code>, a model, a <code>Priority</code> (<code>Interactive</code> by default, <code>Batch</code> or
<code>Background</code>), the input (inline messages, or a <code>context_ref</code> to a stored conversation), sampling settings,
a seed, a <code>response_format</code> (text, JSON or a JSON schema), tools, and <code>raw</code> for a node that should skip
its own prompt handling. Optionally it carries an assistant prefix and its length in characters: the part of the answer already
shown, which a node continues from.</p>
<ol>
<li>The node checks the caller (see below). When all its slots are busy it answers <code>Queued{position}</code> and repeats it
every few seconds; each one resets the asker's accept timeout, so a queued request is not mistaken for a dead node. Higher
priorities go first; a full queue answers <code>Busy</code>.</li>
<li><code>Accepted</code> names the model and says whether the node can resume from a prefix.</li>
<li><code>Delta</code> (text), <code>Reasoning</code> and <code>ToolCall</code> frames stream with their character offset in the
answer, then <code>Usage</code> and <code>Done</code> with the finish reason and metadata: the node that served it, queue and
first-token timings, and any resumes. <code>Cancel</code> can go the other way at any time.</li>
<li>Embedding requests get one <code>Embedding</code> frame per input, the vector as little-endian f32 in a CBOR byte string.</li>
</ol>
<p>Hosts implement <code>InferBackend</code> (and <code>EmbedBackend</code>); a plain <code>ModelBackend</code> is adapted.
<code>DeltaSink::reasoning</code> and <code>AgentEvent::ReasoningDelta</code> carry reasoning text to the app (task/1 does not
forward it).</p>
<h3>Answer cache per request (0.5.1)</h3>
<p><code>Request::cache</code> is a <code>CacheMode</code>: <code>use</code> (the default), <code>bypass</code> (the node neither
reads nor stores a cached answer, for evals and freshly fine-tuned weights) or <code>refresh</code> (skip the read, run the model
and store the fresh answer over the old one). Set it with <code>Request::with_cache</code>; <code>CacheMode::may_read</code> and
<code>may_store</code> say what a cache may do. Unlike <code>raw</code>, it keeps the node's context lookups and stand-ins. The
field is left off the wire when it is <code>use</code>, so older nodes read every request as before; nodes before 0.5.1 ignore
it and may still answer from their cache, which <code>Meta::cache_hit</code> reports. <code>Request::with_wait_for_model</code>
(0.5.1) sets <code>wait_for_model</code>.</p>
<h3>A pool as one model (0.5.3)</h3>
<p><code>remote::pool_model::PoolModel</code> turns a <code>Pool</code> of inference nodes (for example a
<a href="https://github.com/WeirdBrains/ymir">Ymir</a> cloud on the user's own devices) into one <code>ModelBackend</code>, so an
agent app runs its turns there like on a local model. Text and reasoning stream to the <code>DeltaSink</code>, tool calls come
back in the turn, and cancel stops the node. A node that dies mid-answer is resumed on another one, shown as
<code>ModelNotice::Continued</code>; when the chosen model can't read a turn's images or audio, the pool picks one that can, shown as
<code>ModelNotice::Rerouted</code> (on by default; <code>with_reroute(false)</code> refuses the turn instead). When the
pool can't take a turn before any text has streamed, an optional fallback, usually the local model (<code>with_fallback</code>),
runs it, shown as <code>ModelNotice::FellBack</code>; without one the error is <code>ModelError::PoolUnreachable</code>. Notices
reach the app as <code>AgentEvent::ModelNotice</code> through <code>DeltaSink::notice</code>.</p>
<p><code>PoolWatch</code> follows the pool catalog (catalog/1 subscribe) as a <code>PoolStatus</code> for a model picker: live,
searching or unreachable, with each model's state and speed. It knows which nodes answered (<code>CatalogNodes</code>, a
<code>NodeSource</code> through <code>PoolWatch::nodes</code>), so turns go only to real inference nodes, and
<code>PoolWatch::retry</code> asks the nodes again now instead of after the backoff.</p>
<h3>Origin and license (0.5.4)</h3>
<p>Catalog entries can say where a model came from and its license: <code>CatalogModel::origin</code> (<code>ORIGIN_HUB</code>,
<code>ORIGIN_UPLOAD</code> or <code>ORIGIN_TRAIN</code>, as in a <a href="/crates/model">weirdnet-model</a> provenance record) and
<code>license</code>, set with <code>with_origin</code> and <code>with_license</code>. Both are left off the wire when unset.</p>
<h3>LoRA adapters (0.5.2)</h3>
<p>A model node can serve LoRA adapters on a base model (<a href="/crates/backends">weirdnet-backends</a> 0.4), each under its own
model id. <code>CatalogModel::base</code> names an adapter's base model (set with <code>with_base</code>; <code>is_adapter</code>
tests it), so an app can show the adapter as a variant of the base; requests still name the adapter's id.
<code>Request::adapter_scale</code>, set with <code>with_adapter_scale</code>, is how strongly the requested adapter applies for
this request on nodes that scale per request (llama.cpp); <code>None</code> keeps the adapter's own scale, and base models ignore
it. Neither field is sent when unset, and nodes and catalogs from 0.5.1 and earlier ignore or lack them.</p>
<h3>Pool, failover and resume (0.4.0)</h3>
<p><code>remote::pool::Pool</code> runs a request across nodes from a <code>NodeSource</code>, best first. It moves to the next
node when one is unreachable, busy, refuses, lacks the model or does not accept in time, and uses infer/1 with nodes that do not
serve infer/2. Once a stream has started, the pool cancels it when no frame arrives for <code>max(15 s, 3 &times; the recent
gap between tokens)</code> (25 s at most, and 25 s for the first token), under weirdnet-net's 30 s stream resume window. It then
resumes on a node that supports it: the same <code>job_id</code> and seed, the next <code>attempt</code>, and the text already
shown as the prefix. Frames are placed by offset, so nothing is shown twice, and a gap fails that attempt. At most two resumes
per answer by default; if nothing can take over, the partial answer comes back with the error.</p>
<p>The pool also runs embeddings, background jobs (<code>submit</code> returns a <code>Job</code> to watch, wait for or cancel), and
catalog queries and subscriptions (<code>/weirdnet-agent/catalog/1</code>: each model's purpose, state, replicas, speed and
context) that move to another node when one goes away. <code>RemoteModel</code> is a thin <code>ModelBackend</code> over a pool;
resume is opt-in there (<code>with_resume(true)</code>).</p>
<h3>Continuing an answer (0.4.2)</h3>
<p>When the user stops an answer or it is cut off, a Continue button can send the same conversation with the partial answer as
the request's <code>assistant_prefix</code>: the model carries on from that text (assistant prefill: llama.cpp continues a trailing
assistant message, vLLM gets <code>continue_final_message</code>). <code>Request::continuing()</code> builds such a request from
messages that end in an assistant message without tool calls. The wire is unchanged: it is the same prefix a resume uses.</p>
<ul>
<li>Only nodes whose <code>Accepted</code> says <code>resume: true</code> take it; others, and infer/1 nodes, are skipped as
<code>Unsupported</code>. With none left, the error comes back with the prefix as the partial answer.</li>
<li>The <code>Answer</code> starts from the prefix: <code>text</code> and <code>reasoning</code> include it, <code>Answer::prefix</code>
is what was given and <code>Answer::continuation()</code> the text after it. Events carry only the new text.</li>
<li>Failover keeps the prefix, whether or not resume is on; if a node dies part-way, the next one resumes from everything shown,
and that resume is recorded in <code>Meta::resumes</code> as usual.</li>
</ul>
<h3>Images and audio (0.5.0)</h3>
<p><code>Message::content</code> is a <code>Content</code>: text, or OpenAI-style parts. <code>ContentPart::text</code>,
<code>ContentPart::image</code> (an <code>image_url</code> with a <code>data:image/...</code> URL) and <code>ContentPart::audio</code>
(<code>input_audio</code> with base64 data and a format) build them; <code>Message::user</code> takes a string or a list of parts.
Text still goes on the wire as a plain string, so text-only messages reach 0.4 peers as before; parts need 0.5 on both ends.
<code>Message::text()</code> gives the text alone, and <code>Message::needs()</code> / <code>Request::needs()</code> the
<code>Modalities</code> (vision, audio) a model must take.</p>
<h3>Routing by input (0.5.0)</h3>
<p>Catalog entries say which inputs beyond text a model takes (<code>CatalogModel::inputs</code>, set with
<code>with_inputs</code>; entries without it are text-only). <code>Catalog::route(model, needed)</code> picks the model for a
request: a named model must take the request's inputs, and with no model it picks one that does. The pool routes with it, so an
image or audio request never lands on a text-only model: a named model that can't read it, or a pool with no model that can, is a
<code>BadRequest</code> before any node runs it. Requests with parts skip infer/1 nodes, and a model node refuses parts its model
can't take, so a pool moves on. Model nodes from <a href="/crates/backends">weirdnet-backends</a> 0.2 report these inputs
(<code>Capabilities::inputs</code>).</p>
<h3>Serving inference to linked devices (0.4.0)</h3>
<p>The serving side gets a <code>Caller</code>: the transport-authenticated peer plus any certificate the request presented.
<code>InferHost::authorize</code> and <code>CatalogHost::authorize</code> run before anything else; a refusal is sent with its reason.
With the <code>serve</code> feature, <code>serve::RosterAuth</code> does this with weirdnet-sync's
<a href="/crates/sync">caller check</a>, and <code>Server::start(&amp;node, Serving { infer, catalog, announce })</code> accepts
infer/1, infer/2 and catalog/1 streams and announces the node as an inference node. With the <code>pool</code> feature,
<code>pool::connect(node, roster, Some(&amp;my_cert))</code> builds a pool over <code>LinkedNodes</code>: the roster's active devices
that announce inference, direct connections first.</p>
<h3>Device roles and tasks (0.4.4)</h3>
<p><code>RosterAuth::require_roles(&amp;["ymir.inference"], roles)</code> admits only linked devices the user granted one of the
roles (the signed grants in the <a href="/crates/sync">weirdnet-sync</a> 0.7 roster: <code>roles</code> is
<code>|peer| roster.roles_of(peer)</code>); others are refused with <code>role</code>. Never authorize on a certificate label,
which is not signed. <code>Authorize::admit</code> returns <code>Admitted { peer, roles }</code>, and
<code>Server::start_with(node, serving, ServingExtras::default().tasks(host, auth))</code> serves task/1 next to inference: each
task is admitted first and built by <code>TaskHost::session_for(&amp;admitted, ..)</code>, so a host can scope tools per device
or role, and the <code>INFERENCE_APP</code> announcement then lists task/1. All of it is additive; the <code>pool</code> and
<code>serve</code> features accept weirdnet-sync 0.5.2 to 0.7 (to 0.8 since 0.5.5). 0.4.3 stopped offline devices from slowing every request.</p>
<h3>Moving to 0.5.0</h3>
<ul>
<li><b>Message content</b>: <code>Message::content</code> is a <code>Content</code>, not a <code>String</code>. Constructors take
<code>impl Into&lt;Content&gt;</code>, so <code>Message::user("hi")</code> is unchanged; where code reads <code>m.content</code> as
text, use <code>m.text()</code> (or <code>m.content.text()</code>). <code>AgentSession::run</code> takes <code>impl Into&lt;Content&gt;</code>.</li>
<li><b>Inference nodes</b>: put each model's inputs in its catalog entry (<code>CatalogModel::with_inputs</code>, from
weirdnet-backends' <code>Capabilities::inputs()</code>), or image and audio requests will find no model to route to.</li>
<li><b>Dependents</b>: move together with <a href="/crates/backends">weirdnet-backends</a> 0.2.0,
<a href="/crates/openai">weirdnet-openai</a> 0.2.0 and <a href="/crates/model">weirdnet-model</a> 0.5.0;
<a href="/crates/mcp">weirdnet-mcp</a> 0.5.3 takes agent 0.4 or 0.5.</li>
</ul>
<h3>Moving to 0.4.0</h3>
<ul>
<li><b>Serving inference</b>: implement <code>InferHost::authorize(&amp;self, caller: &amp;Caller)</code> (for Weirdnet,
<code>RosterAuth</code>); <code>InferHost::open</code> is now <code>open(&amp;self, caller: &amp;Caller, model: Option&lt;&amp;str&gt;)</code>
and <code>infer::serve</code> is <code>serve(channel, caller: &amp;Caller, host, admission)</code>. The caller check that apps did before
calling <code>serve</code> now lives in <code>authorize</code>.</li>
<li><b>Enums are <code>#[non_exhaustive]</code></b>: add a wildcard arm where you match <code>AgentEvent</code> (new:
<code>ReasoningDelta</code>), <code>RemoteError</code> (new: <code>Unsupported</code>, <code>BadRequest</code>, <code>Cancelled</code>,
<code>Stalled</code>; infer/1 sends them as <code>failed</code>), <code>Role</code>, <code>ModelError</code> and the others.</li>
<li><b><code>RemoteModel</code></b> keeps its API; it now tries infer/2 first and falls back to infer/1, so it works with 0.3 nodes.</li>
<li>weirdnet-model 0.4.0 and weirdnet-mcp 0.5.0 move their <code>agent</code> features to weirdnet-agent <code>=0.4.0</code>; move all
three together.</li>
</ul>
<h3>Moving to 0.3.0</h3>
<ul>
<li><b>No source changes</b> are needed: the new API is additive (<code>ToolTimer</code>, <code>PagesPrompt</code>,
<code>BudgetTracker::time_tool</code> and <code>wall_elapsed</code>, and <code>Approver::extend_pages</code>, which has a default body).
The wire protocols are unchanged: <code>/weirdnet-agent/infer/1</code> and <code>/weirdnet-agent/task/1</code>, so 0.2 and 0.3
nodes still talk to each other.</li>
<li><b>Behaviour change:</b> <code>Budget::per_task</code> now counts tool time only, not wall-clock time. A task can run longer than
<code>per_task</code> in wall time, because model turns and approval waits no longer count. If you relied on it as a deadline,
cancel with your own timer (use <code>wall_elapsed</code> to show elapsed time).</li>
<li>To offer "+5 pages", implement <code>Approver::extend_pages</code>.</li>
<li>weirdnet-model 0.3.0 and weirdnet-mcp 0.4.0 move their <code>agent</code> features to weirdnet-agent <code>=0.3.0</code> (breaking for
<code>agent</code> users only; no source changes). An app that uses <code>LocalModel</code> or <code>McpSource</code> moves all three together; versions
before those still pin <code>=0.2.0</code> and can't be mixed with agent 0.3.</li>
</ul>
''',
    features: [
      '<code>pool</code> (0.4.0): the pool over <a href="/crates/net">weirdnet-net</a> 0.8: <code>LinkedNodes</code> finds inference nodes among the user’s linked devices (<a href="/crates/sync">weirdnet-sync</a> 0.5 to 0.8 roster; 0.8 since 0.5.5), <code>NetDialer</code> opens streams, <code>connect</code> builds the <code>Pool</code>.',
      '<code>serve</code> (0.4.0): <code>Server</code> serves infer/1, infer/2 and catalog/1 on a weirdnet-net node and announces it; <code>RosterAuth</code> admits only linked devices.',
      '<code>jobs</code> (0.5.6): synced jobs over the weirdnet-sync 0.8.2 job log (<code>JobBoard</code>, <code>Claim</code>, <code>JobPolicy</code>); pulls in weirdnet-net and weirdnet-sync like <code>pool</code>.',
      '<code>testing</code>: <code>ScriptedModel</code>, <code>ScriptedApprover</code> and <code>FnTool</code> for tests in downstream crates (the example below uses them).',
    ],
  ),
  'model': Guide(
    brings: r'''
<p>Run a small language model on the user's own machine, for any <a href="https://weirdbrains.com">WeirdBrains</a> app, without each app writing its own download,
checksum and inference plumbing. Nothing downloads until the user has agreed to that exact model, and llama.cpp and the agent
backend are optional features, so a build that only needs the catalog and downloads has no native dependencies.</p>
''',
    works: r'''
<h3>Get a model</h3>
<p><code>catalog</code> holds the Gemma 4 E2B (phones, small laptops) and E4B (desktop) GGUF defaults with repo, file, size and
checksum, and <code>catalog::default_for(Device)</code> picks one. <code>ModelStore</code> is a cache directory
(<code>WEIRDNET_MODELS_DIR</code> overrides it). <code>download</code> needs a <code>Consent</code> for exactly that model, reports
<code>Progress</code>, resumes from a <code>.part</code> file and verifies the SHA-256. <code>hf</code> lists a repo's GGUF files
and sizes for a model picker.</p>
<h3>Find a model that fits (0.5.1)</h3>
<p><code>hf::Hub</code> searches the Hugging Face Hub for GGUF repos (<code>Search</code>, <code>SearchHit</code>) and groups a repo's
files into models: split GGUFs (<code>-00001-of-00003.gguf</code>) become one model with their parts, and the quantization is read
from the file name (<code>RepoModel</code>, <code>group_files</code>, <code>quant_of</code>). <code>gguf_info</code> reads a file's
header with a <code>Range</code> request, and <code>gguf::read_info</code> gives the fields that size the KV cache.
<code>fit::choose</code> picks the largest file whose weights and KV cache fit a <code>hw::Budget</code> for the context and slots
asked for, and <code>fit::rank</code> measures every file against it; without a header the KV cache is estimated from the file size.
<code>download_parts</code> fetches every part of a split model under one consent, and <code>ModelStore::list</code> and
<code>remove_local</code> show and delete what is on disk.</p>
<p>A Hugging Face token (<code>HfToken</code>) is read on the machine that downloads, from <code>HF_TOKEN</code>,
<code>HUGGING_FACE_HUB_TOKEN</code> or a token file. <code>ModelStore::from_env</code> sends it to the public Hub only, never to another
host; <code>ModelStore::with_token</code> sets one for any Hub.</p>
<h3>LoRA adapters (0.5.2)</h3>
<p>A GGUF can hold a model or a LoRA adapter. <code>gguf::read_header</code> returns a <code>GgufHeader</code> whose <code>GgufKind</code>
is <code>Model</code>, <code>Adapter { adapter_type, alpha }</code> or, since 0.5.3, <code>Projector</code>, and <code>Hub::gguf_header</code> reads it from the Hub with a
<code>Range</code> request. <code>Hub::adapters</code> lists a repo's adapter files as <code>RepoAdapter</code>s, GGUF LoRA or PEFT
(<code>AdapterFormat</code>), with the base model hinted from the repo (<code>hf::adapter_hint</code>); <code>Search::with_adapters</code>
finds adapter repos and marks them in <code>SearchHit::adapter</code>. <code>download_adapter</code> needs
<code>Consent::given_adapter</code> for that adapter and saves it under <code>adapters/&lt;id&gt;/</code> with an
<code>adapter.json</code>; <code>ModelStore::adapters</code> lists the <code>StoredAdapter</code>s on disk and <code>remove_adapter</code>
deletes one. Adapters never show up in <code>Hub::models</code>, <code>fit</code>, <code>ModelStore::list</code> or plain searches, so a
model picker doesn't offer them as models. <a href="/crates/backends">weirdnet-backends</a> 0.4 serves them on a base model.</p>
<h3>Import local files (0.5.3)</h3>
<p>Models trained or converted on the user's machine come in through <code>artifact::inspect</code>: it reads and hashes local
files (GGUF models, split models, LoRA adapters and vision projectors; safetensors and MLX model directories; PEFT adapters),
reads their headers, and refuses pickles, code and symlinks. The <code>Artifact</code> it returns has an <code>ArtifactKind</code>,
an <code>ArtifactFormat</code>, the <code>ArtifactFile</code>s with their SHA-256s, and a content <code>revision</code> that is the
same wherever the same files are. <code>ModelStore::import</code> (and <code>import_replacing</code>, <code>import_with</code>,
<code>import_files</code>) checks the files again and places them atomically, GGUFs as before and directories under
<code>safetensors/&lt;id&gt;/</code>, <code>mlx/&lt;id&gt;/</code> or <code>projectors/&lt;id&gt;/</code>, with a
<code>provenance.json</code>: a <code>Provenance</code> (<code>weirdnet-provenance/1</code>) naming the origin (upload, training or
the Hub), the base model, the dataset, the trainer and the app. <code>StoredModel::provenance</code> and
<code>StoredAdapter::provenance</code> read it back; <code>dir_models</code>, <code>projectors</code> and
<code>remove_projector</code> list and delete the new layouts. <code>free_bytes</code> and <code>disk_space</code> say how much room
is left, and <code>bytes_by_origin</code> how much is stored from one origin, for quotas.</p>
<h3>Run it</h3>
<p><code>Worker</code>: one thread owns the <code>Engine</code>; <code>Worker::generate</code> returns a <code>Generation</code>
that streams <code>Chunk</code>s and can be cancelled from any thread. <code>prompt</code> renders chat turns through the model's
own chat template and parses <code>&lt;tool_call&gt;</code> tags into tool calls as they stream. With the <code>agent</code> feature,
<code>agent::LocalModel</code> implements <code>weirdnet_agent::ModelBackend</code>, so the <a href="/crates/agent">agent loop</a> can
run on a local model. Since 0.5.0 (weirdnet-agent 0.5) it reads text parts and refuses messages with images or audio. Tests use a mock <code>Engine</code> and never download a model.</p>
<h3>Hardware and sizing (0.4.0)</h3>
<p><code>hw::detect()</code> reports the OS, CPU threads, system memory and GPUs: NVIDIA through <code>nvidia-smi</code> (name, memory,
compute capability, driver), AMD through sysfs, and Apple silicon. Devices that share system memory (Apple, GB10, AMD APUs) are
marked unified. It never fails; a missing tool means fewer devices.</p>
<p><code>hw::budget(&amp;hw, memory_budget, reserve)</code> is the memory models may use: 85% of VRAM, or 85% of unified memory after an
OS reserve (an eighth of RAM, at least 4 GiB). Both can be overridden. <code>hw::catalog()</code> is a tiered list from SmolLM2 135M
through Gemma 4 E2B and E4B, Qwen3 8B, 14B, 30B-A3B and 32B and gpt-oss 20B, plus Qwen3 Embedding 0.6B and (since 0.5.4) Voxtral Mini 3B for speech to text. Each entry has a pinned
<code>ModelSpec</code> (so it downloads through the consent gate) and a footprint: the file, the KV cache for its context and slots,
and 10% headroom. <code>hw::plan(&amp;hw, budget)</code> picks the largest chat model that fits, a Gemma 4 stand-in and the embedding
model. CPU-only machines only get models with at most 4B active parameters, so answers stay usable.</p>
<h3>Speech to text (0.5.4)</h3>
<p>Every catalog entry has a <code>Purpose</code>, its role on a node: <code>chat</code>, <code>embedding</code> or
<code>transcribe</code> (<code>Purpose::as_str</code> and <code>Purpose::parse</code> give the names). The <code>transcribe</code>
entry is <a href="https://huggingface.co/ggml-org/Voxtral-Mini-3B-2507-GGUF">Voxtral Mini 3B</a> (<code>hw::VOXTRAL_MINI_3B</code>,
Q4_K_M), which llama.cpp runs with its audio encoder: <code>CatalogEntry::projector()</code> is that pinned <code>mmproj</code> file,
downloaded through the same consent gate and counted in <code>footprint</code>. Audio goes in as an <code>input_audio</code> part
and the transcript comes back as text, so a soundtrack can become text for models without audio. <code>hw::plan</code> never
proposes it; <code>hw::transcriber(&amp;budget)</code> returns it when it fits, and <code>hw::by_purpose</code> lists entries by role.</p>
<h3>Model limits (0.5.4)</h3>
<p>A client fitting images, audio or a video's frames to a model needs that model's limits, and none are defaulted: what isn't
known stays absent. <code>ModelLimits</code> holds the context the model runs with on the node (per slot, not the trained context),
images per request, what an image costs (a fixed number, or one token per <code>image_patch</code> pixels square up to
<code>image_tokens</code>), the longest image edge, audio length and cost (<code>audio_tokens_per_minute</code>, and
<code>audio_chunk_seconds</code> with <code>audio_chunk_tokens</code> for encoders that take 30-second pieces, so a short clip costs a
whole piece), <code>video_max_seconds</code>, <code>video_max_bytes</code> and <code>max_request_bytes</code>. <code>or</code> puts an
operator's settings over measured ones, <code>tightest</code> merges copies, and <code>image_cost</code> and <code>audio_cost</code>
price one input. With the <code>agent</code> feature, <code>to_media</code> and <code>from_media</code> convert to and from
<a href="/crates/agent">weirdnet-agent</a>'s <code>MediaLimits</code> for catalog entries.</p>
<p>When a node loads a model, <code>limits::measure(model, projector, context)</code> reads the GGUF and its projector into a
<code>LimitsRecord</code> (<code>weirdnet-limits/1</code>): what the projector's header says images and audio cost
(<code>from_projector</code>, from <code>gguf::ProjectorInfo</code>; Gemma 3 images cost 256 tokens, Qwen-VL one token per 28 pixels
square, Voxtral and Ultravox 187 tokens per 30 seconds of audio, Qwen2 audio 750), the context passed in and the trained context for
reference. Other projector types are left absent. <code>ModelStore::record_limits</code> keeps the record next to the model's files,
<code>StoredModel::limits</code> reads it back until the files change size, and <code>remove_local</code> deletes it with the model.
<code>LlamaEngine::limits</code> gives the context the engine runs with.</p>
<h3>CPU support (0.2.0)</h3>
<p>llama.cpp's build turns on AVX, AVX2, BMI2, FMA and F16C by default, so a plain <code>llama</code> build only runs on x86 CPUs that
have them (roughly Haswell and Excavator, 2013 to 2015, and later). Two things keep older CPUs from crashing with an illegal
instruction:</p>
<ul>
<li><b>The guard, always on.</b> <code>build.rs</code> works out which instructions the linked llama.cpp contains.
<code>LlamaEngine::load</code> calls <code>cpu::check()</code> first and returns <code>Error::UnsupportedCpu { missing }</code> on a CPU
without them; <code>llama::describe()</code> then says <code>llama.cpp (unsupported CPU)</code>. An app can call
<code>cpu::check()</code> itself to hide local models, or to offer another machine instead.</li>
<li><b><code>cpu-dispatch</code>, for release binaries that should run local models on any CPU.</b> ggml is built once per CPU
level (x86 from baseline x86-64 up to the AVX-512 levels; ARM from armv8.0 to armv9.2, Apple M1 to M4) and each library is asked at
load time whether this CPU can run it, keeping the best. Speed on a modern CPU matches the static build. The price: llama.cpp
becomes shared libraries the app must ship, and without them the app does not start at all.</li>
</ul>
<p>What to ship with <code>cpu-dispatch</code>: <code>libllama</code>, <code>libllama-common</code>, <code>libggml</code> and
<code>libggml-base</code>, which the executable links against (point its rpath at them on Linux and macOS, or put the DLLs next to
the <code>.exe</code> on Windows), and one <code>libggml-cpu-&lt;level&gt;</code> library per level, plus <code>libggml-vulkan</code> or
<code>libggml-metal</code> with those features. They load from <code>llama::backends_dir()</code>: the directory given to
<code>llama::set_backends_dir</code>, else <code>WEIRDNET_GGML_BACKENDS_DIR</code>, else the executable's directory; the working
directory is never searched. If none loads, loading a model fails with <code>Error::NoCpuBackend</code>. The README's measured
example on x86-64 Linux is a 4.3 MB executable plus 35 MB of libraries, against 9.4 MB for the static example.</p>
<p>Without <code>cpu-dispatch</code>, a static build can run everywhere at a speed cost by building ggml for an older level, for
example <code>GGML_AVX=OFF GGML_AVX2=OFF GGML_BMI2=OFF GGML_FMA=OFF GGML_F16C=OFF</code> (SSE4.2 and later); the guard follows those
variables. ARM builds need nothing. Don't use <code>target-cpu=native</code> for anything you distribute.</p>
<div class="callout warn"><b>Known build limits (README, 0.2.0).</b> <code>llama-cpp-sys-2</code> 0.1.161's shared-library build
fails with Rust 1.100's build directory layout, so build <code>cpu-dispatch</code> with Rust 1.99 for now. A second build in the same
target directory can fail with "File exists" on the library symlinks; deleting the <code>lib*.so*</code> symlinks under
<code>target/&lt;profile&gt;/</code> between builds avoids it. The static <code>llama</code> build has neither problem.</div>
''',
    features: [
      '<code>llama</code>: <code>LlamaEngine</code> on llama.cpp, CPU. Needs cmake and a C++ compiler to build.',
      '<code>cpu-dispatch</code> (implies <code>llama</code>): llama.cpp for every CPU level, chosen at run time; the app ships the shared libraries.',
      '<code>vulkan</code>, <code>metal</code> (imply <code>llama</code>): GPU offload.',
      '<code>agent</code>: <code>agent::LocalModel</code>, a <code>weirdnet_agent::ModelBackend</code>, and <code>ModelLimits</code> conversions to <code>MediaLimits</code> (weirdnet-agent <code>"0.5.7"</code> since 0.5.4; <code>"0.5"</code> in 0.5.0 to 0.5.3; <code>"0.4"</code> in 0.4.2 and 0.4.3; <code>=0.4.0</code> in 0.4.0 and 0.4.1; <code>=0.3.0</code> in 0.3.0, <code>=0.2.0</code> in 0.2.1).',
    ],
  ),
  'backends': Guide(
    brings: r'''
<p>Use weirdnet-backends on a machine that runs models for the user's other devices. It wraps llama.cpp's <code>llama-server</code>,
<code>vllm serve</code> and, on Apple silicon, MLX-LM's <code>mlx_lm.server</code> (or a stock OpenAI-compatible server already running on loopback) and keeps them healthy, so
inference nodes only have to say what should be loaded and send requests.</p>
<ul>
<li><b>Engines handled</b>: loopback-only ports, a per-process API key in the environment, readiness probes, logs.</li>
<li><b>Memory handled</b>: swap groups so models that share a GPU never load together, and idle unload.</li>
<li><b>Failures handled</b>: restarts with backoff, crash loops reported rather than retried forever.</li>
<li><b>One protocol</b>: signed capability records and commands over <code>weirdnet-net</code>, inference over infer/2.</li>
</ul>
''',
    works: r'''
<h3>The supervisor</h3>
<p><code>Supervisor::new(engines, models, options)</code> knows every model the node may run (<code>ModelLaunch</code>: id, engine,
GGUF path or Hugging Face id, context, slots, GPU layers, swap group, idle timeout, extra flags, or a <code>Wrap</code>).
<code>load</code> picks a free loopback port and a random API key, starts the engine in its own process group, and polls
<code>/health</code> until it answers; loading a model in a swap group first drains and stops the group's other models. Load and
unload are serialized, so swaps never interleave. <code>unload</code> waits for requests under way (up to <code>drain_timeout</code>),
then stops the engine: SIGTERM, then SIGKILL after <code>stop_grace</code>. A crash while serving restarts the engine after a backoff
that doubles per crash; <code>max_crashes</code> within <code>crash_window</code> is a crash loop, and only a forced load starts it
again. Everything that happens is a <code>SupervisorEvent</code>.</p>
<h3>Serving infer/2</h3>
<p><code>ModelHost</code> is a <code>weirdnet-agent</code> <code>InferHost</code>. Each request names a model (or gets the default); the
request becomes an OpenAI streaming body for the engine (an assistant prefix becomes a trailing assistant message, with
<code>continue_final_message</code> on vLLM), and the engine's server-sent events become infer/2 text, reasoning and tool-call
frames. Cancelling the request drops the engine stream. Model nodes serve raw infer/2 only: the inference node has already
assembled the messages. Since 0.1.1 raw prompts go to the engine's <code>/v1/completions</code>.</p>
<h3>Images and audio (0.2.0)</h3>
<p>weirdnet-agent 0.5 content parts (<code>image_url</code> with a <code>data:</code> URL, <code>input_audio</code>) go to llama.cpp
unchanged, in the OpenAI shape. <code>ModelLaunch::capabilities</code> derives what a model takes: llama.cpp models launched
with a multimodal projector (<code>--mmproj</code>) take images and audio, vLLM and MLX-LM models are text only, and embedding
models only embed. <code>ModelHost</code> refuses parts the model's <code>Capabilities</code> lack (<code>Unsupported</code>,
so a pool tries another node) and remote image URLs (<code>BadRequest</code>). An inference node puts
<code>Capabilities::inputs()</code> in the model's catalog entry (<code>CatalogModel::with_inputs</code>), so the pool routes
image and audio requests to it.</p>
<h3>Its own protocol id (0.1.1)</h3>
<p>An inference node serves <code>/weirdnet-agent/infer/2</code> to apps, so a machine that is both an inference node and a model node
could not also take raw infer/2 for its models on the same id. 0.1.1 gives raw inference its own id,
<code>/weirdnet-backends/infer/1</code> (<code>RAW_INFER_PROTOCOL</code>), with the same infer/2 framing. <code>NodeServer</code> always serves
it and lists it in the <code>weirdnet-backends-node</code> announcement; it keeps serving infer/2 too, for 0.1.0 inference nodes, unless
<code>NodeServer::start_with(.., NodeServerOptions::default().with_legacy_infer2(false))</code> leaves infer/2 to the inference role.
On the inference node, wrap the dialer of the model-node <code>Pool</code> in <code>RawInferDialer</code>: infer/2 opens try the new id
first and fall back to infer/2 on a node that doesn't accept it, remembering that node. Inference nodes on 0.1.0 keep working
against 0.1.1 model nodes as they are.</p>
<h3>node/1</h3>
<p>A <code>Capability</code> record lists the hardware and memory budget (<code>weirdnet-model</code> <code>hw</code>), the engines, every
configured model with its state, revision, quantization, context and slot limits, load-time estimate and measured speed, the
load (queued, active, slots, in flight), warm prefix hashes, swap groups, and the draining and group-job flags. The node signs
the CBOR record with its own key; the record carries the user's <code>NodeCert</code> for that node, an increasing sequence number
and a 90 second expiry. Subscribers get one at once, every 15 seconds and on every change; <code>Verifier</code> checks the
signature, that the signer is the peer on the stream, the expiry and the user's certificate, and <code>Subscription</code> rejects a
sequence that goes backwards. Withdrawal ends subscriptions.</p>
<p>Commands are one per stream: <code>Load</code> (waits until ready), <code>Unload</code>, <code>Drain</code> (stops new requests and
waits for those under way), <code>GroupUp</code>/<code>GroupDown</code> and <code>Health</code>. Who may send them is an
<code>Authorize</code> hook; <code>RosterAuth</code> admits the user's linked devices.</p>
<h3>Managing models (0.3.0)</h3>
<p><code>Supervisor::add_model</code> and <code>remove_model</code> serve a new model, or stop serving one, without restarting the node
(<code>SupervisorEvent::Added</code>, <code>Removed</code>). With the <code>node</code> feature, <code>models::ModelsService</code> serves
<code>/weirdnet-backends/models/1</code> to the node's owner only: it takes an <code>Authorize</code> such as <code>RosterAuth</code>
(the owner's linked devices, narrowed with <code>require_roles</code>). Commands are <code>Search</code> (GGUF repos on the Hugging
Face Hub), <code>Files</code> (a repo's models, each measured against the node's memory budget), <code>Pull</code> (download with
progress, resuming a partial file, split GGUFs too; with no file named, the largest that fits), which can hand the model to the
supervisor to serve or load, <code>List</code> and <code>Remove</code>. Closing a pull's stream cancels it. The Hugging Face token is
the node's own (<a href="/crates/model">weirdnet-model</a> <code>HfToken</code>) and never crosses the wire.
<code>ModelsServer::start</code> serves it on a <code>weirdnet-net</code> node; <code>ModelsClient</code> is the owner's side.</p>
<h3>LoRA adapters (0.4.0)</h3>
<p>A <code>LoraAdapter</code> (an id, a path and an optional scale) is served on a base model: <code>ModelLaunch::with_adapters</code>
adds them, <code>served_ids</code> lists the base and adapter ids, and <code>check_adapters</code> checks them before a load: on llama.cpp it reads
each file's GGUF header through <a href="/crates/model">weirdnet-model</a> and takes only LoRA adapters with the base's architecture;
on vLLM an adapter is a PEFT LoRA directory or a Hub id. A request names either the base or an adapter;
<code>openai::Target</code> is <code>Base</code> or <code>Adapter</code>, and <code>chat_body_for</code> and <code>completion_body_for</code>
write the engine body for it. llama.cpp starts with one <code>--lora</code> per adapter and <code>--lora-init-without-apply</code>, and
each request carries a <code>lora</code> list that turns on only its adapter; vLLM starts with <code>--enable-lora</code>, one
<code>--lora-modules</code> list and <code>--max-loras</code>. <code>Supervisor::add_adapter</code> and <code>remove_adapter</code>
return an <code>AdapterChange</code>: <code>Live</code> when it applies now, <code>NextLoad</code> when it waits for the next load.
<code>ModelStatus::base</code> names the base model, and each adapter gets its own status row. On models/1, <code>Pull::adapter_for</code>
downloads an adapter for a base and <code>RepoFits::adapters</code> lists a repo's adapters.</p>
<p>0.4.0 is breaking: <code>ModelLaunch</code> is <code>#[non_exhaustive]</code>, so build it with <code>ModelLaunch::new</code> and the
<code>with_</code> methods; <code>StoredEntry::model</code> is an <code>Option</code>, with new <code>adapter</code> and <code>base</code>
fields; <code>StoredEntry</code> and <code>RepoFits</code> are no longer <code>Eq</code>; and weirdnet-model is always a dependency.</p>
<h3>Live adapters and scale (0.4.1)</h3>
<p>On vLLM, <code>add_adapter_live</code> and <code>remove_adapter_live</code> load and unload an adapter in the running engine
(the supervisor sets <code>VLLM_ALLOW_RUNTIME_LORA_UPDATING</code>), within <code>ModelLaunch::lora_slots</code>. On llama.cpp,
<code>set_adapter_scale</code> changes an adapter's strength without a restart, and a request can set its own with
<code>Request::adapter_scale</code> (weirdnet-agent 0.5.2; <code>complete_scaled</code>), capped at <code>MAX_ADAPTER_SCALE</code>.
vLLM applies adapters at full strength and refuses a scale. The owner's models/1 adds <code>ServeAdapter</code>,
<code>UnserveAdapter</code> and <code>AdapterScale</code>.</p>
<h3>Readiness (0.4.2)</h3>
<p>An engine counts as ready only when its <code>/v1/models</code> answers with the launch's API key and lists the launch's model id,
so another process that took the port first is never mistaken for it. A launch that lost its port starts again on a new one, up
to 3 times, without counting as a crash.</p>
<h3>Reservations (0.4.3)</h3>
<p><code>Supervisor::reserve(holder)</code> stops the node's engines and holds its accelerators for one holder, returning a <code>Reservation</code>;
while it lasts every load is refused, forced ones too, until <code>release(holder)</code>. <code>reservation_changes</code> watches it. On node/1,
<code>Command::Reserve</code> and <code>Release</code> (<code>NodeClient::reserve</code> and <code>release</code>) do the same remotely, and
<code>Capability::reserved</code> and <code>Health::reserved</code> tell routers to skip the node.</p>
<h3>Uploads and copies (0.4.4)</h3>
<p>The owner can send local files to a model node over models/1. <code>ModelsClient::upload</code> takes what
<a href="/crates/model">weirdnet-model</a>'s <code>artifact::inspect</code> read and sends <code>ModelsCommand::Upload</code> with the
file list, sizes, SHA-256s and a <code>Provenance</code>. The node checks names, size, quota, free disk, the engine and, for
adapters and projectors, the base, then answers <code>UploadReady</code> with the bytes it already holds of each file; the client
sends <code>UploadFrame::Chunk</code>s of at most 48 KiB (<code>CHUNK</code>) from there. Each GGUF or safetensors header is checked
as soon as it arrives, so a wrong file is refused early. At the end the node checks every size, SHA-256 and header, places the
entry with <code>ModelStore::import_files</code>, serves it when asked (adapters go live on their base) and answers
<code>Uploaded</code>. Closing the stream cancels, and the received parts stay in a staging directory outside the store for a resume
until <code>WritePolicy::part_ttl</code> (a week by default); <code>AbandonUpload</code> drops them.</p>
<p>Nodes copy from each other with <code>ModelsCommand::Fetch</code>: <code>Pull::from_peer</code> (<code>PullSource::Peer</code>)
pulls an upload or a stored entry from another node, once <code>ModelsService::with_peer_dialer</code> lets the node dial out, and
<code>ModelsClient::replicate</code> has several nodes pull an upload from the node it landed on at the same time.</p>
<p>Every write (uploads, removes, peer copies) follows the <code>WritePolicy</code>: an optional separate write
<code>Authorize</code>, <code>max_upload</code>, a <code>quota</code> on uploaded bytes, and <code>KeepFree</code>, the space never
filled (10 percent or 20 GiB by default, the larger). Without a write <code>Authorize</code>, any caller the service admits may
write. Since 0.4.7, <code>WritePolicy::with_uploads(false)</code> turns uploads off alone: they are refused with
<code>not-allowed</code>, while pulls, peer copies and removals keep working. <code>ModelsCommand::Disk</code> returns a <code>DiskReport</code> (free and total bytes, the limits, uploaded and staged
bytes). <code>List</code> includes safetensors and MLX models and projectors, with provenance (<code>StoredEntry::provenance()</code>).
<code>StoredEntry::list(&amp;store)</code> (0.4.7) lists a <code>ModelStore</code> the same way without a running service, and
<code>StoredEntry::from_model</code>, <code>from_adapter</code> and <code>from_projector</code>, with <code>with_served</code> and
<code>with_base</code>, build entries without serde.
Refusals carry stable reasons in <code>refusal</code> (<code>exists</code>, <code>too-big</code>, <code>no-space</code>,
<code>quota</code>, <code>wrong-engine</code>, <code>wrong-arch</code>, <code>no-base</code>, <code>checksum</code> and others), read
with <code>refusal_reason</code>. Nodes before 0.4.4 refuse the new commands.</p>
<p>Media limits (0.4.8): <code>Capabilities::limits</code> carries a model's media and request limits (a
<a href="/crates/agent">weirdnet-agent</a> 0.5.7 <code>MediaLimits</code>). The operator sets numbers the node can't measure with
<code>ModelLaunch::with_limits</code>; they reach every <code>ModelStatus</code> and capability record, and
<code>ModelStatus::limits()</code> reads them back. <code>Capabilities::intersect</code> keeps the stricter limits.
<code>Capabilities::apply_to</code> and <code>ModelStatus::apply_to</code> fill a catalog/1 entry's inputs, limits and context
window. Records without limits read as before.</p>
<h3>Measured limits (0.4.9)</h3>
<p>When a model loads (started or wrapped), the supervisor measures what it can and never fills in the rest. For a llama.cpp model
whose source is a GGUF file it reads the model's and the projector's headers with <a href="/crates/model">weirdnet-model</a> 0.5.4
<code>limits::measure</code>: what one image costs (fixed, or per patch up to a cap; <code>--image-max-tokens</code> in the engine's or
the model's extra arguments caps a size-dependent projector) and what audio costs. For every engine that says, it asks for the context per
sequence it actually runs (llama-server <code>/props</code>, per slot; vLLM <code>/v1/models</code> <code>max_model_len</code>).
<code>Supervisor::capabilities</code> and every <code>ModelStatus</code> carry the operator's <code>ModelLaunch::limits</code> over the measured
ones, field by field; a figure nobody knows, such as images per request or the longest audio, stays absent.
<code>Supervisor::measured_limits</code> returns the <code>LimitsRecord</code>, and <code>ModelStatus::context_tokens</code> the
context per sequence, which <code>ModelStatus::apply_to</code> puts in the catalog entry instead of the configured
<code>--ctx-size</code>. <code>Supervisor::set_limits_store</code> keeps records next to the model files in a <code>ModelStore</code> and
reads them back for models not loaded yet (without the context, which belongs to the run that measured it), so an unloaded model still
reports its image and audio figures after a restart. Changing a model's projector clears its measurement.</p>
<h3>Transcription (0.4.9)</h3>
<p><code>ModelLaunch::with_transcribe(true)</code> gives a model the transcription role. <code>Capabilities::transcribe</code> says the
node can serve it: llama.cpp with an audio projector (Voxtral, say) or vLLM (Whisper, say); never MLX-LM or an embedding model.
<code>ModelLaunch::purpose</code>, <code>ModelStatus::purpose</code> and <code>ModelStatus::catalog_model(state)</code> give catalog/1
<code>Purpose::Transcribe</code> (<a href="/crates/agent">weirdnet-agent</a> 0.5.8), so <code>Catalog::route_transcribe</code> finds it.
<code>ModelHost</code> serves infer/2 <code>Transcribe</code> (<code>InferHost::open_transcribe</code>): a named model must transcribe
on the node (otherwise <code>Unsupported</code>, so a pool tries elsewhere); with none named it takes the loaded transcriber, or with load
on demand the first one. <code>Supervisor::transcribe</code> sends llama.cpp a greedy chat request with the clip as a base64
<code>input_audio</code> part (llama-server takes WAV and MP3) and an instruction to answer with the transcript only, naming the language
and the prompt when given; the duration comes from a WAV header, and there are no segments. vLLM gets
<code>/v1/audio/transcriptions</code>, with timed segments when timestamps are asked for.</p>
<h3>Placement hooks, origin and license (0.4.5)</h3>
<p><code>ModelsService::on_placed</code> runs a callback (<code>OnPlaced</code>) after each upload, peer copy (including
<code>ModelsClient::replicate</code> targets) or Hub pull is placed. It gets a <code>Placed</code>: the <code>StoredEntry</code> with
its provenance, the <code>Pulled</code> answer with its revision, how it arrived (<code>PlacedVia</code>: <code>Upload</code>,
<code>Peer</code> or <code>Hub</code>), and <code>serve_error</code> when the files were placed but serving them failed.
<code>ModelsService::with_node_info</code> uses it to keep the node's capability record current
(<code>NodeService::set_model_info</code>). Capability records also carry each model's origin and license
(<code>ModelEntry::origin</code> and <code>license</code>: <code>hub</code>, <code>upload</code> or <code>train</code>, as in a
weirdnet-model provenance record, and an SPDX license), set with <code>NodeService::set_model_origin</code> or, through
<code>with_node_info</code>, from each placed entry's provenance (<code>Placed::origin_and_license</code>). They are left out of the
record when unset.</p>
<h3>Projectors (0.4.4)</h3>
<p><code>ModelLaunch::with_mmproj</code> gives a llama.cpp model a vision projector: the engine starts with <code>--mmproj</code> and
<code>capabilities()</code> reports image input. <code>Supervisor::set_projector_live</code> sets or clears it; the capabilities change
at once, and the running engine picks it up at the next load, so a served model is reloaded when its projector changes.</p>
<h3>Link info and the roster (0.1.2)</h3>
<p>Capability records carry the node's private links (<code>Capability::links</code>: address, <code>AddrClass</code>, interface,
the NIC's nominal speed and an operator-declared one), set with <code>NodeService::set_links</code>;
<code>link::local_links()</code> lists this machine's interfaces. Only loopback, link-local and private addresses are ever
advertised, never public or CGNAT ones. Older verifiers ignore the field. <code>Verifier::with_roster(roster)</code> also checks
the record's node against the roster, so a revoked model node is refused even when it presents its old certificate. Model nodes
should admit callers with <code>RosterAuth::require_roles</code> (weirdnet-agent 0.4.4). 0.1.2 accepts weirdnet-sync 0.5 to 0.7; 0.4.6 accepts 0.5 to 0.8.</p>
<h3>Platforms</h3>
<table>
<tr><th></th><th>Linux</th><th>macOS</th><th>Windows</th></tr>
<tr><td>llama.cpp</td><td>yes</td><td>yes</td><td>yes</td></tr>
<tr><td>vLLM</td><td>yes</td><td>no</td><td>no</td></tr>
<tr><td>Graceful stop (SIGTERM, then SIGKILL)</td><td>yes</td><td>yes</td><td>no: killed outright</td></tr>
<tr><td>Own process group</td><td>yes</td><td>yes</td><td>no</td></tr>
<tr><td>Dies with the node process</td><td>yes</td><td>no</td><td>no</td></tr>
</table>
''',
    features: [
      '<code>node</code>: <code>/weirdnet-backends/node/1</code> over <code>weirdnet-net</code> 0.8 and <code>weirdnet-sync</code> 0.5 to 0.8 (0.8 since 0.4.6), with <a href="/crates/model">weirdnet-model</a> hardware in the records (0.5.3 since 0.4.4; 0.5.2 in 0.4.0 to 0.4.3; 0.5.1 in 0.3.0; 0.4 before), <code>/weirdnet-backends/models/1</code> (0.3.0), and <code>weirdnet-agent</code>’s <code>pool</code> and <code>serve</code> features.',
    ],
  ),
  'openai': Guide(
    brings: r'''
<p>Use weirdnet-openai to let the user's local tools that already speak the OpenAI API use their own devices' models (chat, embeddings,
speech and transcription). Point the
tool at <code>http://127.0.0.1:&lt;port&gt;/v1</code> with the bridge token as the API key; requests go through a
<code>weirdnet-agent</code> pool, so failover, resume and stand-ins work as they do for the app.</p>
''',
    works: r'''
<h3>Who can call it</h3>
<p>The bridge binds <code>127.0.0.1</code> only. Every request must have a <code>Host</code> of <code>127.0.0.1:&lt;port&gt;</code> or
<code>localhost:&lt;port&gt;</code> (so a web page can't reach it by DNS rebinding) and the bearer token (at least 16 characters,
compared in constant time). It sends no CORS headers, so browsers block pages from reading its answers.</p>
<h3>Requests</h3>
<p>Chat bodies become infer/2 requests: messages (string content or parts: <code>text</code>, <code>image_url</code> with a
<code>data:image/...</code> URL, <code>input_audio</code> and, since 0.2.5, <code>video_url</code> with a <code>data:video/...</code> URL;
remote image or video URLs and other part types get 400), sampling, <code>seed</code>,
<code>response_format</code> and function tools; other parameters are ignored. <code>x-wait: 1</code> sets <code>wait_for_model</code>.
<code>"cache": false</code> or <code>x-weirdnet-cache: off</code> (0.2.1) skips the nodes' answer cache, and <code>"cache": "refresh"</code>
or <code>x-weirdnet-cache: refresh</code> skips the read and stores the fresh answer (weirdnet-agent 0.5.1 <code>Request::cache</code>);
with both, the stricter wins, and any other value is a 400.
<code>continue_final_message: true</code> (0.1.2, as in vLLM) moves the last assistant message into the request's prefix, so the
model continues it (weirdnet-agent's <code>Request::continuing</code>); the answer, whole or streamed, holds only the new text. It
needs the last message to be an assistant message without tool calls and <code>add_generation_prompt</code> not true (else 400),
and a node that can continue (else 501). Without the flag a trailing assistant message is passed on as a message.
A streamed answer starts when a node accepts the request, so an error before that is a plain HTTP error; after that, an error
arrives as a final <code>error</code> event. Answers carry <code>x-weirdnet-model</code>, <code>x-weirdnet-cache</code> and
<code>x-weirdnet-standin</code>, and the same under <code>weirdnet</code> in the body (on the last chunk when streaming).</p>
<p>Images and audio (0.2.0) and video (0.2.5) go to the pool unchanged, which sends them only to a model whose catalog entry takes
them (<code>vision</code>, <code>audio</code>, <code>video</code>, and all three as <code>inputs</code>, under <code>weirdnet</code> in
<code>/v1/models</code>): with no <code>model</code> it picks one; a named model that lacks the input, or a pool with no such model,
is a 400 that says so. A client whose model doesn't read video sends frames as images instead.</p>
<h3>Speech (0.2.5)</h3>
<p><code>POST /v1/audio/speech</code> runs infer/2 <code>Speak</code> through <code>Pool::speak</code>, or <code>Pool::speak_stream</code>
with <code>stream_format: "audio"</code> (the bytes as the node sends them; <code>"sse"</code> is refused). The body is OpenAI's:
<code>input</code>, <code>model</code>, <code>voice</code> (a preset name or <code>{"id": name}</code>), <code>instructions</code>,
<code>response_format</code> (<code>wav</code>, <code>pcm</code>, <code>mp3</code>, <code>opus</code> or <code>flac</code>; absent, the
model's first format, which is <code>wav</code> for the usual speech models rather than OpenAI's <code>mp3</code>) and <code>speed</code>.
Weirdnet extensions go under <code>weirdnet</code>: <code>language</code>, <code>seed</code>, <code>sample_rate</code>, <code>design</code>
(a voice described in words), <code>ref_audio</code> (a base64 <code>data:</code> URL; remote and file URLs are never fetched) with
<code>ref_text</code> and <code>consent: true</code> to clone a voice, <code>script</code>
(<code>[{"speaker": 0, "text": "..."}]</code> instead of <code>input</code>) and <code>raw</code>.</p>
<p>Before a node is asked, the bridge checks the request against the catalog's speech profile for the model
(<a href="/crates/agent">weirdnet-agent</a> 0.5.11 <code>Catalog::route_speak</code>), or picks a speaker that covers it when no
<code>model</code> is named. A voice, format or feature the model lacks is a 400 that names the model and what it has, for example
<code>model `tts` has no preset voice `alloy` (presets: vivian, ryan)</code>: OpenAI voice names are never mapped to another voice.
The answer's <code>Content-Type</code> is the real format (<code>audio/pcm;rate=24000</code> for raw PCM), with
<code>x-audio-sample-rate</code> and <code>x-weirdnet-audio-channels</code> when the node knows them; a whole answer also names request
fields the model ignored (such as a reference transcript) in <code>x-weirdnet-ignored</code>. A streamed answer that fails after audio
has left ends early: the pool never fails over once audio has started, because another node would start again with another voice.</p>
<h3>Transcription (0.2.5)</h3>
<p><code>POST /v1/audio/transcriptions</code> takes multipart/form-data and runs infer/2 <code>Transcribe</code> through
<code>Pool::transcribe</code>: <code>file</code>, <code>model</code> (absent, the catalog's transcriber), <code>language</code>,
<code>prompt</code>, <code>response_format</code> and <code>timestamp_granularities[]=segment</code> (<code>word</code> and
<code>stream</code> are refused). The audio's format comes from the file name, else its <code>audio/*</code> type, else its first bytes.
<code>json</code> (the default) answers <code>{"text": ...}</code>; <code>verbose_json</code> adds <code>language</code>,
<code>duration</code> (seconds) and <code>segments</code>; <code>text</code> is plain text; <code>srt</code> and <code>vtt</code> are
subtitles from the transcriber's timed segments (one cue over the whole clip when it reports only the duration, and a 501 when it
times nothing, rather than invented cues). Speech and transcription are never cached.</p>
<p>Request size (0.2.4): bodies (chat, speech and transcription alike) may be up to 32 MiB (<code>DEFAULT_MAX_REQUEST_BYTES</code>) unless the bridge is set otherwise with
<code>Bridge::with_max_request_bytes</code>. A larger body gets a 413 with code <code>request_too_large</code> whose message names the
limit, and the <code>x-weirdnet-max-request-bytes</code> header carries it. <code>/v1/models</code> reports
<code>weirdnet.max_request_bytes</code> per model (the smaller of the bridge's and the node's) and <code>weirdnet.limits</code>, the
model's media limits from <a href="/crates/agent">weirdnet-agent</a> 0.5.7, so a client sizes frames to fit the bytes as well as the
tokens. infer/2 carries at most 32 MiB per message.</p>
<p>LoRA adapters (0.2.2): <code>"adapter_scale"</code> in a chat or completion body sets how strongly a LoRA adapter model
applies for that request (<a href="/crates/agent">weirdnet-agent</a> 0.5.2 <code>Request::adapter_scale</code>); a value that is not
a finite number is a 400. <code>/v1/models</code> reports an adapter's base model as <code>weirdnet.base</code>
(<code>null</code> for models). Since 0.2.3 it also reports <code>weirdnet.origin</code> (<code>hub</code>, <code>upload</code> or
<code>train</code>) and <code>weirdnet.license</code> when the node says (weirdnet-agent 0.5.4 <code>CatalogModel::origin</code> and
<code>license</code>), and <code>null</code> otherwise.</p>
<p>Errors map to OpenAI-style bodies: unknown model 404, bad request 400, busy 503 with <code>Retry-After</code>, unavailable 503,
refused 403, unsupported 501, timeouts 504, engine failures 502.</p>
''',
  ),
  'semcache': Guide(
    brings: r'''
<p>Use weirdnet-semcache on an inference node to answer repeated deterministic prompts without running a model again, and,
since 0.2.2, to answer prompts close enough in meaning to one it has already answered.</p>
''',
    works: r'''
<h3>Exact matches</h3>
<p>Only deterministic requests are cached: temperature exactly 0, no tools, messages inline (not a context reference). The key is
SHA-256 over the CBOR of a version, the model, the input, sampling, seed, response format and the raw flag, so two requests share
an answer only when everything that could change it is equal. Image and audio parts (weirdnet-agent 0.5) are part of the
input, so a different image is a different request. Only answers that finished with <code>stop</code> or
<code>length</code> are kept; an unreadable stored entry is dropped. A hit should be marked with infer/2
<code>Meta::cache_hit</code>, which <a href="/crates/openai">weirdnet-openai</a> shows as <code>x-weirdnet-cache: hit</code>.</p>
<h3>Bypass, refresh and revisions (0.2.1)</h3>
<p><code>may_read(&amp;request)</code> and <code>may_store(&amp;request)</code> follow the request's weirdnet-agent 0.5.1
<code>CacheMode</code>: <code>ExactCache</code> never reads for <code>bypass</code> or <code>refresh</code> and never stores for
<code>bypass</code>. The mode is not part of the key, so a <code>refresh</code> overwrites the entry a later <code>use</code> reads.
<code>AnswerCache::get_rev</code> and <code>put_rev</code> take the model's revision (its weights) as well as its id, so a
fine-tune served under the same id doesn't replay the old weights' answers; <code>exact_key_rev</code> is the key. With no
revision the key is the 0.2.0 one, so stored answers still hit. Their default methods miss and keep nothing when a revision is
given, so a cache that doesn't know revisions never crosses weights.</p>
<h3>Stores</h3>
<p><code>AnswerStore</code> keeps opaque bytes under 32-byte keys; <code>MemoryStore::new(max)</code> evicts the least recently used.
<code>ExactCache::with_store</code> takes any store.</p>
<h3>Similarity lookup (0.2.2)</h3>
<p><code>SemanticCache</code> doesn't embed anything itself: the caller embeds the prompt with its own embedding model and passes
the vector (<code>&amp;[f32]</code>). <code>lookup(scope, embedding)</code> finds the most similar live entry in that scope by cosine
similarity and returns <code>Lookup::Hit { value, score, id }</code> when the score reaches the threshold
(<code>SemanticConfig::with_threshold</code>, 0.95 by default), or <code>Lookup::Miss { best }</code> with the best score below it.
<code>insert(scope, embedding, value)</code> stores an entry and returns its id; an entry pointing the same way is replaced
rather than duplicated.</p>
<p>Scopes keep answers apart: build one with <code>scope_key(&amp;[model, revision, system_prompt_hash])</code> (SHA-256 over the
length-prefixed parts) so different models, weights or system prompts never share an answer. Embeddings are refused when
empty, not finite (NaN or infinity), all zero, or of the wrong dimension (a fixed <code>with_dimension</code>, or the scope's first
entry), and are normalized on the way in. The cache holds at most <code>max_entries</code> across all scopes and evicts the least
recently used; <code>with_ttl</code> expires entries by age. <code>remove</code>, <code>remove_scope</code>, <code>clear</code> and
<code>stats</code> (entries, hits, misses, evictions, expired) round it out, and <code>snapshot</code> / <code>restore</code> write and
read the entries as CBOR, keeping their age. Values default to <code>CachedAnswer</code> but can be any <code>Clone</code> type. As
with <code>ExactCache</code>, check <code>may_read</code> and <code>may_store</code> on infer/2 requests first.</p>
''',
  ),
  'media': Guide(
    brings: r'''
<p>Use weirdnet-media when an app sends audio or video to a model or gets speech back: normalizing audio for a transcriber,
cutting long recordings to the transcriber's window and stitching the transcript back together, splitting long text for a
speech model and joining the audio it returns, writing subtitles, and turning a video into frames and a soundtrack for a model
that reads images and audio. It runs on clients and, opt in, on nodes; untrusted media only reaches ffmpeg through the
hardened runner.</p>
''',
    works: r'''
<h3>Limits come from the model</h3>
<p>Nothing here guesses a model's limits. <code>TranscribeLimits</code> carries the transcriber's <code>audio_max_seconds</code> and
<code>max_request_bytes</code>, <code>TextLimits</code> the speech profile's <code>max_input_chars</code>, and <code>FrameRequest</code> a frame
count and edge the caller derived from the model's media limits. When a plan needs a limit that is absent, it refuses with a
message naming the setting: a clip over the request limit with no <code>audio_max_seconds</code>, or text over 4 000 characters
with no <code>max_input_chars</code> (a refusal threshold of the client, not a limit claimed for any model).</p>
<h3>Long-audio transcription</h3>
<p><code>audio::normalize_pcm</code> turns any input into 16 kHz mono 16-bit PCM: a WAV is decoded and resampled in Rust (a
windowed-sinc filter that low-passes when going down), anything else is decoded by ffmpeg. <code>transcribe::plan</code> keeps the
clip whole when it fits; otherwise the window is <code>audio_max_seconds</code>, narrowed by what fits the request, and
<code>vad::silence_cuts</code> places each cut at the quietest 30 ms frame in the last fifth of the window, so pieces never overlap
and rarely split a word. Each piece's prompt is <code>prompt_from</code> the previous transcript (its last 200 characters, from a
word). <code>realign</code> shifts every segment by its piece's start and clamps it to the piece; a backend that returns no segments
gets one segment per piece, flagged <code>coarse</code>, and WebVTT output says so in a <code>NOTE</code>.</p>
<h3>Long-text speech</h3>
<p><code>TextPlan</code> is pure and deterministic. It packs whole paragraphs into a piece while they fit, splits a paragraph that
doesn't at sentence ends, a sentence at clause punctuation, and a clause between words; a single word longer than the limit is
an error rather than a split. Scripts (<code>SpeechText::Script</code>) keep their turns: a piece never mixes speakers, and a long
turn splits at sentences and keeps its speaker. Each piece records its paragraph and whether it starts one, and
<code>joins</code> turns that into a 10 ms equal-power crossfade inside a paragraph and a 300 ms pause before a new paragraph or
turn, for <code>pcm::concat</code>, which refuses pieces whose sample rate or channels differ. <code>audio::encode</code> writes WAV in
Rust, or MP3, Opus or FLAC through ffmpeg.</p>
<h3>Video</h3>
<p><code>FrameSource</code> is the decoder seam: <code>probe</code>, <code>frame_at</code>, <code>scenes</code>, <code>keyframes</code> and
<code>audio</code>. <code>FfmpegSource</code> implements it over the runner (JPEG frames through <code>image2pipe</code>, scene scores from
ffmpeg's <code>select</code> filter, keyframes from <code>ffprobe</code> packet flags, the soundtrack as 16 kHz mono WAV); phone decoders
can implement it too, and <code>FakeSource</code> generates frames for tests. <code>plan_frames</code> picks times inside a range:
uniform (the middle of equal slices), scene (the start and the strongest changes), hybrid (half uniform, half scene changes
away from them), keyframes (the nearest keyframe to each slot) or every N milliseconds, always sorted, unique and never more
than asked. <code>extract_frames</code> bounds the total bytes; <code>clip</code> stream-copies a range to fragmented MP4, Matroska or
WebM for models that read video natively.</p>
<h3>The hardened runner</h3>
<p>Every call is a <code>Job</code>: one input, the options before and after it, an output bound. <code>Runner</code> runs it without a
shell, adding <code>-nostdin</code>, <code>-protocol_whitelist file,pipe</code> and a demuxer allowlist (<code>-format_whitelist</code>: WAV,
MP3, FLAC, Ogg, AAC, MP4/MOV, Matroska/WebM, AVI), so a playlist, <code>concat</code> list or URL inside a file can't be followed;
jobs that name a URL, another protocol, an extra input or a disallowed input format are refused before anything starts. The
input is a canonical regular file under the size limit or bytes on <code>pipe:0</code>; output goes only to <code>pipe:1</code>, read with
a bound, and the child is killed when it passes it or the time limit (120 s by default). On Unix the child gets a 1 GiB
address-space limit and a lower priority, and on Linux a new network namespace where unprivileged user namespaces allow it.
stderr is kept only on failure, truncated to 2 KiB, and nothing is logged. <code>PrivateDir</code> is a 0700 temporary directory
removed on drop. <code>FakeRunner</code> validates jobs exactly like the runner, records them and answers from rules or a
<code>FakeMedia</code> description, so apps can test their media paths without ffmpeg.</p>
''',
  ),
  'alerts': Guide(
    brings: r'''
<p>Tell an operator when a node needs attention: an engine that keeps crashing, a default route that fell back to Wi-Fi, a
filesystem running out of space, a GPU running hot. Rules are data, so an application ships defaults and users add their own.</p>
''',
    works: r'''
<ul>
<li><b>Observations</b>: a kind (<code>engine.crash_loop</code>, <code>net.route</code>, <code>disk</code>, <code>gpu</code>, or
anything the application emits) and JSON fields. Probes produce the built-in ones; the <code>backends</code> feature maps
supervisor events and runs a <code>monitor</code> loop until told to stop.</li>
<li><b>Rules</b>: <a href="/crates/rules">weirdnet-rules</a> specs whose actions are <code>fail</code> (raise an alert under a key),
<code>ok</code> (clear it, sending a recovery notice) and <code>event</code> (a one-off). Titles are templates over the fields. A
failing key repeats at most every <code>repeat_secs</code> (an hour by default).</li>
<li><b>Sinks</b>: SMTP (lettre over rustls), JSON webhooks, the log, memory for tests, and push wakes through
<a href="/crates/push">weirdnet-push</a>, which carry only a reason code. Every sink has a dry run that builds the message and
sends nothing. Subjects read <code>[product host] title</code>; <code>with_product</code> sets the product.</li>
<li><b>Secrets</b>: SMTP passwords and webhook tokens are <code>env:NAME</code> or <code>file:/path</code> references; inline
values are refused.</li>
</ul>
''',
    features: [
      '<code>push</code>: <code>PushSink</code>, wakes through weirdnet-push 0.1 (pulls in aws-lc through reqwest).',
      '<code>backends</code>: <code>engine::observation</code>, <code>engine::probes</code> and <code>engine::monitor</code> for <a href="/crates/backends">weirdnet-backends</a> 0.2 to 0.4 (since 0.2.2; 0.2 or 0.3 in 0.2.0 and 0.2.1, 0.1 before). Adapters added or removed at run time arrive as <code>engine.added</code> and <code>engine.removed</code>, like models.',
    ],
  ),
  'plugin': Guide(
    brings: r'''
<p>The SDK a code space plugin is written against. It has no dependencies, so plugins build offline, and a stable C ABI, so a
plugin built once keeps loading. It is for trusted, first-party code that runs in the app's process; untrusted extensions run
out of process in a sandbox (<a href="/crates/ext">weirdnet-ext</a>).</p>
''',
    works: r'''
<ul>
<li>A plugin is a <code>cdylib</code> that exports <code>weirdnet_plugin_abi</code>, <code>weirdnet_plugin_info</code> and
<code>weirdnet_plugin_run</code> (<code>src/abi.rs</code>); the <code>plugin!</code> macro writes them. ABI version 2 keeps
version 1's layout; only the symbol names and the version differ.</li>
<li>At run time the host hands the plugin a table of its methods. <code>Host</code> is the safe API over them (JSON methods):
the input frame of loaded records, series helpers and the ingest-connector methods.</li>
<li>The plugin returns a result view: a table, chart, text or tiles. The host
(<a href="/crates/code-spaces">weirdnet-code-spaces</a>) checks it and cuts it to its limits.</li>
</ul>
''',
  ),
  'code-spaces': Guide(
    brings: r'''
<p>Let users write small programs against an app's data (a formula, a Polars expression, Rust or typed Python) and run them
as native plugins, with builds cached by content and nothing run until its owner approves it. Muninn's code spaces came from
here.</p>
<div class="callout warn">Plugins run as native code with the app's rights. Approving one is trusting it; the crate checks
hashes and the ABI, it does not sandbox.</div>
''',
    works: r'''
<ol>
<li><b>Source to crate</b>: <code>generate</code> turns the source into a crate against the SDK this crate carries
(<code>write_sdk</code> puts it next to builds, so they work offline). Math and Polars compile through generated Rust; Python
is translated in process with ruff's parser and a vendored python-ast (no libpython); prebuilt libraries skip this.</li>
<li><b>Build</b> (<code>native-plugins</code>): cargo with a shared target directory; libraries are cached under a content
key (<code>build_key</code>: ABI, SDK, codegen, language, platform, dependencies, source).</li>
<li><b>Trust</b>: <code>trust_hash_of</code> hashes the language and source (a prebuilt library's bytes); <code>approved</code>
compares it with the hash the owner approved, so an edit asks again. Spaces approve their line-up
(<code>spaces::lineup_hash</code>). Who may approve, and where approvals live, is the app's.</li>
<li><b>Load</b> once per process after checking the profile's symbols and ABI version, then <code>run</code> with a host table
over the app's <code>Host</code> methods.</li>
<li><b>Results</b>: <code>view</code> parses and checks the table, chart, text and tiles a plugin returns, with table, chart,
text-line and sparkline conversions. Drawing them is the app's (or <a href="/crates/render">weirdnet-render</a>'s).</li>
</ol>
<p>Spaces can <code>@import</code> each other with renames; <code>spaces::Graph</code> checks cycles and depth. Everything
that names the app or SDK comes from a <code>Profile</code> (<code>WEIRDNET</code>: SDK weirdnet-plugin, ABI 2), so an app keeps
its own hashes and messages. Native builds and loading need a desktop platform with a Rust toolchain; prebuilt plugins
don't.</p>
''',
    features: [
      '<code>math</code> (default): formulas over columns (<code>sma20 = sma(close, 20)</code>).',
      '<code>polars</code>: Polars expressions (implies <code>math</code>).',
      '<code>python</code>: typed Python, translated in process (implies <code>math</code>).',
      '<code>native-plugins</code> (default): running cargo and loading libraries (desktop platforms).',
    ],
  ),
  'pipelines': Guide(
    brings: r'''
<p>Run graphs of app-defined sources, steps and sinks, with validation that catches broken graphs before they run. The
crate gives no node a meaning: the app's <code>Kind</code> type says what each node is, and the runner reaches the app only
through <code>Host</code>.</p>
''',
    works: r'''
<ul>
<li><b>Graphs</b>: <code>Graph&lt;K&gt;</code> parses nodes (<code>ID=KIND</code>, <code>+TEE</code> side saves) and edges
(<code>A&gt;B[:NAME]</code>, chains <code>A&gt;B&gt;C</code>), and serializes as <code>{nodes, edges}</code>.</li>
<li><b>Checks</b>: <code>Graph::order</code> puts every node after its upstreams (a cycle is an error naming its nodes);
<code>Graph::check</code> reports duplicates, edges to missing nodes, self-loops, no source or sink, sources with inputs,
steps or sinks without, leaves that aren't sinks, sinks with something after them, and (with a resolver) names the app can't
find.</li>
<li><b>Running</b>: <code>execute</code> runs each node once, in order. Fan-out sends a node's frame to every node after it;
fan-in waits for all inputs and passes them as <code>(name, frame)</code> pairs; tees save a frame and the data flows on. A
failing node skips the nodes below it; the others still run.</li>
<li><b>Frames</b>: JSON column frames (<code>{model, fields, ids, columns, groups}</code>) built from rows, CSV, JSON or NDJSON,
with union, select, filter, keep-last and a Markdown table.</li>
</ul>
<p>Lookups, permissions, approvals, storage and every other effect stay in the app.</p>
''',
  ),
  'rules': Guide(
    brings: r'''
<p>If-this-then-that for an app's own events and actions, with the parts that are easy to get wrong done once: a condition
language, cron and interval schedules in any time zone, and loop protection so rules can't trigger each other forever. It
does no I/O and decides no permissions.</p>
''',
    works: r'''
<ul>
<li><code>RuleSpec&lt;T&gt;</code>: <code>on</code> event-kind patterns (<code>import</code>, <code>journal.*</code>,
<code>*</code>), <code>when</code> conditions, <code>then</code> actions of the app's own type <code>T</code>,
<code>related</code>, and an optional schedule; versioned JSON.</li>
<li><code>syntax</code>: conditions such as <code>inserted &gt; 0</code>, <code>title ~ "btc halving"</code> and
<code>out ?</code>, lists, quoting, and <code>on</code> patterns checked against the app's event catalog.
<code>compare</code>: how each operator compares JSON values (numbers, text, globs, arrays, missing values).</li>
<li><code>schedule</code>: <code>every 6h</code> (s, m, h, d or w; at least a minute) and five-field cron in local time or any
<code>chrono</code> zone, with the next run. <code>template</code>: <code>{field}</code>, <code>{rule}</code>,
<code>{date}</code>, <code>{time}</code>, <code>{now}</code>.</li>
<li><code>engine</code>: <code>check</code>, <code>dispatch</code> and <code>run</code> through the app's <code>Host</code> (it
lists enabled rules, reads event fields, records runs and blocked runs, and executes one then-action). A rule never
re-enters itself, chains stop at <code>MAX_DEPTH</code>, and an outermost event allows at most <code>MAX_RUNS</code> runs.
<code>due</code> and <code>next_run</code> drive the app's scheduler tick.</li>
</ul>
''',
  ),
  'render': Guide(
    brings: r'''
<p>Turn tables and line charts, or JSON describing them, into PNG with hard limits on input size, for reports, previews and
anywhere a UI can't draw. The input is plain data, not any app's types; Muninn draws code-space charts in reports with it.</p>
''',
    works: r'''
<ul>
<li><code>Table</code>: column names and text rows, drawn as a grid with an 8×8 bitmap font: numbers right-aligned, long cells
cut with <code>~</code>, characters without a glyph shown as <code>?</code>.</li>
<li><code>Chart</code>: x values and named series (gaps allowed), drawn as a line chart; <code>legend</code> names each
series' colour.</li>
<li><code>json_png</code> and <code>Drawing::from_json</code> accept <code>{"columns", "rows"}</code>, an array of objects
(columns are the sorted keys), an array of arrays, or <code>{"x", "series", "width", "height"}</code>.</li>
<li>Every entry point checks <code>Limits</code> (columns, rows, cell length, series, points, image size, JSON size) and returns
an <code>Error</code> instead of drawing something unbounded; a chart with no finite value is <code>Error::Empty</code>.</li>
</ul>
<p>The glyphs come from the <code>font8x8</code> crate (MIT).</p>
''',
  ),
  'themes': Guide(
    brings: r'''
<p>One theme format for terminal and GUI front ends, so a TUI, a Flutter app and a website can share colours: TOML files with
dark and light variants, semantic roles instead of raw colours, and contrast checks.</p>
''',
    works: r'''
<ul>
<li>A theme file has <code>[meta]</code>, <code>[dark]</code> and <code>[light]</code> tables and 21 required semantic colour
roles (<code>ROLES</code>), each a palette name or <code>#rrggbb</code>. Eight palettes are built in: <code>tokyo-night</code> (the
default), <code>catppuccin</code>, <code>gruvbox</code>, <code>dracula</code>, <code>nord</code>, <code>one</code>,
<code>solarized</code> and, from 0.2.0, <code>bragi</code>.</li>
<li><b>Optional roles (0.2.0)</b>: <code>surface</code>, <code>code_bg</code>, <code>diff_add_bg</code>,
<code>diff_remove_bg</code>, <code>link</code> and <code>dim</code> (<code>OPTIONAL_ROLES</code>). <code>VariantDef::color(role)</code>
derives the ones a theme leaves out: the surface is <code>bg</code> mixed 5% toward <code>fg</code>, code blocks use the surface,
diff backgrounds mix <code>bg</code> 16% toward <code>up</code> or <code>down</code>, links use <code>info</code>, and dim text is
<code>muted</code> mixed 35% toward <code>bg</code>. Theme files without them load unchanged; a role that is set must resolve, and
unknown roles are refused. <code>VariantDef::resolve(role)</code> is the raw value, and <code>mix</code> blends two colours.</li>
<li>WCAG contrast checks, and lightness-inverted variants generated from one side.</li>
<li>Storage is the app's: <code>load</code>, <code>save</code>, <code>list</code>, <code>materialize</code> and
<code>reset</code> work through the <code>ThemeDirs</code> trait. From 0.2.0, <code>UserDir::for_app("myapp")</code> is the
per-user folder <code>&lt;config dir&gt;/myapp/themes</code>, with the config dir from <a href="https://crates.io/crates/dirs">dirs</a>
(<code>$XDG_CONFIG_HOME</code> or <code>~/.config</code> on Linux, <code>~/Library/Application Support</code> on macOS,
<code>%APPDATA%</code> on Windows). It writes atomically, with private permissions on Unix. Theme names are checked before any
file is touched.</li>
<li><b>Editors and switchers (0.2.0)</b>: <code>entries</code> lists every theme with its display name, whether it is built in,
whether the user has a file for it and any load error; <code>exists</code>, <code>is_builtin</code>, <code>unique_name</code>,
<code>duplicate</code>, <code>rename</code> (user themes, assets included), <code>delete</code> (a user theme, or the user's edited
copy of a built-in, which brings the shipped one back), <code>import</code>, <code>export</code>, <code>cycle</code> for a
next/previous key, and <code>VariantDef::set_role</code> / <code>clear_role</code>. A user file with a built-in's name overrides
it.</li>
<li><code>Mode::{Light, Dark, System}</code>. From 0.2.0, <code>resolve_variant</code> probes nothing: <code>System</code> reads
the <code>COLORFGBG</code> hint, else dark. <code>resolve_variant_with(mode, detect::Probe::ALL)</code> also asks the terminal
background (OSC 11) and the OS preference (the freedesktop portal, <code>defaults</code> or <code>reg</code>);
<code>Probe::NONE.os(true)</code> picks one.</li>
<li><code>ColorDepth::detect</code> honours <a href="https://no-color.org">NO_COLOR</a> and <code>TERM=dumb</code>
(<code>ColorDepth::None</code>, 0.2.0), then <code>COLORTERM</code> and <code>TERM</code>. <code>ColorDepth::detect_with</code>
takes the app's own setting (<code>truecolor</code>, <code>256</code>, <code>16</code>, <code>none</code>), which wins over
NO_COLOR.</li>
<li><code>to_hex</code> gives <code>#rrggbb</code> for Dart or web front ends; errors are <code>ThemeError</code>.</li>
</ul>
<h3>Moving to 0.2.0</h3>
<ul>
<li><b><code>Mode::System</code></b>: it no longer asks the terminal or the OS. To keep the old behaviour, call
<code>resolve_variant_with(mode, detect::Probe::ALL)</code> and enable the <code>terminal-background</code> feature, which is no
longer on by default. <code>detect::system_variant</code> now takes a <code>Probe</code>.</li>
<li><b><code>ColorDepth</code></b> has a <code>None</code> variant: a <code>match</code> on it needs an arm, and
<code>to_color</code> gives <code>Color::Reset</code> for it.</li>
<li><b>ratatui <code>Theme</code></b>: <code>#[non_exhaustive]</code>, with <code>depth</code>, <code>surface</code>,
<code>code_bg</code>, <code>diff_add_bg</code>, <code>diff_remove_bg</code>, <code>link</code> and <code>dim</code>; build it with
<code>Theme::from_variant_depth</code>. In 16 colours <code>bg</code>, <code>fg</code> and the background roles are now
<code>Color::Reset</code> (the terminal's own) rather than the nearest ANSI colour; <code>to_bg_color</code> does the same for
your own colours.</li>
<li><b>Apps with their own workarounds</b> (NO_COLOR, a depth override, derived surfaces, link and diff colours, a themes folder):
replace them with <code>ColorDepth::detect_with</code>, <code>VariantDef::color</code> and <code>UserDir</code>.</li>
<li><code>materialize</code> now also writes the <code>bragi</code> theme folder.</li>
</ul>
''',
    features: [
      '<code>terminal-background</code> (off by default from 0.2.0): lets <code>detect::Probe::terminal</code> ask the terminal for its background (OSC 11).',
      '<code>ratatui</code>: <code>Theme::from_variant_depth</code>, <code>to_color</code> and <code>to_bg_color</code> give ratatui colours by <code>ColorDepth</code>.',
    ],
  ),
  'text': Guide(
    brings: r'''
<p>Use weirdnet-text for the rules behind a text field (an address bar, a prompt box, a chat input) when you draw the field
yourself in a toolkit with no text widget of its own, such as GPUI. The rules live outside the toolkit, so they are tested
headless and every app's inputs behave the same.</p>
''',
    works: r'''
<p><code>TextField</code> holds the text, the selection (and which end of it moves) and any text an input method has marked
while composing. Offsets are UTF-8 byte offsets, always on grapheme cluster boundaries, so the caret never lands inside an
accented letter or an emoji with a skin tone.</p>
<ul>
<li><b>Editing</b>: <code>replace(None, text)</code> types or pastes over the selection (or marked text) and puts the caret after
it; <code>backspace</code> and <code>delete</code> remove one grapheme cluster or the selection.</li>
<li><b>Moving and selecting</b>: <code>left</code>, <code>right</code>, <code>home</code>, <code>end</code>, <code>move_to</code>;
<code>select_left</code>, <code>select_right</code>, <code>select_to</code> (the selection can reverse), <code>select_all</code>,
<code>selected_text</code>, <code>cursor</code>.</li>
<li><b>Completions</b>: <code>append_selected(suffix)</code> adds a suggestion selected, so typing replaces it, Backspace removes it
and Right accepts it. <code>set_text_selected</code> replaces the text and selects it, as an address bar does on focus.</li>
<li><b>Input methods</b>: <code>replace_and_mark</code> inserts composing text as marked, with a selection inside it;
<code>unmark</code> commits it. <code>len_utf16</code>, <code>offset_to_utf16</code>, <code>offset_from_utf16</code>,
<code>range_to_utf16</code>, <code>range_from_utf16</code> and <code>set_selection_utf16</code> convert for platform input APIs,
which count UTF-16 units.</li>
<li><b>Line breaks</b>: <code>TextField::new()</code> is one line and turns line breaks into spaces;
<code>TextField::multiline()</code> keeps them and normalises <code>\r\n</code> and <code>\r</code> to <code>\n</code>.</li>
</ul>
''',
  ),
  'sync': Guide(
    brings: r'''
<p>Keep one person's devices in step (bookmarks, history, settings, notes) peer to peer, with nothing readable by a relay or
server, and with a revoked device locked out of everything written after the revocation. Apps keep their record types and
their storage; the crate brings the clock, the log, the merge rules, the keys and the protocol over
<a href="/crates/net">weirdnet-net</a>.</p>
''',
    works: r'''
<h3>The log and the merge rules</h3>
<p>Each node appends ops to an <code>OpLog</code> stamped with a hybrid logical clock (<code>Hlc</code>: physical time, a
counter and the node id), so a later write orders after everything the node has seen even when its wall clock is behind. Ops
carry an app-defined type and record id; the bytes are the app's.</p>
<ul>
<li>Fields are last-writer-wins by HLC (<code>lww</code>).</li>
<li>Sets are observed-remove (<code>OrSet</code>): concurrent adds of different elements keep both; a concurrent add and remove
of the same element keeps the add; a remove strictly later than the add wins. The same rule settles edit against delete.</li>
<li>Tombstones may be collected after 90 days, and only once every known peer cursor is past the delete; losing versions may
be kept 30 days for the app's UI. <code>folder_cycle</code> catches moves that would make a folder its own ancestor.</li>
</ul>
<h3>The protocol</h3>
<p><code>/weirdnet/sync/2</code> (<code>/1</code> before 0.5.0), length-prefixed CBOR, one request and reply at a time: <code>Hello</code> /
<code>HelloOk</code> or <code>Refuse</code>, <code>Pull</code>, <code>Page</code>, <code>Ack</code>, <code>Roster</code>, and (0.8.0) the lease messages. A session is
accepted only from a node with an unrevoked <code>NodeCert</code> for the same user. Pulls ask for one type, and positions are
kept per (node, type), so pulling one type never skips another. A server answers only up to what it holds completely, and
after a pull the puller's clock moves past the newest op it holds. Payloads with records, cursors or certificates are
sealed.</p>
<h3>Keys and revocation</h3>
<ul>
<li>Before any rotation, <code>SyncKey(type) = HKDF-SHA256(seed, salt = user id, info = weirdnet-sync/v1/&lt;type&gt;)</code>,
and pages are XChaCha20-Poly1305 sealed with associated data binding the type, epoch and asking peer.</li>
<li><b>Rotation on revoke</b> (0.3.0): every device holds the identity seed, so no seed-derived key can shut a device out.
<code>SyncState::revoke</code> therefore makes a fresh random epoch key and seals a copy to each remaining device's
<code>DeviceKey</code> (an X25519 key derived from its node key and signed by it). Rotations are signed by their creator and
travel in the roster's key chain; concurrent rotations settle on one head. After a rotation only the head key carries data,
and a device that missed it gets the roster back and catches up.</li>
<li><b>Re-admission</b>: a device restored from the recovery words gets a new node key and reports
<code>needs-admission</code> (<code>KeyStatus::NeedsAdmission</code>) until a member device admits it
(<code>SyncState::admit</code>, or <code>approve</code> before its key is known; compare <code>DeviceKey::fingerprint</code> on
both screens).</li>
<li>The first rotation starts by itself once two devices are linked and all have device keys
(<code>auto_first_rotation</code>); <code>devices_without_key</code> lets an app warn before a revoke. 0.3.1 fixes two devices
that both started the first rotation splitting into two chains, and revoking the device that made the first rotation no
longer drops the whole chain.</li>
<li>Epoch keys (<code>EpochKeys</code>) are secret: store them encrypted (<code>export</code>/<code>import</code>). The chain is
public and stored with the roster.</li>
</ul>
<h3>Large and sealed records (0.4.0)</h3>
<p>Ops carry small values inline. <code>SyncState::write</code> takes a record value of any size up to
<code>Limits::record_max</code> (default 16 MiB) and stores it as follows.</p>
<ul>
<li><b>Chunks</b>: a value over <code>Limits::inline_max</code> (default 32 KiB) is split into <code>chunk_size</code> pieces
(default 48 KiB). Each piece is addressed by its BLAKE3 hash and stored as an entry of the companion type
<code>&lt;type&gt;#chunks</code>; the record itself carries only the list of hashes and the length. A type's chunks are pulled
right after the type (<code>Limits::eager_chunks</code>, on by default) or on demand with <code>pull_chunks</code>, and are served
wherever the type is. <code>SyncState::read</code> reassembles the value only when every chunk, the length and the whole hash
match, and otherwise returns <code>RecordValue::Pending</code> listing the missing chunks.</li>
<li><b>Sealed records</b>: a type configured with <code>RecordOptions { sealed: true, .. }</code> seals every value under its
own key, derived from the head epoch key and bound (as associated data) to the type, record id, epoch, rotation and writer. A
device revoked before a write cannot open it, even holding the seed and every older key; members keep older epoch keys, so
values sealed before a rotation stay readable, and <code>reseal_stale</code> can re-seal them under the head key. Nothing is
sealed under seed-derived keys (the write fails with <code>no-epoch-key</code>), and an unsealed entry in a sealed type is
refused.</li>
<li><b>Older peers</b>: <code>write_with_fallback</code> lets an app give a small fallback op; a 0.3 peer ignores the new field
and keeps the fallback, and a plain entry keeps the 0.3 wire shape.</li>
<li><b>Page budget</b>: a page is now budgeted for what crosses the wire (<code>PAGE_BUDGET</code>; in 0.4.0 about 60 KiB, a
quarter of the 256 KiB <code>PAGE_MAX</code>), because the sealed body is hex and, with weirdnet-net 0.7, the request-response
codec sent bytes as an integer array. Before, a full page could exceed the 256 KiB reply cap and stall the stream. 0.5.0
raises the budget to 112 KiB (see below).</li>
<li><b>Caller check</b>: <code>Roster::check_caller</code> says whether the transport-authenticated caller of an app call is an
active linked device of this user. A presented certificate must match the peer and user, a revoked one is refused, and a
certificate the roster does not hold never admits a caller.</li>
</ul>
<p>0.4.0 depends on <a href="/crates/net">weirdnet-net</a> 0.7, whose types are in its API, so apps move to net 0.7 with it.</p>
<h3>Moving to 0.5.0</h3>
<ul>
<li><b>weirdnet-net 0.8</b>: 0.5.0 depends on <a href="/crates/net">weirdnet-net</a> 0.8, whose types are in this crate's API, so
apps move to net 0.8 with it. There are no other API changes from 0.4.</li>
<li><b>Protocol <code>/weirdnet/sync/2</code></b> (was <code>/1</code>): requests and replies carry byte fields as CBOR byte
strings. A 0.4 node and a 0.5 node fail to negotiate rather than fail to decode, so 0.5.0 does not talk to 0.4 peers. Upgrade
every device together.</li>
<li><b>Bigger pages</b>: <code>PAGE_BUDGET</code> is now <code>(PAGE_MAX - 16 KiB) / 2 - 8 KiB</code>, 114,688 bytes (112 KiB; was
about 60 KiB). A page is hex-sealed (2x) inside one CBOR byte string (1x), no longer four times the plaintext. A full page is
about 225 KiB on the wire, under the 256 KiB <code>PAGE_MAX</code>, and <code>CHUNK_MAX</code> grows with it.</li>
<li><b>Stored data is unchanged</b>: op logs, records, chunks, sealed values and key chains read exactly as in 0.4. Only the
network protocol moved.</li>
</ul>
<p>The <a href="https://weirdbrains.com">WeirdBrains</a> relay must not store sealed pages; only a user-run node may keep them for catch-up, as an app choice.
weirdnet-storage's row change log is a separate, local mechanism.</p>
<h3>Snapshots, merge-back and partial pulls (0.5.1)</h3>
<p>A node's <code>SyncHandler</code> answers from the same <code>Arc&lt;Mutex&lt;SyncState&gt;&gt;</code> the app pulls into. Holding that
lock for a whole pull stops the node answering, and two nodes pulling from each other at once then wait on each other until the
request times out. <code>pull_from_shared(&amp;state, &amp;node, peer, &amp;addrs, typ)</code> avoids that: it takes a
<code>SyncState::snapshot()</code>, pulls into it without the lock, and folds it back with <code>SyncState::merge_back</code>, also when
the pull failed part-way.</p>
<p><code>merge_back(&amp;snapshot)</code> is for apps that keep their own copies too (it replaces the deprecated
<code>take_keys_from</code>). It keeps everything the state learned or wrote meanwhile:</p>
<ul>
<li>the roster merges as on the wire: a revocation on either side wins, and an active copy in the snapshot never un-revokes a
device; the epoch is the higher one and the key chain merges;</li>
<li>epoch keys and the adopted root come across, then any key the merged chain seals to this device;</li>
<li>log entries it lacks are integrated (<code>OpLog::integrate</code>, so chunks and sealed values read back), peer and per-type
cursors move to the further of the two, and the clock moves past both;</li>
<li>types, record options and the device stay the state's own. Write locally to the shared state, not to the snapshot.</li>
</ul>
<p>It returns a <code>MergeOutcome</code> with the entries, keys and revocations it took.</p>
<p>A pull applies and acks page by page, so if a later page is refused, the network drops or the closing rotation fails, the
earlier pages stay applied and their cursors moved. <code>pull_from</code> keeps its signature and returns only the error;
<code>pull_from_outcome</code> and <code>pull_from_shared</code> return a <code>PullOutcome { applied, error }</code> (non-exhaustive)
with the count either way, so an app can show progress and retry from where it stopped.</p>
<h3>Several types in one session (0.8.5)</h3>
<p><code>pull_types(&amp;mut state, &amp;node, peer, &amp;addrs, &amp;["ymir.pool", "ymir.context"])</code> pulls several record
types from one peer in one session: one <code>Hello</code> (and at most one roster swap) for all of them, then each type's
<code>Pull</code>, <code>Page</code> and <code>Ack</code>. <code>pull_types_shared</code> does the same on a snapshot, as
<code>pull_from_shared</code> does for one type.</p>
<ul>
<li>Each type's requests are sealed under that type's own key, so a service device's scoped keys work as with
<code>pull_from</code>. Since 0.8.5 a server refuses a <code>Pull</code> sealed under another type than the one it asks for
(<code>type-mismatch</code>).</li>
<li>It returns a <code>PullTypesOutcome</code> with one <code>PullOutcome</code> per type, in the order asked
(<code>get</code>, <code>applied</code>, <code>is_ok</code>). A type the peer refuses fails alone and the others still pull:
<code>type-not-granted</code> outside a service device's grant, <code>type-off</code> where the peer does not sync it. A service
device does not ask for a type outside its own grant; that type comes back <code>type-not-granted</code> without a request.</li>
<li>Nothing changes on the wire: a server answers each request on its own, so a 0.7.1 or 0.8.0 to 0.8.4 peer serves a
<code>pull_types</code> session too, with one <code>Hello</code>.</li>
</ul>
<h3>A device linked elsewhere (0.5.2)</h3>
<p>Before 0.5.2 a node answering a pull listed only revoked certificates, so a device linked on another device (no revocation and
no rotation, so no epoch change) reached the rest only by luck, and a pass could finish without error while the new device stayed
unknown. Since 0.5.2 the answer lists every certificate, and a puller whose peer lacks one of its certificates sends it the roster.
Old and new nodes still talk both ways: older nodes merge the extra certificates as before, and a 0.5.2 puller hands an older peer
its roster on each pass (one small request).</p>
<h3>The identity store (0.6.0)</h3>
<p>Every app with linked devices keeps the same things: the user key seed, its own node key and certificate, the epoch keys and the
roster. <code>Identity</code> stores them in one directory (0700 on Unix; <code>seed</code>, <code>node.key</code>, <code>keys</code>
and <code>roster.json</code> in 0600 files, not sealed, so apps that keep secrets in the OS keystore hold <code>SyncState</code>
themselves for now). Each identity announces one sync type, such as <code>ymir.pool</code> or <code>bragi.app</code>.</p>
<ul>
<li><code>Identity::open(dir, typ)</code> loads it (<code>None</code> if there is none); <code>create(dir, label, typ)</code> makes a
new user with this device as its first node and never overwrites one.</li>
<li><code>adopt(dir, node_key, seed, cert, settings, typ)</code> takes what a device link delivered: the seed, the certificate the
existing device made for this node (checked against this node and user) and that device's <code>LinkSettings</code> JSON with its
roster. <code>link_settings()</code> and <code>seed()</code> are the sending side; <code>approve(cert)</code> adds the new device.</li>
<li><code>revoke(peer)</code> revokes and rotates the keys, but never this node's own certificate.</li>
<li><code>tick(&amp;node, &amp;addrs)</code> runs <code>pull_from_shared</code> against every other active device and saves. It
returns a <code>Tick</code> with the devices reached, entries applied and each failure, so devices linked or revoked elsewhere
arrive even when the type has no records. <code>state()</code> is the shared state for the node's <code>SyncHandler</code>, and
<code>roster_view()</code> a live roster for checks such as weirdnet-agent's <code>RosterAuth</code>.</li>
</ul>
<p>The file layout is the one Ymir's <code>membership</code> and Bragi's <code>identity</code> modules used, so their stores open
unchanged. 0.6.0 also makes <code>SyncError</code> non-exhaustive, with <code>Io</code> and <code>Identity</code> variants: add a
catch-all arm where you match it.</p>
<h3>Service devices and grants (0.7.0)</h3>
<p>A server (an inference or model node) can now be linked without the seed. The user signs a <code>DeviceGrant</code> for it:
a class (<code>Full</code> or <code>Service</code>), roles such as <code>ymir.inference</code>, and the sync types it may hold.
Grants live in the roster, sync like certificates and revocations, and are how apps decide what a device may do
(<code>Roster::roles_of</code>, <code>has_role</code>); people's roles stay in <a href="/crates/access">weirdnet-access</a>.</p>
<ul>
<li>The existing device makes the bundle with <code>Identity::service_bundle(peer, roles, types)</code> (it grants and, for a
device with types, rotates first, so the bundle carries keys; since 0.8.3 only type-scoped ones), sends it over a
<a href="/crates/device-link">weirdnet-device-link</a> 0.4 credential, and the server calls
<code>Identity::adopt_service</code>. Its <code>SyncState::seed</code> is <code>None</code>.</li>
<li>A service device with types syncs them under the epoch key and is sealed into every later rotation, so revoking it cuts
it off. One with no types (a model node) is roster-only: it holds no keys and follows certificates, revocations and grants
over an unsealed roster exchange (only a roster or a refusal ever goes unsealed).</li>
<li>It can't admit, revoke, grant or rotate (<code>SyncError::NotPermitted</code>), and rotations or admissions it signs are
ignored.</li>
<li><code>SecretStore</code> lets an app keep the identity's secrets in its own store (<code>FileSecrets</code> is the
default).</li>
</ul>
<h3>Type-scoped keys for service devices (0.8.3)</h3>
<p>A service device with sync types holds only the keys of the types in its grant, never an epoch key. A node granted
<code>ymir.train</code> syncs <code>ymir.train</code>, votes and claims jobs, and cannot open a <code>ymir.context</code> page or
sealed record, whatever it is sent.</p>
<ul>
<li>The link bundle carries, for each rotation, the key of each granted type and its chunk type, derived exactly as a full
device derives it, so envelopes look the same on the wire. A later rotation admits the device with the new rotation's
scoped keys instead of sealing the epoch key to it (<code>Roster::scoped_types</code>, <code>EpochKeys::get_scoped</code>).</li>
<li>Leases come automatically: a service device with any sync type also gets the <code>weirdnet.lease</code>
(<code>LEASE_TYPE</code>) key. Granting only <code>weirdnet.lease</code> makes a voter that holds no data keys.</li>
<li>Devices serve a service peer only its granted types: a <code>Hello</code>, <code>Pull</code> or <code>Ack</code> for another
type, and a lease request from a roster-only device, get <code>type-not-granted</code> (<code>Roster::may_sync</code>). Full
devices are not limited.</li>
<li>A service device granted a sealed record type (<code>RecordOptions::sealed</code>) reads and writes its records since
0.8.4 (below). One not granted the type opens neither its pages nor its records.</li>
<li>A service device given epoch keys by an older device replaces them with scoped keys when it loads them. Upgrade full
devices to 0.8.3: an older one that rotates still seals the epoch key to service devices. A service device on 0.8.2 can't
use the scoped keys and needs 0.8.3.</li>
</ul>
<h3>Sealed records on service devices (0.8.4)</h3>
<p>A record of a sealed type can be sealed under a key from the type's own key under the rotation
(<code>scoped_record_key</code>), which a service device granted the type holds, instead of the epoch key. A node granted
<code>ymir.pool</code> and <code>ymir.context</code> reads and writes sealed <code>ymir.context</code> records; one granted
<code>ymir.train</code> still opens none of them.</p>
<ul>
<li>Which key seals (<code>SyncState::seals_scoped</code>): a service device always uses the type-scoped key. A full device
uses it while an active service device is granted the type (<code>Roster::service_granted</code>), and the epoch key
otherwise, so 0.7.1 to 0.8.3 devices keep reading what it writes while no service device shares the type.</li>
<li>Readers try both keys, so nothing changes on the wire. Every full device that reads a type shared with a service device
needs 0.8.4.</li>
<li>Records written before the grant stay under the epoch key. Run <code>SyncState::reseal_stale</code> on a full device
after syncing: besides records under an older rotation, it re-seals those that use the other key than a write would now,
so the service device can open them. After the last such service device is revoked, it moves them back.</li>
<li>A service device revoked before a rotation gets no key for it, so it cannot open records sealed under that rotation by
either scheme.</li>
</ul>
<h3>Moving to 0.7.0</h3>
<p>Breaking: <code>SyncState::seed</code> is an <code>Option&lt;Vec&lt;u8&gt;&gt;</code>; <code>Roster</code> has a
<code>grants</code> field, <code>KeyStatus</code> a <code>RosterOnly</code> variant, <code>Envelope</code> a <code>clear</code> flag
and <code>SyncError</code> a <code>NotPermitted</code> variant. Full devices on 0.6 and 0.7 keep syncing with each other (0.6
ignores grants), but a service device needs 0.7 peers.</p>
<h3>Leases, plans and jobs (0.8.0)</h3>
<p>The op log is eventually consistent, so it can't give mutual exclusion. For "one device decides" (a scheduler) and "one
device works on this job", 0.8.0 adds a majority-vote lease with fencing terms, and two kinds of records ordered by term
instead of clock.</p>
<ul>
<li><b>Voters</b> are the devices the user granted a role (<code>Voters::Role("ymir.inference")</code>, or
<code>Voters::Peers</code> for a fixed set) with an active certificate. A device votes once it has a <code>Voter</code>
(<code>SyncState::set_voter</code>, or <code>Identity::enable_voter</code>, which keeps its terms on disk and writes each new
term before granting it).</li>
<li><b>Leases</b> (<code>Leases::acquire</code>, <code>renew</code>, <code>release</code>, or an <code>Elector</code> that keeps
one in the background): a candidate asks every voter at once and holds the lease once a majority granted it, and stops before
any voter's promise ends. A voter never grants a term twice and refuses takeovers for one lease duration after a restart. A
live holder keeps the lease. Defaults: 15 s leases, renewed every 5 s, 1 % clock drift.</li>
<li><b>Fencing</b>: every command that matters carries the lease's <code>Term</code>; resources keep a
<code>FenceGuard</code> and refuse a term older than one they have seen, so a paused or partitioned ex-holder does no harm.</li>
<li><b>Plans</b> (<code>publish_plan</code>, <code>current_plan</code>): one signed document per name; the newest by
<code>(term, version)</code> from an active signer wins, whatever the clock says.</li>
<li><b>Jobs</b> (<code>Jobs</code>, <code>JobSpec</code>, <code>Leases::claim_job</code>): claiming a job is acquiring its own
lease, and that term fences the attempt. When a worker dies its claim lapses and another voter resumes from the last
checkpoint.</li>
<li><b>Job rules</b> (0.8.1, <code>JobSpec::with_rules</code>, <code>JobRules</code>): the devices that may claim a job (a role,
narrowed by a candidate list), how long voters wait after a claim lapsed before another device may take it over, and a backoff
after a retryable failure. Claims from other devices are ignored when folding and refused by voters. Voters grant a job its own
claim time (up to an hour, <code>MAX_JOB_CLAIM</code>; other names keep their limits, see <code>Voter::with_limits</code>) and wait
out their longest grant after a restart. Under rules, only the job's owner or a full device can pause, resume or cancel it.</li>
<li><b>Pausing and notes</b> (0.8.1): <code>Jobs::pause</code> and <code>resume</code>; a pause never counts as an attempt (since 0.8.2 that holds for the owner's pause
even when the holder's lease ran out before it recorded its own).
<code>JobEvent::Note</code> lets the holder keep small values (progress, where copies of a checkpoint are) without a new
checkpoint, newest per key.</li>
<li>Lease messages travel on <code>/weirdnet/sync/2</code>, sealed under the head key, so only the user's admitted, unrevoked
devices take part. Change the voter set one device at a time.</li>
</ul>
<h3>Moving to 0.8.0</h3>
<p>Breaking: <code>SyncState</code> has a public <code>voter</code> field (struct literals add <code>voter: None</code>) and
<code>Message</code> has <code>LeaseAsk</code>, <code>LeaseGrant</code>, <code>LeaseDeny</code> and <code>LeaseFree</code>
variants (exhaustive matches need arms for them). Pulls between 0.7 and 0.8 devices are unchanged; every voting device needs
0.8.</p>
<p>0.8.1 needs no source changes, unless you match <code>JobEvent</code> or <code>JobStatus</code> exhaustively (new
<code>Paused</code>, <code>Resumed</code> and <code>Note</code>). Jobs posted without rules encode and fold as in 0.8.0. Give every
voter for a job role the 0.8.1 limits before posting jobs with long claim times.</p>
<h3>Checking callers on a serving node</h3>
<p>A node that serves something to the user's other devices (inference, files, app calls) has to decide who is calling. The
transport tells it the caller's peer id, authenticated by Noise; the roster tells it whether that peer is one of the user's
devices. Call <code>Roster::check_caller(profile, &amp;user_key, &amp;peer, presented)</code> for every incoming stream or call:</p>
<ul>
<li><code>peer</code> is the peer id the transport authenticated (for weirdnet-net, <code>Stream::peer()</code>), never a value
from the request body.</li>
<li><code>presented</code> is an optional <code>NodeCert</code> the caller sent. It must name that peer and this user and verify
against the user key, or the answer is <code>WrongUser</code>; a revoked one is <code>Revoked</code>.</li>
<li>Only a certificate the roster itself holds admits a caller. A presented certificate alone is never enough, because anyone with
the user seed (a revoked device too) can mint one: a peer the roster does not know is <code>Unknown</code>.</li>
<li><code>Linked</code> admits. <code>CallerCheck::reason()</code> gives a short refusal string to send back:
<code>unknown-device</code>, <code>revoked</code>, <code>wrong-user</code> or <code>needs-admission</code> (a device not yet in the
key chain's head).</li>
</ul>
<p>Check on each new stream rather than once per connection, with the roster as it is now, so a revocation takes effect for the
next call. <a href="/crates/agent">weirdnet-agent</a>'s <code>serve</code> feature does exactly this for inference
(<code>serve::RosterAuth</code>).</p>
''',
  ),
  'access': Guide(
    brings: r'''
<p>One answer to "may this peer do this to this resource?" across every Weirdnet app, so Morph sites and Muninn orgs behave
the same: who can see a resource exists, who can get in, what each role may do, and whether the reply must be sealed. Apps
supply role defaults and their own permissions; they don't hard-code forum or org types into it.</p>
''',
    works: r'''
<h3>Two independent settings</h3>
<p><code>Visibility</code> is <code>Private</code> (only the owner and trusted peers know it exists; members must be trusted
too) or <code>Public</code>. <code>Access</code> is <code>Open</code> (no membership needed) or <code>Gated</code> (a valid
membership is needed). On the wire it is always <code>gated</code>; CLIs may also accept <code>members</code>,
<code>member</code> and <code>closed</code>. New resources default to Private + Open.</p>
<h3>Permissions and roles</h3>
<p>The core <code>Catalog</code> is <code>read</code>, <code>members.list</code>, <code>members.approve</code>,
<code>members.invite</code>, <code>members.kick</code>, <code>members.role</code>, <code>members.defaults</code> and
<code>roles.manage</code>. Apps add their own with implications (<code>files.delete</code> includes <code>files.write</code>,
which includes <code>files.read</code>), followed transitively; cycles are refused. Roles have a name, a rank and permissions.
Presets: <code>owner_member</code> (Morph) and <code>ranked</code> (owner/admin/user/viewer, Muninn). The owner can do
everything and alone grants the builtin <code>owner</code> role (always <code>*</code>); everyone else manages only roles and
members ranked below them. Removing a role moves its members to the lowest remaining role. Apps that keep roles elsewhere use
<code>roles::check_grant</code> and <code>check_over</code> (0.1.1).</p>
<h3>Enforcement order</h3>
<table>
<tr><th>Step</th><th>Private</th><th>Public</th></tr>
<tr><td>1. Identity</td><td>revoked node: not found</td><td>revoked node: denied</td></tr>
<tr><td>2. Visibility</td><td>not the owner and not trusted: not found</td><td>continue</td></tr>
<tr><td>3. Membership (Gated)</td><td>none: not found</td><td>none: join first</td></tr>
<tr><td>4. Role</td><td>the role must allow it</td><td>the role must allow it</td></tr>
<tr><td>5. Transport</td><td>sealed</td><td>sealed if Gated, plain if Open</td></tr>
</table>
<p>Guests act under the resource's guest role only on Open resources, never with managing permissions. The crate doesn't
depend on weirdnet-net: the app passes in <code>Facts</code> it has already checked (the node certificate, the trust list and
the presented membership).</p>
''',
  ),
  'push': Guide(
    brings: r'''
<p>Wake a suspended phone when a peer or its home relay has sealed messages for it, without Apple, Google or the push
service learning anything about the message, the sender or the network. It is the payload format, the client, a
self-hostable server, and the relay wake path for phones without Google services.</p>
''',
    works: r'''
<ul>
<li><b>Wake payloads</b> (<code>wake</code>): exactly 96 bytes, sealed to the device's <code>PushKey</code> (X25519, HKDF-SHA256,
ChaCha20-Poly1305, a fresh key per payload) and bound to its handle. Inside are only a reason code
(<code>MessageWaiting</code>, <code>ConnectionRequested</code>), a random value and a time. <code>ReplayGuard</code> refuses
repeats and stale wakes.</li>
<li><b>Wake handles</b> (<code>handle</code>): 32 random bytes. The device shares a <code>WakeCard</code> (handle and push public
key) only with its home relay and trusted peers, sealed. Its <code>ControlSecret</code> rotates the handle (the old one stops at
once) or revokes it.</li>
<li><b>Client</b> (<code>PushClient</code>): register, rotate, unregister, wake, and follow relay announcements.</li>
<li><b>Server</b> (the <code>weirdnet-push</code> binary): APNs with token auth (an alert with <code>mutable-content</code> and a
fixed placeholder text the device replaces after decrypting), FCM HTTP v1 high-priority data messages, and the relay path. A
token the provider rejects revokes its handle. It stores only SHA-256 hashes of handles and control secrets and logs no handles
or tokens. Put TLS in front.</li>
<li><b>Relay wake path</b> (<code>relaywake</code>, <code>/weirdnet/wake/1</code>): a device that opted in keeps a stream to its
home relay and subscribes its handles; trusted peers deliver payloads to the relay, which also passes on the push service's
announcements. weirdnet-relay serves it.</li>
</ul>
<table>
<tr><th>Party</th><th>Sees</th></tr>
<tr><td>Apple / Google</td><td>the device token, the time and 96 bytes of ciphertext</td></tr>
<tr><td>The push service</td><td>the handle's hash and the device token (stored); the handle and time (per wake)</td></tr>
<tr><td>Relays</td><td>the handle, the time and the ciphertext (the home relay also sees which peer subscribed)</td></tr>
<tr><td>Senders</td><td>the handle and push public key they were given</td></tr>
</table>
<p>Nobody but the device sees the reason. Abuse control in this phase is handle revocation and rotation; there are no rate
limits yet, and UnifiedPush is a later phase.</p>
''',
    features: [
      '<code>client</code> (default): the HTTP client for devices and senders.',
      '<code>relay-wake</code> (default): the relay wake path’s wire protocol.',
      '<code>server</code>: the push server library and the <code>weirdnet-push</code> binary.',
    ],
    install: r'''cargo install weirdnet-push --features server
weirdnet-push relay-token                      # for each relay that follows
weirdnet-push check -c /etc/weirdnet-push/config.toml
weirdnet-push serve -c /etc/weirdnet-push/config.toml''',
  ),
  'schemes': Guide(
    brings: r'''
<p>Make a <code>weirdnet-&lt;app&gt;://</code> link mean the same thing on every device: which app owns a scheme, who
published it, how to install it if it's missing, and how to register it with the OS. Every app registers a signed prefix;
prefixes beginning with <code>weirdnet</code> are reserved for <a href="https://weirdbrains.com">WeirdBrains</a>, and the resolver never hands a link to a
stranger's app without asking.</p>
''',
    works: r'''
<ul>
<li><b>Names</b> (<code>names</code>): an app's schemes are its prefix or <code>prefix-…</code>. First-party apps use
<code>weirdnet-&lt;app&gt;</code> (<code>first_party("morph")</code> is <code>weirdnet-morph</code>). Standard schemes
(<code>https</code>, <code>file</code>, <code>mailto</code>, …) can't be claimed. <code>weirdnet://</code> is internal only:
never registered with the OS and never resolved to an app.</li>
<li><b>Records</b>: a <code>PrefixRecord</code> and a <code>SchemeRecord</code> (scheme, prefix, app id, publisher key, display
name, capabilities, install hints, <code>seq</code>, expiry, withdrawal), each signed by the publisher's Ed25519 key over its
exact JSON. Reserved prefixes also carry the <a href="https://weirdbrains.com">WeirdBrains</a> root signature and appear only on the canonical list, which the root
key signs as a whole. A prefix moves to a new publisher only with a transfer signature from the old one; the root key rotates
by a record both keys sign.</li>
<li><b>Resolver</b> (<code>Registry</code>): loads the canonical list, records from relays (later the DHT) and installed apps;
refuses unsigned, stale, expired and withdrawn records and any <code>weirdnet…</code> claim not on the list. Resolution prefers
the user's pin, then the canonical list, then an installed app whose publisher matches, and otherwise returns
<code>Resolution::Choose</code> so the app asks the user. The registry serializes as the device's local cache.</li>
<li><b>Links</b> (<code>Link</code>): <code>&lt;scheme&gt;://join/&lt;code&gt;</code>,
<code>&lt;scheme&gt;://answer/&lt;code&gt;</code>, and <code>&lt;scheme&gt;://&lt;name or user id&gt;/&lt;path&gt;</code> for
resources held by peers.</li>
<li><b>Install hints</b>: Salty Gull, App Store, Google Play, F-Droid or an HTTPS page, filtered by <code>Platform</code>; shown,
never acted on without the user.</li>
<li><b>OS registration</b> (<code>os</code>): the Linux <code>.desktop</code> entry and <code>xdg-mime</code> defaults,
per-user Windows registry keys (or a <code>.reg</code> file), <code>CFBundleURLTypes</code> for macOS and iOS, and the Android
intent filter. All refuse <code>weirdnet://</code>.</li>
</ul>
<p>The <a href="https://weirdbrains.com">WeirdBrains</a> root key is used through <a href="/crates/weirdnetctl">weirdnetctl</a>; apps ship its public key as their
trust anchor (<code>TrustAnchors</code>).</p>
''',
  ),
  'device-link': Guide(
    brings: r'''
<p>Move a person's Weirdnet identity to their new device by scanning a QR code, without typing the 24 recovery words and
without anyone else on the network being able to take it. Built in Morph as "Login over QR" and moved here; 0.3.0 brings
over the rest of Morph's copy, so apps use this crate instead of their own.</p>
''',
    works: r'''
<ol>
<li><b>Offer</b>: the new device (no identity yet) shows a QR code or link: its node key, a fresh X25519 key, its addresses
(up to three direct ones, one per host first, and a circuit for each of up to two relays, so devices on other networks
connect) and a 120-second expiry, signed by its node key. Nothing secret is in it. Or the other way round: the existing
device shows an <code>Invite</code> and the new one scans it. Codes are compact CBOR arrays: addresses are binary, and a
circuit through the <a href="https://weirdbrains.com">WeirdBrains</a> public relay (<code>KNOWN_RELAYS</code>) is one byte, so the QR stays easy to scan off a
laptop screen.</li>
<li><b>Pairing</b>: the existing device connects on <code>/weirdnet/link/2</code> (invites arrive on
<code>/weirdnet/link-invite/2</code>). Both derive a key and a 6-digit short
authentication string from the X25519 agreement and a transcript hash, and show the code.</li>
<li><b>Transfer</b>: only after the user confirms the codes match on the existing device does it send the seed, the profile
name, the sync types the user opted in to (<code>Pairing::send_with</code>) and a node certificate for the new device, sealed
with that key.</li>
<li><b>Service link</b> (0.4.0): a server that must never hold the seed (a model or inference node) gets a
<code>Credential</code> instead: the user's <em>public</em> key, a node certificate the existing device signs with the user key
(which never leaves it), the sync types and an opaque sync bundle (weirdnet-sync's <code>Identity::service_bundle</code>: the
device's grant, the roster and, if it syncs types, keys for those types only since weirdnet-sync 0.8.3), sealed the same way
(<code>Pairing::send_credential</code>). The new device takes it with <code>take_any()</code> and adopts it with
<code>Identity::adopt_service</code>. <code>take()</code> still returns only a full transfer, and a 0.3 device refuses a
credential.</li>
<li><b>Relays</b>: link nodes start with the relays in their <code>NodeConfig</code> and link-sized limits
(<code>with_link_limits</code>: 1 MiB requests since 0.4.0, 16 KiB responses, a 30-second timeout). <code>RelayProbe</code> reserves on
the configured relays and measures each one's round trip, and <code>relay_states</code> turns node statuses into connected,
reserved and round-trip state per relay, for a settings page.</li>
<li>An offer is single use and dies after three pairing attempts, a cancel, a transfer or its expiry. Nothing logs
secrets.</li>
</ol>
<p>Modules: <code>offer</code> (offers and links), <code>invite</code>, <code>session</code> (both sides without the network:
<code>Host</code>, <code>Sender</code>), <code>net</code> (<code>HostNode</code>, <code>Pairing</code> over weirdnet-net),
<code>compact</code>, <code>reach</code>, <code>relays</code> and <code>wire</code> (CBOR messages).</p>
<h3>0.3.1 and 0.4.0</h3>
<p>0.3.1 depends on <code>weirdnet-net = "0.8"</code> and <code>weirdnet-keys = "0.1"</code> with caret ranges, so it shares a tree
with weirdnet-keys 0.1.1 and net 0.8.1. 0.4.0 adds service links (above) and raises link requests to 1 MiB; the rest of the API
and the full transfer are unchanged.</p>
<h3>0.4.2 and 0.3.3</h3>
<p><a href="https://docs.rs/weirdnet-device-link/0.4.2">0.4.2</a> (and <a href="https://docs.rs/weirdnet-device-link/0.3.3">0.3.3</a>
on the 0.3 line) adds what Morph had built on top of the crate, without changing anything already there:</p>
<ul>
<li><code>offer_scheme(schemes, text)</code>: which of several schemes a new device's code is on (its
<code>&lt;scheme&gt;link/</code> prefix in any case) and the code normalized for <code>decode_link</code>. The prefix is not
signed, so an app can pair with codes another app made with this crate under its own scheme.
<code>is_offer(scheme, text)</code> is the counterpart of
<code>is_invite</code>.</li>
<li><code>link_node_config(label, relays)</code>: a link node's <code>NodeConfig</code>, listening on TCP and QUIC on every
interface with the link limits. <code>known_relays()</code> is <code>KNOWN_RELAYS</code> as multiaddrs,
<code>parse_relays</code> reads a comma-separated relay list, and <code>relays_from_env(VAR)</code> reads one from the app's
own environment variable (set but empty means no relays; unset means the known relays).</li>
</ul>
<h3>Moving to 0.3.0</h3>
<p>Codes changed: offers and invites are compact CBOR arrays (protocol version 2). A 0.2 code read by a 0.3 device, or the
other way round, says to update rather than that the code is damaged, so put both devices on apps with the same version.
The stream ids stay <code>/weirdnet/link/2</code> and <code>/weirdnet/link-invite/2</code>. Version mismatches are now
<code>Error::OlderCode</code> and <code>Error::NewerCode</code> (were <code>Error::Invalid</code>); match them to word the
message with your app's name. Link nodes now apply <code>with_link_limits</code> to the <code>NodeConfig</code> you pass.
Everything else is added: <code>compact</code>, <code>reach</code>, <code>relays</code>, <code>Pairing::send_with</code>,
<code>session::make_transfer_with</code> and <code>net_status()</code> on <code>HostNode</code>, <code>Pairing</code> and
<code>InviteHost</code>.</p>
<h3>Moving to 0.2.0</h3>
<p>0.2.0 is built on weirdnet-net 0.8.0. Its streams moved to <code>/weirdnet/link/2</code> and
<code>/weirdnet/link-invite/2</code> (were <code>/1</code>), so a 0.1 device and a 0.2 device fail to connect rather than
misread each other: put both devices on apps with the same version. Offers, links, codes and the sealed transfer are
unchanged, and so is the API.</p>
''',
  ),
  'ext': Guide(
    brings: r'''
<p>Let an app (Morph first) run third-party extensions without trusting them: signed packages pinned to their author, the
user's grants checked on every call, and an OS sandbox that leaves the extension no network, no files beyond its own and no
<code>socket()</code>. Everything goes through the host over a private gRPC socket.</p>
<p>Three crates in one repository: weirdnet-ext (the host side, this page), <a href="/crates/ext-proto">weirdnet-ext-proto</a>
(the contract) and <a href="/crates/ext-sdk">weirdnet-ext-sdk</a> (for extension authors).</p>
''',
    works: r'''
<ul>
<li><b>Packages</b> (<code>package</code>): a tar archive with <code>manifest.json</code>, <code>manifest.sig</code> and the
files. The author's Weirdnet user key (Ed25519) signs the exact manifest bytes, and the manifest lists every file with its
size and BLAKE3. Opening checks all of it and refuses unlisted files, links, unsafe paths and oversized archives.</li>
<li><b>Install and update</b> (<code>Installer</code>): one read-only directory per version. Each extension id is pinned to
its first author, even after an uninstall. An update must be newer, and <code>Plan::new_capabilities</code> lists what it adds
so the app can ask. Every launch hashes the files again.</li>
<li><b>Grants</b> (<code>Grants</code>): capabilities such as <code>page.read</code>, <code>net.fetch</code> or
<code>storage</code>, with optional <code>*</code> patterns, checked on every call; a revoked capability fails the next
call.</li>
<li><b>Sandbox</b>: empty environment, own process group, resource limits, parent-death signal, and only the private socket
inherited. Linux adds <code>no_new_privs</code>, Landlock (files limited to the package, system libraries and the data
directory; TCP denied; abstract sockets and signals scoped on 6.12+) and a seccomp filter (no <code>socket()</code>,
namespaces, mounts, <code>ptrace</code>, <code>bpf</code>, <code>io_uring</code>, keyrings, modules or terminal injection).
macOS uses a deny-by-default <code>sandbox-exec</code> profile. <code>sandbox::probe</code> reports what a machine gives, and
the default <code>Require::Full</code> refuses to run with less.</li>
<li><b>Supervisor</b>: starts the extension with a fresh socket pair and a one-time token, serves the broker
(<code>weirdnet.ext.v1.Host</code>), restarts crashes with backoff and gives up after repeated ones, stops idle extensions and
kills stuck ones after a grace period. App services come in through the <code>Services</code> trait.</li>
</ul>
<table>
<tr><th>OS</th><th>Native extensions</th></tr>
<tr><td>Linux 5.13+</td><td>Landlock + seccomp (network rules from 6.7, signal and abstract-socket scoping from 6.12)</td></tr>
<tr><td>macOS</td><td><code>sandbox-exec</code> deny-by-default profile</td></tr>
<tr><td>Windows</td><td>not yet</td></tr>
</table>
<p><code>tests-e2e</code> builds a real extension, installs it and runs it in the sandbox, which tries to read
<code>/etc/passwd</code>, write outside its data directory, open sockets, <code>ptrace</code>, <code>unshare</code> and use
<code>io_uring</code>. It also covers crash restarts, idle stops, grant revocation and a tampered install.</p>
''',
  ),
  'ext-proto': Guide(
    brings: r'''
<p>The one wire contract between any Weirdnet extension host and its extensions, <code>weirdnet.ext.v1</code>, with tonic
client and server stubs. App-specific services (such as Morph's <code>morph.ext.v1</code>) ride inside it as bytes, so the
contract is the same for every app. protoc is bundled; nothing to install.</p>
''',
    works: r'''
<p>The host serves <code>Host</code> on the private socket it made for the extension:</p>
<ul>
<li><code>Handshake</code>: the one-time token, the extension id and the API version.</li>
<li><code>Events</code> (a server stream): stop, grant changes, pings and app events.</li>
<li><code>Call</code>: an app service and method with a prost-encoded payload, checked against the grants.</li>
<li><code>Log</code> and <code>Health</code>.</li>
</ul>
<p>Constants: <code>API_VERSION</code> (1), the environment variables the host sets (<code>WEIRDNET_EXT_SOCKET</code>,
<code>WEIRDNET_EXT_FD</code>, <code>WEIRDNET_EXT_TOKEN</code>, <code>WEIRDNET_EXT_ID</code>) and the
<code>x-weirdnet-session</code> header. The schema is <code>proto/weirdnet/ext/v1/ext.proto</code>. Hosts use
<a href="/crates/ext">weirdnet-ext</a>; extensions use <a href="/crates/ext-sdk">weirdnet-ext-sdk</a>.</p>
''',
  ),
  'ext-sdk': Guide(
    brings: r'''
<p>Write a Weirdnet extension in Rust. A host such as Morph starts your binary in its sandbox with a private socket and a
one-time token; the SDK uses them to connect and hand-shake, and gives you calls into the app, logging, health reports and
the app's events.</p>
''',
    works: r'''
<ul>
<li><code>Extension::connect(version)</code> reads the socket and token the host set, does the handshake and returns a
session with the extension id, the host and the API version.</li>
<li><code>granted()</code> and <code>has(name)</code> show what the user granted; <code>call(service, method, payload)</code>
calls an app service (for example <code>morph.ext.v1.Notes</code>), which the host checks against the grants.</li>
<li><code>log</code> and <code>health</code> report to the host; <code>run(on_event)</code> handles app events until the host
says stop.</li>
</ul>
<p>The sandbox leaves you no network, no files outside your package and data directory, and no <code>socket()</code> call:
everything goes through the host.</p>
''',
  ),
  'weirdnetctl': Guide(
    brings: r'''
<p>The maintainer's tool for Weirdnet signing keys. It holds and rotates the <a href="https://weirdbrains.com">WeirdBrains</a> root key, signs prefix and scheme
records for <a href="/crates/schemes">weirdnet-schemes</a>, countersigns reserved <code>weirdnet…</code> records, builds the
canonical list, and verifies all of them. App publishers use it to sign their own prefix and scheme.</p>
''',
    works: r'''
<ul>
<li>Keys are Ed25519, sealed with a passphrase (Argon2id, then XChaCha20-Poly1305) in JSON key files created 0600 and never
overwritten. The public key and label are in the clear and bound to the sealed key. The passphrase is prompted for, or read
from <code>--passphrase-file</code> or <code>WEIRDNETCTL_PASSPHRASE_FILE</code>; typed passphrases need at least 12
characters. <code>--unencrypted</code> is for tests only.</li>
<li>Commands: <code>key new</code>, <code>show</code>, <code>check</code> and <code>rotate</code>; <code>prefix</code> and
<code>scheme</code> (with <code>--withdraw</code> for withdrawals); <code>countersign --as root</code> and
<code>--as transfer</code>; <code>list</code> (build and sign the canonical list, then check it loads); <code>verify</code>
against <code>--anchor</code> keys.</li>
<li>Rotating the root: <code>key rotate</code> makes a new key and a rotation signed by both; publish the rotation, ship the new
public key as an anchor in app updates (apps follow it with <code>TrustAnchors::rotate</code>), sign the next list with the new
key, and keep the old key offline.</li>
</ul>
''',
    install: r'''cargo install weirdnetctl
weirdnetctl key new --label weirdbrains-root --out root.key
weirdnetctl key show root.key            # public key and id: ship it as the trust anchor
weirdnetctl prefix --key morph.key --prefix weirdnet-morph --seq 1 -o prefix.json
weirdnetctl list --key root.key --seq 42 prefix.json scheme.json -o canonical.json
weirdnetctl verify --anchor "$(weirdnetctl key show root.key | head -1)" canonical.json''',
  ),
};
