/// The Weirdnet crates, from their READMEs.
library;

enum Status { shipped, fresh }

class Crate {
  const Crate({
    required this.slug,
    required this.tagline,
    required this.about,
    required this.parts,
    this.status = Status.shipped,
    this.usedBy = const [],
    this.dependsOn = const [],
    this.example = '',
    this.notes = '',
    this.group = 'Building blocks',
    this.origin = '',
    this.version = '',
    this.crateName = '',
    this.repo = '',
    this.binary = false,
    this.docsRs = true,
  });

  final String slug;
  final String tagline;

  /// Paragraphs (HTML).
  final List<String> about;

  /// Module or feature bullets (HTML).
  final List<String> parts;
  final Status status;
  final List<String> usedBy;
  final List<String> dependsOn;
  final String example;
  final String notes;
  final String group;

  /// Where the code came from.
  final String origin;

  /// The latest version on crates.io; empty while unpublished.
  final String version;

  /// The crate name when it is not `weirdnet-<slug>` (weirdnetctl).
  final String crateName;

  /// The GitHub repository when it is not the crate name (crates in a workspace repo).
  final String repo;

  /// A program you install rather than a library you depend on.
  final bool binary;

  /// Has a library target, so docs.rs has API docs.
  final bool docsRs;

  String get name => crateName.isNotEmpty ? crateName : 'weirdnet-$slug';
  String get repoName => repo.isNotEmpty ? repo : name;
  bool get published => version.isNotEmpty;
}

const crates = <Crate>[
  Crate(
    slug: 'net',
    version: '0.8.3',
    group: 'Network',
    tagline: 'The libp2p node, streams, app calls, key exchanges, invitations, sealed messaging, identities and certificates.',
    about: [
      'Peer-to-peer networking for applications that keep their own data. The application brings its own request and response types, its own storage and its own policy; the crate brings the wire.',
      'Every identifier on the wire or under a signature comes from a <code>Profile</code>. <code>WEIRDNET</code> is the default (<code>/weirdnet/net/2</code>, <code>wnet-x1-offer:</code>, port 4747 and so on). Key cryptography is not here: every derivation, seal and open goes through <code>weirdnet-keys</code>.',
    ],
    parts: [
      '<code>node</code>: a <code>Node&lt;Q, R&gt;</code> over TCP and QUIC (or an in-memory transport for tests) with Noise and Yamux, mDNS, Kademlia, identify, ping, a relay client and an opt-in relay server, DCUtR hole punching and AutoNAT. The swarm runs on its own thread; the handle is blocking. Requests are the application’s <code>Q</code>, answers its <code>R</code>, in CBOR with every byte field as one byte string (0.8.0).',
      '<code>names</code>: signed peer records and withdrawals, a names (rendezvous) server, checked DHT records under <code>SHA-256("weirdnet/peer/" + user id)</code>, <code>_weirdnet.&lt;name&gt;</code> TXT bindings, and key-only dialing (<code>request_key</code>, <code>request_user</code>).',
      '<code>app</code>: app calls for <code>weirdnet-&lt;app&gt;://</code> URLs. <code>Node::serve_app</code> serves an app (and announces it through identify), <code>Node::resolve_app</code> finds the peers serving it for a peer id, user id or bound name, and <code>Node::app_call</code> sends an HTTP-like request with a streamed body and gets a streamed response, directly or through relays. One stream per call on <code>/weirdnet/app/1</code> with CBOR heads; heads capped at 16 KiB, bodies uncapped, a 60-second idle timeout.',
      '<code>stream</code>: byte streams with no size cap, backpressure and per-protocol limits, moving between relayed and direct paths without losing a byte; sealed streams bound to an exchange.',
      '<code>exchange</code>: signed offers and answers (Ed25519 node keys, fresh X25519 keys), the derived exchange key, a ten-digit short code and a fingerprint to compare out of band, tokens and links, scopes with an expiry, sealed messages bound to the exchange and direction.',
      '<code>sealed</code>: send a sealed request through the application’s envelope and open the answer (<code>call</code>), and answer one only for the exchange’s own, Noise-authenticated peer (<code>serve</code>).',
      '<code>invite</code>: invitation automation: connect, offers answered on the spot or kept for the owner, poll and settle, crossing offers settled on one exchange, trust on first use and impostor warnings.',
      '<code>identity</code>, <code>user</code>, <code>sync</code>, <code>shard</code>, <code>addr</code>: node identities, user certificates, revocations, cards and link grants, the linked-node sync key, dark-shard blobs and address helpers.',
      '<code>android_context_init!</code> and <code>android::init_context</code> (0.8.1, Android builds): export the JNI method an app calls once at startup so <code>ndk-context</code> is set before a node resolves DNS.',
    ],
    dependsOn: ['keys'],
    usedBy: ['Morph', 'Muninn', 'weirdnet-relay', 'weirdnet-sync', 'weirdnet-device-link'],
    origin: 'Muninn',
    notes: 'Not audited. Tested over libp2p’s in-memory transport with real Noise, Yamux and request-response. See <code>SECURITY.md</code> in the repository for what the crate enforces and what it leaves to the application. Version 0.8.3 is on <a href="https://crates.io/crates/weirdnet-net/0.8.3">crates.io</a> (<a href="https://docs.rs/weirdnet-net/0.8.3">docs.rs</a>). 0.8.3 is a fix with no API change: an accepted stream that both sides have ended stops counting against <code>Limits::max_streams</code> right away, instead of until its driver finishes lingering. 0.8.1 is additive: the Android <code>ndk-context</code> init that Morph and Bragi each carried a copy of.',
  ),
  Crate(
    slug: 'service',
    version: '0.1.0',
    group: 'Network',
    tagline: 'A service framework: typed request/response services and live topic feeds behind an Authorize hook, over weirdnet-net.',
    about: [
      'One server, many apps. A server exposes typed request/response services and live topic feeds; desktop, terminal, mobile and MCP clients connect over <code>weirdnet-net</code> streams, and every call and subscription goes through an <code>Authorize</code> hook first.',
    ],
    parts: [
      '<code>Service</code>: your own request and response types. A session is one stream: credentials once, then concurrent calls with ids, cancellation, per-call deadlines and a bounded queue that answers <code>Busy</code> when full.',
      '<code>Access</code>, <code>Admitted</code>, <code>Authorize</code>: each request names a permission, optionally on a resource; the hook says who was admitted and the handler gets it. <code>RosterAuth</code>, <code>MembershipAuth</code>, <code>AllOf</code>, <code>AnyOf</code>, <code>AllowAll</code> or a closure.',
      '<code>Hub</code>: live feeds with a snapshot, then deltas, resume after a reconnect, coalescing for slow subscribers, throttling, heartbeats and periodic re-authorization. <code>Live</code>: a local copy of a topic that reconnects and resumes on its own.',
      '<code>ProtocolId</code>: versioned protocol ids served side by side; <code>Client::session_any</code> picks the newest the server has.',
      '<code>Channel</code>: the transport-neutral core; <code>net</code> adds <code>Server</code>, <code>NetDialer</code> and stream channels for weirdnet-net 0.8.',
    ],
    dependsOn: ['net'],
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-service">crates.io</a> (<a href="https://docs.rs/weirdnet-service/0.1.0">docs.rs</a>). The API may change before 1.0.',
  ),
  Crate(
    slug: 'relay',
    version: '0.6.1',
    binary: true,
    group: 'Network',
    tagline: 'A relay and bootstrap node you can run: circuit relay v2, Kademlia server, an info page.',
    about: [
      'A small daemon on <code>weirdnet-net</code> with <code>relay_server</code> on. Phones and other nodes behind NAT reserve a slot and become reachable at <code>…/p2p/RELAY/p2p-circuit/p2p/PEER</code>; DCUtR tries a direct path first and the circuit is the fallback.',
      'It also serves the Kademlia DHT, announces itself under the relay provider key, answers AutoNAT probes, and publishes a page with its name, peer id and addresses for people and apps to add it.',
    ],
    parts: [
      'Circuit relay v2 server with configurable limits (unlimited by default).',
      'Kademlia server mode and the <code>/weirdnet/relay/1</code> provider record, so nodes find relays they were not configured with.',
      'Its node key and state in a SQLCipher database (<code>weirdnet-storage</code>), keyed from a systemd credential.',
      'A names server (<code>/weirdnet/names/2</code>, weirdnet-net 0.8) for signed peer records, kept in the same database.',
      'An info page: HTML at <code>/</code> and <code>/.well-known/weirdnet-relay.json</code>.',
      'A TOML config file, flags and environment variables; structured logs; a hardened systemd unit.',
    ],
    dependsOn: ['net', 'storage', 'push', 'update'],
    usedBy: ['<a href="https://weirdbrains.com">WeirdBrains</a> public relays', 'self-hosters'],
  ),
  Crate(
    slug: 'tls',
    version: '0.3.0',
    group: 'Network',
    tagline: 'TLS certificates: ACME issuance and renewal, certificate stores and an SNI resolver for rustls.',
    about: [
      'Certificates from Let’s Encrypt or any ACME directory over <code>instant-acme</code>, kept current in the background and served through a rustls resolver that swaps them without a restart. It is the shared replacement for the ACME code in Mouser, Muninn, itcmdr and TAUR.',
      'A failed order never drops TLS: the last certificate stays in service, and the crate never falls back to plain HTTP. HTTP servers and port forwarding are left to the app.',
    ],
    parts: [
      '<b>ACME</b>: an account per directory, several names per certificate, wildcards, ACME profiles, <code>replaces</code> on renewal.',
      '<b>Challenges</b>: TLS-ALPN-01 answered by the resolver, HTTP-01 from a token board, DNS-01 by a hook command, a manual prompt or a <code>grindvakt-core</code> provider.',
      '<b>Stores</b>: files (0600), memory, or a table in an encrypted <code>weirdnet-storage</code> database.',
      '<b>Resolver</b>: per-name certificates in the order pinned, user, ACME, self-signed, with a default for handshakes without SNI.',
      '<b>Renewal</b>: inside the CA’s renewal window (ARI), else two thirds into the lifetime; backoff from an hour to a day; a typed status.',
      '<b>Testing</b>: a mock ACME CA that checks the real challenge answers.',
    ],
    dependsOn: ['storage'],
    origin: 'Mouser',
    notes: 'Version 0.3.0 is on <a href="https://crates.io/crates/weirdnet-tls">crates.io</a> (<a href="https://docs.rs/weirdnet-tls/0.3.0">docs.rs</a>). It adds app prefixes and extra variables for DNS hooks (<code>HookDns::with_prefix</code>, <code>with_env</code>), an offline renewal schedule read from the store (<code>acme::schedule</code>), the ACME certificate as the default for handshakes without SNI (<code>Acme::with_default_cert</code>), forced renewals from the running renewer behind the repeat-certificate guard (<code>Acme::trigger_renewal</code>), challenge-only TLS-ALPN-01 and HTTP-01 listeners (<code>Acme::serve_challenge</code>), and importing an app’s earlier account, certificate and state (<code>Acme::import</code>). 0.3.0 is breaking: <code>valid_name</code> and <code>AcmeConfig::validate</code> refuse <code>localhost</code>, IP addresses and all-digit top labels unless <code>AcmeConfig::private_names</code> is set for a private CA, <code>AcmeConfig</code> is <code>#[non_exhaustive]</code> (build it with <code>AcmeConfig::new</code>), and <code>HookDns</code> is built with <code>HookDns::new</code>.',
  ),
  Crate(
    slug: 'keys',
    version: '0.1.2',
    group: 'Keys and storage',
    tagline: '256-bit keys, BIP39 words, Shamir shards, KDFs, sealing, X25519 and an envelope keyring.',
    about: [
      'Key material and key policy, built only on vetted RustCrypto, dalek, BIP39, vsss-rs and age crates. Nothing here invents a cipher, a KDF or a format of its own.',
      'Every label (HKDF info, associated data, shard prefix, claim salt) comes from a <code>Profile</code>; envelopes record their format, so a file written under one profile is refused under another.',
    ],
    parts: [
      '<code>Key32</code>: a 256-bit key, wiped on drop, never printed.',
      '<code>words</code>: the 24 BIP39 words for a key. <code>shards</code>: Shamir k-of-n split and combine with a checksummed text form.',
      '<code>kdf</code>: HKDF-SHA256 and Argon2id. <code>aead</code>: XChaCha20-Poly1305 <code>Sealed</code>. <code>password</code>: Argon2id password sealing and claim tags. <code>mac</code>: HMAC-SHA256. <code>exchange</code>: X25519 agreement with a contributory check.',
      '<code>keyring</code>: envelope encryption for a database key, wrapped by a versioned service key and by a key derived from the master key: init, unlock, rotate, rekey with undo, recover, verify, export.',
      '<code>dark</code>: shards sealed with a shard password for custodians. <code>age</code>: password age files for exports.',
    ],
    usedBy: ['weirdnet-net', 'weirdnet-sync', 'weirdnet-push', 'weirdnet-device-link', 'Morph'],
    origin: 'Muninn',
    notes: 'Not audited. The shard checksum catches typos, not forgery: a forged share combines into a wrong key, which verification then rejects.',
  ),
  Crate(
    slug: 'storage',
    version: '0.1.2',
    group: 'Keys and storage',
    tagline: 'SQLCipher databases opened with a caller-supplied raw key, migrations, savepoints, hot standby replication with failover, and long-term retention.',
    about: [
      'General storage for SQLite databases encrypted with SQLCipher. The crate knows no schema and no brand: callers bring their migrations, table registry and queries.',
      'It never derives, wraps, stores, recovers or exports a key, and never sees a password. Opening with a key fails if SQLite was built without SQLCipher, so a key is never silently ignored.',
    ],
    parts: [
      '<code>open</code>, <code>open_readonly</code>, <code>open_in_memory</code>: open with a raw 32-byte key and verify it, in a private folder (0700) and file (0600).',
      '<code>rekey</code> and <code>encrypt_plaintext_in_place</code>.',
      '<code>migrate</code>: ordered migrations in one transaction, with a hook after each one.',
      '<code>savepoint</code>, <code>begin</code>/<code>release</code>/<code>rollback</code>: all-or-nothing units that nest.',
      '<code>files</code> (private files written through a side file), <code>snapshot_to</code> (online copies), and <code>sync</code>: a trigger-kept change log, row codec and hash, three-way merge decisions.',
      '<code>replicate</code> (<code>replication</code> feature): a primary and hot standbys kept current from an append-only, hash-chained log written in the same transaction as the data, with epochs that fence an old primary, manual or automatic failover (a <a href="/crates/sync">weirdnet-sync</a> lease with <code>lease</code>), and fail-back.',
      '<code>replicate::service</code> (<code>replication-service</code> feature): the log as a <a href="/crates/service">weirdnet-service</a> service, so standbys follow over <a href="/crates/net">weirdnet-net</a> as linked devices or roster grants.',
      '<code>retention</code> (<code>retention</code> feature): minimum-age policies (for example seven years) that refuse earlier deletes and edits, a hash-chained seal ledger, purges of expired rows only, verification, and encrypted archives for cold storage.',
    ],
    usedBy: ['Morph', 'weirdnet-relay', 'weirdnet-tls'],
    origin: 'Muninn',
    notes: '0.1.2 is additive: replication, failover and retention sit behind new features, and the defaults are unchanged. Replication is asynchronous: a failover can lose the old primary’s last unreplicated writes, which that node rewinds and keeps. Retention triggers stop the app’s own code; someone holding the key can still rewrite the file, which verification, replicas and archives make evident.',
  ),
  Crate(
    slug: 'vault',
    version: '0.1.0',
    group: 'Keys and storage',
    tagline: 'An encrypted secret and credential store: sealed values, scopes, per-identity grants, rotation and a hash-chained audit log.',
    about: [
      'A secret and credential store for servers and apps that keep API credentials, tokens and passwords for many tenants and identities. Plaintext stays in the process unless an approved identity retrieves it.',
      'Values sit in a SQLCipher database (<code>weirdnet-storage</code>) and each version is sealed again on its own with XChaCha20-Poly1305 (<code>weirdnet-keys</code>), bound to its secret, version, environment and scope. Every call is checked and recorded in an audit log that never holds a value.',
    ],
    parts: [
      '<code>Vault</code>: create, list, use, reveal, rotate, delete, grant and revoke, with the audit log and snapshots. <code>AsyncVault</code> runs each call on Tokio’s blocking pool.',
      '<code>Scope</code> (hierarchical, such as <code>tenant-7/provider-a</code>) and <code>Environment</code> (<code>Test</code> or <code>Live</code>): a dry-run caller never reaches a live secret.',
      '<code>Authorize</code>, <code>RolePolicy</code>, <code>Caller</code>, <code>Action</code>: your policy hook on every call, with example roles you assign per scope.',
      '<code>Grant</code>, <code>GrantTarget</code>, <code>GrantAction</code>: <code>Use</code> and <code>Reveal</code> approvals per identity on a secret or scope, with an optional expiry; <code>RecipientSealed</code> seals a retrieved value to the recipient’s X25519 key.',
      '<code>AuditRecord</code>, <code>AuditQuery</code>, <code>verify_chain</code>: the hash-chained, append-only log and its queries.',
      '<code>KeyStore</code>, <code>VaultHome</code>: where the database key comes from (a password keyring, an OS keychain, a weirdnet-sync secret store or your own).',
    ],
    dependsOn: ['keys', 'storage'],
  ),
  Crate(
    slug: 'update',
    version: '0.2.2',
    group: 'Building blocks',
    tagline: 'Signed update metadata: org roots, manifests, freshness, verification, targeting, rollouts, consent, boot health.',
    about: [
      'Signed update metadata and client-side checks for Weirdnet apps. Salty Gull, the <a href="https://weirdbrains.com">WeirdBrains</a> over-the-air update service, builds on it; nothing here is Flutter-specific.',
      'Updates are never forced: the consent policy asks for each update by default, and new capabilities always ask.',
    ],
    parts: [
      '<b>Org roots</b>: k-of-n Ed25519 root keys, release-key delegations scoped to apps and channels, optional timestamp keys, pinned by a BLAKE3 fingerprint.',
      '<b>Manifests</b>: app, channel, seq, kind (assets, Wasm, full package, store notices), per-file size and BLAKE3, targeting, staged rollout, rollback target, expiry.',
      '<b>Envelopes</b>: signatures over the exact CBOR payload with the domains <code>weirdnet-update/v1/root|manifest|freshness</code>.',
      '<b>Client</b>: the acceptance rule and anti-rollback state. <b>Targeting and rollout</b> on the device, no install id needed.',
      '<b>Consent</b> and <b>boot health</b>: trial boots, commit on ready, local rollback after two failed boots.',
    ],
    usedBy: ['Salty Gull', 'weirdnet-relay'],
    origin: 'Salty Gull',
    notes: 'Version 0.2.1 is on <a href="https://crates.io/crates/weirdnet-update">crates.io</a> (<a href="https://docs.rs/weirdnet-update/0.2.1">docs.rs</a>). 0.2.1 reserves <code>UNSIGNED</code> (<code>"unsigned"</code>) as the signing identity of plain tar.gz and zip file sets and refuses it for other formats; <code>FullPackage::signing_identity_matches</code> keeps an update from stripping or adding a platform signature.',
  ),
  Crate(
    slug: 'accounts',
    version: '0.2.0',
    group: 'Identity and access',
    tagline: 'Multi-tenant accounts with weirdnet-access roles, invitations, revocations and one authorization hook, plus Argon2id passwords, hashed tokens, name rules, rate limits and API keys.',
    about: [
      'Account building blocks for <a href="https://weirdbrains.com">Weird Brains</a> services. The password, token, name, rate-limit and API-key rules were extracted from TAUR; since 0.2 the crate also has a multi-tenant accounts model where one server hosts many accounts, each with many identities holding <a href="/crates/access">weirdnet-access</a> roles.',
      'The model persists through a <code>Store</code> interface. The optional <code>SqliteStore</code> keeps its records in a SQLCipher database of its own, so it never touches an app\'s schema.',
    ],
    parts: [
      '<code>account</code>: accounts (tenants) with an owner, a status and their own role set; members, invitations, revocations and API-key bindings.',
      '<code>catalog</code>: account permissions on the weirdnet-access core, <code>tiered</code> role sets and a <code>standard</code> preset.',
      '<code>authz</code>: <code>Authorizer</code>, one hook for account-scoped requests: identity, account status, membership, then <code>enforce::decide</code>.',
      '<code>directory</code>: <code>Accounts</code>, the checked operations on accounts, members, invitations and key bindings, with the rank rules.',
      '<code>store</code>: the <code>Store</code> interface and <code>MemoryStore</code>; <code>sqlite</code>, <code>net</code> and <code>service</code> features add a SQLCipher store, signed memberships and a <a href="/crates/service">weirdnet-service</a> hook.',
      '<code>password</code>, <code>token</code>, <code>names</code>, <code>ratelimit</code>, <code>apikeys</code>: the 0.1 primitives, unchanged.',
    ],
    dependsOn: ['access'],
    usedBy: ['TAUR', 'Salty Gull'],
    origin: 'TAUR',
    notes: 'Version 0.2.0 is on <a href="https://crates.io/crates/weirdnet-accounts/0.2.0">crates.io</a> (<a href="https://docs.rs/weirdnet-accounts/0.2.0">docs.rs</a>, <a href="https://github.com/WeirdBrains/weirdnet-accounts/blob/main/CHANGELOG.md">CHANGELOG</a>). The 0.1 modules and their <code>Error</code> are unchanged, so moving from 0.1 is changing the requirement to <code>"0.2"</code>.',
  ),
  Crate(
    slug: 'chart',
    version: '0.1.0',
    tagline: 'Real-time charts: line, area, bar, candlestick, OHLC and volume series with axes, pan, zoom and live updates, with optional GPUI and Ratatui backends.',
    about: [
      'Real-time charts for <a href="https://weirdbrains.com">Weird Brains</a> apps on Weirdnet. The core is renderer-independent and has no GUI dependencies; <a href="https://crates.io/crates/gpui">GPUI</a> and <a href="https://crates.io/crates/ratatui">Ratatui</a> backends are optional features.',
    ],
    parts: [
      '<code>Series</code>: time-ordered ring buffers of points or candles, with live-candle replacement and trades folded into fixed-interval candles.',
      '<code>Pane</code>s stacked over one time axis, each with its own y axis, and marks: <code>Line</code>, <code>Area</code>, <code>Bars</code>, <code>Candles</code>, <code>Ohlc</code> and <code>Volume</code>.',
      'A viewport with pan, zoom, span limits and following the newest data.',
      'Per-pixel reduction of lines and merging of thin candles, so only the visible range is laid out.',
      '<code>FrameThrottle</code> for frame-rate redraws, and backend-neutral scenes from <code>Chart::layout</code>.',
    ],
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-chart/0.1.0">crates.io</a> (<a href="https://docs.rs/weirdnet-chart/0.1.0">docs.rs</a>, <a href="https://github.com/WeirdBrains/weirdnet-chart">repository</a>, tag <a href="https://github.com/WeirdBrains/weirdnet-chart/releases/tag/v0.1.0">v0.1.0</a>).',
  ),
  Crate(
    slug: 'exchange',
    version: '0.1.0',
    tagline: 'Exchange-neutral trading types and traits: instruments, exact decimal prices and sizes, orders with a state machine, fills, positions, market data, adapter traits and an in-memory paper exchange.',
    about: [
      'Exchange-neutral trading types and traits for <a href="https://weirdbrains.com">Weird Brains</a> apps on Weirdnet. Adapters for real venues live in their own crates and implement the traits here; apps talk to the traits and can swap in the in-memory <code>Paper</code> exchange for tests and dry runs. The crate has no exchange adapters and makes no network calls.',
    ],
    parts: [
      '<code>Price</code> and <code>Qty</code>: exact decimals with explicit rounding to a product\'s increments.',
      'Instruments (<code>Market</code>, <code>Product</code>) and orders with an <code>Order</code> state machine that refuses impossible transitions and overfills.',
      'Fills, balances, fee tiers, positions and a <code>PositionBook</code> with realized and unrealized PnL.',
      'Market data: trades, tickers, an <code>OrderBook</code> that reports sequence gaps, candles.',
      '<code>MarketData</code> and <code>Trading</code> adapter traits, cost models, a shared rate limiter, environment-checked credentials and the <code>Paper</code> exchange.',
    ],
    dependsOn: ['vault', 'service'],
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-exchange/0.1.0">crates.io</a> (<a href="https://docs.rs/weirdnet-exchange/0.1.0">docs.rs</a>, <a href="https://github.com/WeirdBrains/weirdnet-exchange">repository</a>). weirdnet-vault and weirdnet-service are optional features.',
  ),
  Crate(
    slug: 'mcp',
    version: '0.6.2',
    tagline: 'A stateless Model Context Protocol server for tools, resources and prompts, with sync or async tools, image and audio results, stdio and streamable HTTP servers, plus an optional MCP client and agent tool source.',
    about: [
      'A stateless MCP server extracted from TAUR and shared with Salty Gull, Ymir and Bragi. Since 0.6.0 it serves both protocol eras: clients that open with <code>initialize</code> (2024-11-05 to 2025-11-25, with output unchanged from 0.5) and clients that send the version in each request’s <code>_meta</code> (<a href="https://modelcontextprotocol.io/specification/2026-07-28">MCP 2026-07-28</a>), including <code>server/discover</code>, <code>resultType</code> and caching hints.',
      '0.6.0 adds async tools, nested object, enum, array and <code>anyOf</code> parameter types, image and audio tool results, resources, a stdio server loop, and a streamable HTTP endpoint with bearer auth and <code>Host</code> and <code>Origin</code> checks against DNS rebinding (with a ready axum route).',
      'Since 0.2.0 it can also be the other side: an MCP client (feature <code>client</code>) and, with feature <code>agent</code>, a <a href="/crates/agent">weirdnet-agent</a> tool source, so an agent can use any MCP server’s tools. Both are off by default. The <code>agent</code> feature takes weirdnet-agent 0.4 or 0.5 (<code>">=0.4, &lt;0.6"</code>).',
      '0.6.1 adds prompts: <code>prompts/list</code> and <code>prompts/get</code> through optional <code>Tools</code> methods, advertised only when a server has prompts.',
      '0.6.2 lets clients read image and audio tool results: <code>CallToolResult::from_json</code> and <code>Client::call_tool_content</code> keep every content block, so a tool such as a video frame extractor can return its frames as images.',
    ],
    parts: [
      '<code>Server::handle</code> (sync) and <code>Server::handle_async</code>: one JSON-RPC 2.0 message or batch plus the caller’s bearer token in, the reply out: <code>initialize</code>, <code>server/discover</code>, <code>ping</code>, <code>tools/list</code>, <code>tools/call</code>, and with resources <code>resources/list</code>, <code>resources/templates/list</code> and <code>resources/read</code>.',
      '<code>ToolSpec</code> / <code>Param</code> / <code>ParamType</code>: <code>const</code> tool tables with input schemas (string, integer, number, boolean, string arrays, <code>Any</code>, <code>Enum</code>, <code>Array</code>, <code>Object</code>, <code>AnyOf</code>, raw <code>Json</code>) and read-only, destructive and open-world hints. <code>ToolSpec::check</code> finds mistakes in a table (0.6.0).',
      '<code>Tools</code>: the app implements <code>call</code> (sync, returns JSON) or <code>call_async</code> (returns a <code>CallToolResult</code>); failures become <code>isError</code> results. Optional resource methods and <code>cache_hint</code> (0.6.0), and <code>prompts</code> / <code>get_prompt</code> (0.6.1). <code>args</code>: argument getters with uniform messages.',
      '<code>PromptSpec</code> / <code>PromptArg</code>: <code>const</code> prompt tables with <code>PromptSpec::check</code>; <code>GetPromptResult</code> of user and assistant <code>PromptMessage</code>s; <code>PromptError</code> (0.6.1).',
      '<code>CallToolResult</code> / <code>Content</code>: text, image and audio (base64 plus <code>mimeType</code>), resource links and embedded resources, with <code>data:</code> URL and audio-format helpers that match weirdnet-agent 0.5 content parts (0.6.0). Since 0.6.2 <code>CallToolResult::from_json</code> and <code>Content::from_json</code> parse the wire JSON back (<code>{"type": "image", "data": &lt;base64&gt;, "mimeType": "image/png"}</code>, the same with <code>"audio"</code>), and <code>decoded_bytes</code>, <code>mime_type</code>, <code>is_image</code>, <code>is_audio</code>, <code>as_text</code> and <code>CallToolResult::text</code> read it.',
      '<code>stdio::serve_blocking</code>, and <code>stdio::serve</code> / <code>serve_with</code> (feature <code>stdio-server</code>): concurrent requests, <code>notifications/cancelled</code>, a 32 MiB message cap (0.6.0). <code>stdio::bridge</code>: the <code>&lt;app&gt;ctl mcp</code> loop that forwards stdio lines to a remote <code>/mcp</code>.',
      '<code>http</code> (feature <code>http-server</code>): <code>Guard</code> (<code>Host</code>, <code>Origin</code>, POST only, bearer <code>Auth</code>), <code>respond</code> and <code>respond_checked</code> for any framework on the <code>http</code> crate; <code>http::route</code> and <code>http::router</code> for axum 0.8 (feature <code>axum</code>) (0.6.0).',
      '<code>client</code> feature: <code>Client::connect(transport, ClientOptions)</code>, <code>list_tools</code> (follows cursors), <code>call_tool</code> and <code>call_tool_until</code> (text), and since 0.6.2 <code>call_tool_content</code> and <code>call_tool_content_until</code> (the full <code>CallToolResult</code> with images and audio); <code>StdioTransport</code> (<code>StdioCommand</code>) and <code>HttpTransport</code> (<code>HttpConfig</code>); <code>Secret</code> for tokens and environment values. The stdio transport reads server lines with a cap (<code>DEFAULT_MAX_LINE</code>, 4 MiB).',
      '<code>agent</code> feature: <code>agent::McpSource</code>, a <code>weirdnet_agent::ToolSource</code>, with <code>SourceOptions::tier_floor</code> (default <code>Research</code>); depends on weirdnet-agent <code>">=0.4, &lt;0.6"</code>.',
    ],
    usedBy: ['TAUR', 'Salty Gull (<code>saltyctl mcp</code>)'],
    origin: 'TAUR',
    notes: 'Version 0.6.2 is on <a href="https://crates.io/crates/weirdnet-mcp">crates.io</a> (<a href="https://docs.rs/weirdnet-mcp/0.6.2">docs.rs</a>); it adds parsing of image, audio and resource tool results for clients and changes nothing else. 0.6.1 adds prompts. 0.6.0 is breaking only because <code>ParamType</code> gained variants and is now <code>#[non_exhaustive]</code>; sync apps compile unchanged, and <code>initialize</code> now also negotiates 2025-11-25. See the <a href="https://github.com/WeirdBrains/weirdnet-mcp/blob/main/CHANGELOG.md">CHANGELOG</a>. 0.5.3 and 0.5.2 change only dependency ranges, metadata and docs. 0.1.0 and 0.2.0 to 0.5.1 are yanked; 0.1.1 is a metadata-only patch of 0.1.',
  ),
  Crate(
    slug: 'agent',
    version: '0.5.11',
    tagline: 'The agent runtime: a model-agnostic loop with streaming and cancel, tool sources, tiered approvals, research budgets and traces with citation checks, plus remote inference across the user’s own devices.',
    about: [
      'The shared agent loop for <a href="https://weirdbrains.com">WeirdBrains</a> apps; Morph’s Companions are its first user. The app brings the model, the tools and the approval UI; the crate runs each task, enforces the policy and budget, and records what happened. It has no app-specific types.',
      'Tool results reach the model wrapped as untrusted data, and nothing inside them can widen a permission. Local inference (<code>weirdnet-model</code>, with its <code>agent</code> feature) plugs in through its <code>ModelBackend</code> trait, and any MCP server’s tools through <a href="/crates/mcp">weirdnet-mcp</a> (feature <code>agent</code>, <code>McpSource</code>, a <code>ToolSource</code>). Since 0.2.0 the <code>remote</code> module runs model turns and whole tasks on another of the user’s own nodes; the core supplies only protocols over an app-supplied <code>Dialer</code>, so it does not depend on <code>weirdnet-net</code>.',
      '0.4.0 adds <code>/weirdnet-agent/infer/2</code> (CBOR, with priorities and a queue, reasoning and tool-call frames, embeddings and resume), a model catalog protocol, and a <code>Pool</code> that fails over and resumes an answer on another node without repeating text. The <code>pool</code> and <code>serve</code> features wire these to <a href="/crates/net">weirdnet-net</a> 0.8 and <a href="/crates/sync">weirdnet-sync</a> 0.5: finding inference nodes among the user’s linked devices, and serving them only to those devices.',
    ],
    parts: [
      'Speech out (0.5.11): <code>Purpose::Speak</code> (<code>speak</code> on the wire) with a <code>speech::SpeechProfile</code> per model (<code>CatalogModel::speech</code>: preset voices, designed and cloned voices, style instructions, multi-speaker scripts, raw input, speed, streaming, languages, formats, sample rate and limits, each absent when unknown; <code>tightest</code>, <code>narrowed_by</code>, <code>covers</code>) and <code>Catalog::route_speak</code>. infer/2 <code>ClientFrame::Speak(SpeakRequest)</code> (<code>SpeakInput::Text</code>, <code>Script</code> or <code>Raw</code>; <code>Voice::Preset</code>, <code>Design</code> or <code>Clone</code> with the reference clip as raw bytes and <code>consent</code>) answered by <code>Working</code>, one <code>SpeechStart</code>, <code>Audio</code> chunks of at most 256 KiB and <code>Done</code> with <code>Usage::input_chars</code> and <code>audio_ms</code>. Hosts implement <code>InferHost::open_speak</code> with a <code>SpeakBackend</code> returning an <code>AudioStream</code>; apps call <code>Pool::speak</code> or <code>Pool::speak_stream</code>, which fail over only before the audio starts.',
      'Native video (0.5.10): <code>ContentPart::video</code> and <code>ContentPart::video_bytes</code> build a <code>video_url</code> part (<code>ContentPart::VideoUrl</code>, a whole clip as a <code>data:video/...</code> URL, the part vLLM and mistral.rs take; <code>VideoUrl::mime_type</code>, <code>VideoUrl::data_len</code>) for models that read video natively. <code>Modalities::VIDEO</code> and <code>Modalities::with_video</code>; catalog entries say <code>inputs.video</code> (absent from older nodes, so their models never get a clip). <code>Catalog::route</code> and the pool send a clip only to a model that reads video, and a refusal ends with <code>catalog::VIDEO_FALLBACK</code> (send frames instead). <code>MediaLimits</code> gains <code>video_max_seconds</code>, <code>video_max_bytes</code> and <code>video_frames_per_minute</code>, each absent when unknown, with <code>video_frame_rate</code>, <code>video_frames</code> and <code>check_video</code>.',
      'Pool sharing (0.5.9): another Weirdnet identity uses a pool with its own device certificate, never the pool’s root identity, for catalog/1 and infer/2 only. <code>remote::share::PoolShare</code> is the share link (owner user id, optional name and expiry, inference node peer ids and addresses; <code>wnet-pool1:</code> token or <code>weirdnet-pool://share/</code> link, no secrets). Hosts: <code>serve::GuestAuth</code> verifies the guest credential (<code>encode_credential</code>: its <code>NodeCert</code> plus its user key) against the transport peer and asks the host’s <code>GuestPolicy</code> per <code>GuestScope</code> on every request; <code>SharedPoolAuth</code> combines it with <code>RosterAuth</code> (<code>identify</code>, <code>authorize_for</code>, <code>scoped</code>), and <code>CatalogFeed::rechecking</code> closes a revoked guest’s subscription. Guests: <code>pool::connect_shared</code>.',
      'Transcription (0.5.8): <code>Purpose::Transcribe</code> (<code>transcribe</code> on the wire), <code>Catalog::route_transcribe</code> and <code>Catalog::transcribers</code>; infer/2 <code>ClientFrame::Transcribe(TranscribeRequest)</code> (audio as raw bytes with its <code>format</code>, optional <code>language</code>, <code>prompt</code> and <code>timestamps</code>) answered by <code>Working</code> keepalives, one <code>Transcript</code> (text, language, duration and timed <code>Segment</code>s) and <code>Done</code>; hosts implement <code>InferHost::open_transcribe</code> and <code>TranscribeBackend</code>, apps call <code>Pool::transcribe</code>.',
      'Media limits (0.5.7): <code>MediaLimits</code> and <code>CatalogModel::limits</code> (<code>with_limits</code>): per-model <code>max_images</code>, <code>image_tokens</code>, <code>image_patch</code>, <code>image_edge</code>, <code>audio_max_seconds</code>, <code>audio_tokens_per_minute</code> and <code>max_request_bytes</code>, each absent when the node doesn’t know it, never defaulted, and left off the wire then; <code>image_cost</code>, <code>audio_cost</code>, <code>tightest</code> and <code>or</code> size and merge them.',
      '<code>AgentSession::run</code>: one task. Calls the <code>ModelBackend</code>, checks each tool call against the <code>Policy</code>, asks the app’s <code>Approver</code> when needed, charges the budget, runs the tool with a timeout and a <code>CancelToken</code>, and streams <code>AgentEvent</code>s: text, approvals, skipped-approval notices, tool start and finish, trace steps.',
      '<code>Tool</code>, <code>ToolSource</code>, <code>ToolRegistry</code>: in-process tools now, MCP servers and remote nodes as further sources. Per-source and per-tool switches; a tier override can only make a tool stricter.',
      '<code>Policy</code>: tiers <code>Read</code> (attached content), <code>Navigate</code>, <code>Research</code>, <code>Interact</code> and <code>Never</code>; per-agent, per-site <code>Off</code>, <code>Ask</code> and <code>Act</code>; approvals for once or for the task; revocable “Always allow” for navigate (a site or everywhere) and research (optionally one provider), for one agent or all. Off always wins, signed-in research is never covered by Always allow, and an all-agents allow covers an outside agent only after its first approval.',
      '<code>Budget</code>: searches, pages (with extensions), concurrency, per-page time and per-task tool time, tokens kept per page, model steps. Defaults: 3 searches, 12 pages (+5), 2 at a time, 15 s a page, 90 s of tool time a task (model turns and approval waits don’t count, since 0.3.0). When the page budget runs out, <code>Approver::extend_pages</code> can offer “+5 pages” (<code>PagesPrompt</code>; default no).',
      '<code>Trace</code>, <code>Citation</code>: every search, fetch, tool call, approval and notice is a step with its agent, node and session (logged out or signed in). <code>validate_citations</code> rejects a cited URL that none of its steps fetched; a citation without a step is never shown.',
      '<code>remote::infer</code>, <code>RemoteModel</code>: one model turn on another node, streamed, cancellable, with fallback to the next node or a local model (0.2.0). Since 0.4.0 <code>RemoteModel</code> speaks infer/2 and falls back to infer/1 for 0.3 nodes.',
      '<code>remote::infer::v2</code> (0.4.0): <code>/weirdnet-agent/infer/2</code> in CBOR. Priorities (<code>Interactive</code>, <code>Batch</code>, <code>Background</code>) behind <code>Queued{position}</code>, sampling, seed, response format, tools and raw mode; <code>Delta</code>, <code>Reasoning</code> and <code>ToolCall</code> frames with character offsets, <code>Usage</code>, and <code>Done</code> with metadata; f32 embeddings as byte strings. Hosts implement <code>InferBackend</code> and <code>EmbedBackend</code>, or keep a plain <code>ModelBackend</code>.',
      '<code>remote::pool::Pool</code> (0.4.0): tries nodes in order, cancels a stalled stream and resumes it elsewhere from the text already shown, runs embeddings and background jobs, and queries or subscribes to the catalog with failover. <code>remote::catalog</code>: <code>/weirdnet-agent/catalog/1</code>, the models nodes have and their state.',
      'Images and audio (0.5.0): <code>Message::content</code> is a <code>Content</code>, text or OpenAI-style parts (<code>ContentPart::text</code>, <code>ContentPart::image</code> with a <code>data:image/...</code> URL, <code>ContentPart::audio</code>). Plain text keeps its wire form. <code>Message::needs</code> and <code>Request::needs</code> give the <code>Modalities</code> (vision, audio) a model must take; <code>Message::text</code> gives the text alone.',
      '<code>remote::pool_model</code> (0.5.3): <code>PoolModel</code> is a model pool (such as <a href="https://github.com/WeirdBrains/ymir">Ymir</a> on the user’s own devices) as one <code>ModelBackend</code>, with mid-answer resume on another node, rerouting for images and audio, and an optional local fallback (<code>with_fallback</code>), reported as <code>ModelNotice</code>s (<code>AgentEvent::ModelNotice</code>, <code>DeltaSink::notice</code>) or <code>ModelError::PoolUnreachable</code>. <code>PoolWatch</code> follows the pool catalog as a <code>PoolStatus</code> for model pickers, knows which nodes answered (<code>CatalogNodes</code>) and can ask again at once (<code>retry</code>).',
      'Origin and license (0.5.4): <code>CatalogModel::origin</code> and <code>license</code>, set with <code>with_origin</code> and <code>with_license</code>; <code>ORIGIN_HUB</code>, <code>ORIGIN_UPLOAD</code> and <code>ORIGIN_TRAIN</code> name where a model came from. Both are left off the wire when unset.',
      'LoRA adapters (0.5.2): <code>Request::adapter_scale</code> and <code>with_adapter_scale</code> set how strongly an adapter applies for one request on nodes that scale per request (<a href="/crates/backends">weirdnet-backends</a> 0.4.1 on llama.cpp); <code>CatalogModel::base</code>, <code>with_base</code> and <code>is_adapter</code> mark a catalog entry as an adapter on a base model, so apps can show it as a variant. Both are left off the wire when unset.',
      'Routing by input (0.5.0): catalog entries say which inputs a model takes (<code>CatalogModel::inputs</code>, <code>with_inputs</code>; entries without it are text-only) and <code>Catalog::route</code> picks a model for a request with images or audio. The pool uses it, so such a request never reaches a text-only model: a named model that can’t read it, or a pool with no model that can, is a <code>BadRequest</code> before any node runs it.',
      'Answer cache per request (0.5.1): <code>Request::cache</code> is a <code>CacheMode</code>, <code>use</code>, <code>bypass</code> or <code>refresh</code>, set with <code>Request::with_cache</code>, so an eval can skip or refresh a node’s answer cache without raw mode. It is left off the wire when <code>use</code>. <code>Request::with_wait_for_model</code> sets <code>wait_for_model</code>.',
      'Continuing an answer (0.4.2): a request that carries an <code>assistant_prefix</code> continues that text (assistant prefill). <code>Request::continuing</code> makes one from a trailing assistant message; <code>Answer::prefix</code> and <code>Answer::continuation</code> separate the given text from the new.',
      '<code>pool</code> and <code>serve</code> features (0.4.0): <code>LinkedNodes</code>, <code>NetDialer</code> and <code>connect</code> on the app side; <code>Server</code> and <code>RosterAuth</code> on inference nodes, admitting only linked devices.',
      '<code>jobs</code> feature (0.5.6): <code>JobBoard</code>, <code>JobRecord</code>, <code>Claim</code>, <code>JobPolicy</code>, <code>CheckpointRef</code>: long jobs (such as training) that one device starts and another resumes from its last checkpoint, over the weirdnet-sync job log.',
      '<code>remote::task</code>: a whole agent task on another node, events streamed back, approvals answered on the asking device (0.2.0).',
      'Serde on everything that is stored or synced. The <code>testing</code> feature has a scripted model, approver and closure tools.',
    ],
    usedBy: ['Morph (Companions, in progress)'],
    dependsOn: ['net', 'sync'],
    notes: 'Version 0.5.11 is on <a href="https://crates.io/crates/weirdnet-agent/0.5.11">crates.io</a> (<a href="https://docs.rs/weirdnet-agent/0.5.11">docs.rs</a>). 0.5.11 is additive: speech out (<code>Purpose::Speak</code>, <code>SpeechProfile</code>, <code>Catalog::route_speak</code>, infer/2 <code>Speak</code>, <code>Pool::speak</code> and <code>speak_stream</code>, see the guide). Askers before 0.5.8 get catalogs without <code>speak</code> entries and 0.5.8 to 0.5.10 askers skip them; nodes before 0.5.11 can’t read a speech request and the pool moves on. 0.5.10 is additive: native video (a <code>video_url</code> content part, <code>Modalities::VIDEO</code>, catalog <code>inputs.video</code>, video limits and routing, see the guide). Peers before 0.5.10 can’t read a video part; routing keeps clips away from them. 0.5.9 is additive: sharing a pool with another Weirdnet identity (guest credentials, <code>GuestAuth</code>, <code>SharedPoolAuth</code>, <code>PoolShare</code> links, <code>connect_shared</code>, see the guide). Hosts that don’t opt in refuse guests as before. 0.5.8 is additive: speech to text (<code>Purpose::Transcribe</code>, <code>Catalog::route_transcribe</code>, infer/2 transcription, <code>Pool::transcribe</code>, see the guide). Catalogs leave transcription models out for askers before 0.5.8, which could not read them, and from 0.5.8 an entry a peer can’t read is skipped instead of failing the catalog. 0.5.7 is additive: per-model media and request limits in catalog entries (<code>MediaLimits</code>, <code>CatalogModel::limits</code>); entries without them look as before. 0.5.6 is additive: the opt-in <code>jobs</code> feature (synced jobs, see the guide), which needs weirdnet-sync 0.8.2; nothing changes without it. 0.5.5 changes no API: the <code>pool</code> and <code>serve</code> features accept weirdnet-sync 0.8 (<code>&gt;=0.5.2, &lt;0.9</code>). 0.5.4 is additive: <code>CatalogModel::origin</code> and <code>license</code>, <code>with_origin</code>, <code>with_license</code> and the <code>ORIGIN_HUB</code>, <code>ORIGIN_UPLOAD</code> and <code>ORIGIN_TRAIN</code> names, left off the wire when unset. 0.5.3 is additive: <code>remote::pool_model::PoolModel</code>, <code>PoolWatch</code> (with <code>retry</code>), <code>PoolStatus</code> and <code>CatalogNodes</code>, <code>ModelError::PoolUnreachable</code>, <code>ModelNotice</code>, <code>AgentEvent::ModelNotice</code> and <code>DeltaSink::notice</code>. 0.5.2 is additive: <code>Request::adapter_scale</code> and <code>with_adapter_scale</code>, and <code>CatalogModel::base</code>, <code>with_base</code> and <code>is_adapter</code> for LoRA adapters; neither is sent when unset, and older nodes ignore them. 0.5.1 is additive: <code>CacheMode</code> and <code>Request::cache</code>, <code>Request::with_cache</code> and <code>Request::with_wait_for_model</code>; older nodes ignore the new field. 0.5.0 adds image and audio content parts and routes them by model input; it is breaking: <code>Message::content</code> is a <code>Content</code>, not a <code>String</code>, so code that reads <code>m.content</code> as text uses <code>m.text()</code>, and <code>AgentSession::run</code> takes <code>impl Into&lt;Content&gt;</code> (see Moving to 0.5.0 below). Text-only messages keep their wire form, so 0.4 peers still read them; parts need 0.5 on both ends, and requests with parts skip infer/1 nodes. Frames may be up to 32 MiB (8 MiB before). 0.4.5 changes only package metadata and docs, with no API changes; 0.1.0 to 0.4.4 are yanked. 0.4.4 is additive: device roles in <code>RosterAuth::require_roles</code> (the user-signed grants in the weirdnet-sync 0.7 roster), <code>Authorize::admit</code> and <code>Admitted</code>, <code>TaskHost::session_for</code> and <code>task::serve_for</code>, and <code>Server::start_with</code> with <code>ServingExtras::tasks</code> to serve task/1; the <code>pool</code> and <code>serve</code> features accept weirdnet-sync 0.5.2 to 0.7. 0.4.3 stops offline linked devices from slowing every request (<code>LinkedNodes::with_retry_after</code>) and accepts weirdnet-sync 0.6. 0.4.2 is additive: the pool continues an answer from a caller’s <code>assistant_prefix</code> on nodes that can resume (no wire change; before, such a request failed with missing characters), a remote task’s approval card no longer arrives before the events sent ahead of it, and the <code>pool</code> and <code>serve</code> features need weirdnet-sync 0.5.2 (a device linked elsewhere reaches the others in one pass). 0.4.1 is additive: infer/2 raw prompts (<code>Input::Prompt</code>, <code>Request::prompt</code>; 0.4.0 servers close the stream and the pool moves on), early metadata (<code>Request::early_meta</code>, <code>ServerFrame::Meta</code>, <code>PoolEvent::Meta</code>, so a cache hit is known before the answer), embedding usage (<code>EmbedBackend::embed_counted</code>, <code>Embeddings::usage</code>), and a <code>Pool</code> that keeps error kinds: request errors (<code>BadRequest</code>, <code>Cancelled</code>) come back at once, and when every node fails the last node answer wins over a transport error. Weirdnet crates depend on it with caret requirements (<code>"0.4"</code>, or <code>"0.4.1"</code> where they use these APIs), so agent patch releases don’t force re-releases. 0.4.0 is breaking for hosts that serve inference (<code>InferHost</code> now authorizes a <code>Caller</code>) and for code that matches the crate’s enums, which are now <code>#[non_exhaustive]</code>; see Moving to 0.4.0 below. weirdnet-net and weirdnet-sync are only pulled in by the <code>pool</code> and <code>serve</code> features. The API may change while Morph’s Companions are built on it.',
  ),
  Crate(
    slug: 'model',
    version: '0.5.4',
    tagline: 'Local models: consent-gated Hugging Face GGUF downloads with resume and checksum, Hub search and split GGUFs, picking the largest file that fits, LoRA adapter files (GGUF and PEFT), importing and checking local model files with provenance, a Gemma 4 catalog with a speech-to-text model, per-model media limits measured when a model loads, hardware detection and model sizing, and streaming llama.cpp inference on a worker thread with cancel.',
    about: [
      'The shared local-model layer for <a href="https://weirdbrains.com">WeirdBrains</a> apps. It downloads a GGUF only after the user agrees to that exact model, loads it with llama.cpp and streams tokens from one worker thread that any thread can cancel. It was extracted from Mouser’s <code>mouser-llm</code> and has no app-specific types; switching Mouser over to it is a follow-up for Mouser’s owner <span class="tag wip">in progress</span>.',
      'llama.cpp and the agent backend are optional features, so a build that only needs downloads and the catalog has no native dependencies.',
    ],
    parts: [
      '<code>catalog</code>: Gemma 4 E2B (about 2.8 GB, for phones and small laptops) and E4B (about 4.6 GB, for desktop) as Q4_0 GGUFs from <code>ggml-org</code> on Hugging Face, with pinned size and SHA-256. <code>default_for(Device)</code> picks one.',
      '<code>ModelStore</code>, <code>download</code>: a cache directory (<code>WEIRDNET_MODELS_DIR</code> overrides it), a <code>Consent</code> that must name the model, <code>Progress</code> callbacks, <code>.part</code> resume and a checksum check before the file is kept. Nothing downloads without consent.',
      '<code>hf</code>: lists a repo’s GGUF files and sizes for a model picker. <code>hf::Hub</code> (0.5.1) searches the Hub (<code>Search</code>, <code>SearchHit</code>), groups a repo’s files into models with split GGUFs joined and the quantization read from the name (<code>RepoModel</code>, <code>group_files</code>, <code>quant_of</code>), and reads a file’s GGUF header with a <code>Range</code> request (<code>gguf_info</code>).',
      '<code>fit</code> (0.5.1): <code>choose</code> and <code>rank</code> pick the largest file whose weights and KV cache fit a <code>hw::Budget</code> for the context and slots asked for (<code>FitOptions</code>, <code>Fit</code>); <code>gguf::read_info</code> gives the header fields that size the KV cache, with an estimate when the header isn’t read.',
      '<code>HfToken</code> (0.5.1): a Hugging Face token read on the downloading machine (<code>HF_TOKEN</code>, <code>HUGGING_FACE_HUB_TOKEN</code> or a token file). <code>ModelStore::from_env</code> sends it to the public Hub only; <code>ModelStore::with_token</code> sets one for any Hub.',
      '<code>download_parts</code>, <code>ModelStore::list</code>, <code>ModelStore::remove_local</code> (0.5.1): every part of a split model under one consent, the models on disk with split parts grouped, and removal.',
      '<code>gguf::read_header</code>, adapters (0.5.2): <code>GgufKind</code> says whether a GGUF is a model or a LoRA adapter (<code>Adapter { adapter_type, alpha }</code>); <code>Hub::adapters</code> lists a repo’s adapter files (<code>RepoAdapter</code>, <code>AdapterFormat::{GgufLora, Peft}</code>), <code>Hub::gguf_header</code> reads one over a <code>Range</code> request and <code>Search::with_adapters</code> finds them; <code>download_adapter</code> with <code>Consent::given_adapter</code> saves one under <code>adapters/&lt;id&gt;/</code>, and <code>StoredAdapter</code>, <code>ModelStore::adapters</code> and <code>remove_adapter</code> list and delete them. Adapters stay out of <code>Hub::models</code>, <code>fit</code> and <code>ModelStore::list</code>.',
      '<code>artifact</code>, <code>ModelStore::import</code> (0.5.3): <code>artifact::inspect</code> reads and hashes local files (GGUF models, split models, LoRA adapters and projectors; safetensors and MLX model directories; PEFT adapters) and refuses pickles, code and symlinks, returning an <code>Artifact</code>; <code>ModelStore::import</code> (<code>import_replacing</code>, <code>import_with</code>, <code>import_files</code>) places it atomically with a <code>Provenance</code> (<code>provenance.json</code>: base, dataset, trainer, app). <code>GgufKind::Projector</code>, <code>projectors</code> and <code>remove_projector</code> handle vision projectors; <code>free_bytes</code>, <code>disk_space</code> and <code>bytes_by_origin</code> report space.',
      '<code>prompt</code>: chat turns rendered through the model’s own chat template, and a streaming parser that turns <code>&lt;tool_call&gt;</code> tags into tool calls.',
      '<code>Worker</code>, <code>Engine</code>: the engine lives on one thread; <code>generate</code> returns a <code>Generation</code> that streams <code>Chunk</code>s and cancels from any thread. Tests use a mock engine.',
      '<code>llama</code> feature: <code>LlamaEngine</code> on llama.cpp (CPU; needs cmake and a C++ compiler). <code>vulkan</code> and <code>metal</code> add GPU offload.',
      '<code>hw</code> (0.4.0): <code>detect()</code> finds GPUs (NVIDIA, AMD, Apple silicon), CPU threads and memory; <code>budget()</code> is the memory models may use; <code>catalog()</code> is a tiered list of chat and embedding models with footprints; <code>plan()</code> picks a main model, a stand-in and an embedding model that fit.',
      'Speech to text (0.5.4): <code>Purpose::Transcribe</code>, the <code>transcribe</code> role (<code>Purpose::as_str</code>, <code>parse</code>), and a catalog entry for <a href="https://huggingface.co/ggml-org/Voxtral-Mini-3B-2507-GGUF">Voxtral Mini 3B</a> (<code>hw::VOXTRAL_MINI_3B</code>, Q4_K_M) with its pinned audio projector (<code>CatalogEntry::projector</code>, counted in <code>footprint</code>). <code>hw::transcriber</code> returns it when it fits and <code>hw::by_purpose</code> lists entries by role; <code>plan()</code> never picks it.',
      '<code>limits</code> (0.5.4): <code>ModelLimits</code> holds the context a model runs with, images per request and their token cost, audio length and cost (per minute and per 30-second piece), video length and bytes, and the largest request, each absent when unknown. <code>limits::measure</code> reads a model and its projector when it loads (<code>from_projector</code>: Gemma 3, Qwen-VL, Voxtral, Ultravox and Qwen2 audio projectors), <code>ModelStore::record_limits</code> keeps the <code>LimitsRecord</code> next to the files and <code>StoredModel::limits</code> reads it back. With <code>agent</code> it converts to and from <a href="/crates/agent">weirdnet-agent</a>’s <code>MediaLimits</code>.',
      '<code>agent</code> feature: <code>LocalModel</code> implements <code>weirdnet_agent::ModelBackend</code> (weirdnet-agent <code>"0.5"</code> since 0.5.0; <code>"0.4"</code> in 0.4.2 and 0.4.3; <code>=0.4.0</code> in 0.4.0 and 0.4.1; <code>=0.3.0</code> in 0.3.0), streaming text to the agent loop and returning parsed tool calls. It is text only: it reads text parts and refuses messages with images or audio (<code>ModelError::Unavailable</code>).',
      '<code>cpu-dispatch</code> feature (0.2.0): llama.cpp built for every CPU level and chosen at run time, so a release binary runs local models on any CPU; the app ships the llama.cpp shared libraries (see the guide).',
      '<code>cpu</code> (0.2.0): <code>cpu::check()</code>, <code>required()</code> and <code>missing()</code> say whether this CPU can run the compiled-in llama.cpp. <code>LlamaEngine::load</code> checks first and returns <code>Error::UnsupportedCpu</code> instead of crashing with an illegal instruction.',
      '<code>examples/model.rs</code> (0.2.0): a small CLI with the <code>llama</code> feature. <code>fetch [id]</code> downloads a model with progress (running the command is the consent) and checks its size and SHA-256; <code>chat [id] "question"</code> loads it and streams the answer with load, first-chunk and total timings. The <code>cpu</code> command prints the CPU check. Run from a clone: <code>cargo run --release --example model --features llama -- chat gemma-4-e4b "Why is the sky blue?"</code>.',
    ],
    usedBy: ['Morph (Companions, in progress)'],
    dependsOn: ['agent'],
    example: r'''# Cargo.toml
weirdnet-model = { version = "0.5", features = ["llama", "agent"] }

// main.rs
use std::sync::Arc;
use weirdnet_model::{agent::LocalModel, catalog, llama::{LlamaEngine, LlamaOptions}, ModelStore, Worker};

let spec = catalog::default_for(catalog::Device::Desktop);
let store = ModelStore::from_env();
// After the user agrees: weirdnet_model::download(&store, &spec, &consent, &mut on_progress)?; // on_progress returns false to cancel
let worker = Arc::new(Worker::spawn(LlamaEngine::loader(store.path(&spec), LlamaOptions::default())));
let model = LocalModel::new(spec.id.clone(), worker); // a weirdnet_agent::ModelBackend''',
    notes: 'Version 0.5.4 is on <a href="https://crates.io/crates/weirdnet-model">crates.io</a> (<a href="https://docs.rs/weirdnet-model/0.5.4">docs.rs</a>). 0.5.4 is additive: <code>Purpose::Transcribe</code> and the Voxtral Mini 3B speech-to-text entry (<code>hw::VOXTRAL_MINI_3B</code>, <code>CatalogEntry::projector</code>, <code>transcribes</code>, <code>hw::transcriber</code>, <code>hw::by_purpose</code>); the <code>limits</code> module (<code>ModelLimits</code>, <code>from_projector</code>, <code>measure</code>, <code>LimitsRecord</code>, <code>LimitSource</code>); <code>ModelStore::record_limits</code>, <code>limits</code>, <code>clear_limits</code>, <code>limits_path</code> and <code>StoredModel::limits</code>; <code>gguf::ProjectorInfo</code> on <code>GgufHeader::projector</code>; <code>LlamaEngine::limits</code>. <code>CatalogEntry::footprint</code> now counts an entry’s projector (no existing entry has one), and the <code>agent</code> feature needs weirdnet-agent 0.5.7. 0.5.3 is additive: <code>artifact</code> (<code>inspect</code>, <code>Artifact</code>, <code>ArtifactKind</code>, <code>ArtifactFormat</code>, <code>ArtifactFile</code>, <code>revision</code>, <code>read_safetensors</code>, <code>early_header</code>, <code>inspect_staged</code>), <code>Provenance</code> (<code>weirdnet-provenance/1</code>), <code>ModelStore::import</code>, <code>import_replacing</code>, <code>import_with</code> and <code>import_files</code> with <code>safetensors/&lt;id&gt;/</code>, <code>mlx/&lt;id&gt;/</code> and <code>projectors/&lt;id&gt;/</code> layouts, <code>dir_models</code>, <code>projectors</code>, <code>remove_projector</code>, <code>free_bytes</code>, <code>disk_space</code>, <code>bytes_by_origin</code>, <code>StoredModel::provenance</code> and <code>layout</code>, <code>StoredAdapter::provenance</code> and <code>GgufKind::Projector</code>; <code>gguf::read_header</code> now reports projector GGUFs as projectors instead of models. 0.5.2 is additive: LoRA adapter files, from the GGUF header (<code>gguf::read_header</code>, <code>GgufHeader</code>, <code>GgufKind</code>, <code>gguf::hub_id</code>) to the Hub (<code>Hub::adapters</code>, <code>Hub::gguf_header</code>, <code>hf::adapter_hint</code>, <code>Search::with_adapters</code>, <code>SearchHit::adapter</code>), downloads (<code>download_adapter</code>, <code>Consent::given_adapter</code>, with an <code>adapter.json</code> beside the files) and the store (<code>StoredAdapter</code>, <code>ModelStore::adapters</code>, <code>remove_adapter</code>, <code>adapter_dir</code>); model listings, fits and searches leave adapters out. 0.5.1 is additive: Hub search, split GGUFs, <code>fit</code>, <code>HfToken</code>, <code>download_parts</code>, and listing and removing models on disk; <code>download</code> now creates the directory of a file in a repo subdirectory and refuses names that leave the store. 0.5.0 moves the <code>agent</code> feature to weirdnet-agent <code>"0.5"</code> (content parts): breaking for <code>agent</code> users only, who move to agent 0.5 with it; <code>LocalModel</code> reads text parts and refuses images and audio. Nothing changes without the <code>agent</code> feature. 0.4.3 changes only package metadata and docs, with no API changes; 0.1.0 to 0.4.2 are yanked. 0.4.2 loosens the <code>agent</code> feature’s weirdnet-agent requirement from <code>=0.4.0</code> to <code>"0.4"</code>, so it works with agent 0.4.1 and later 0.4 patches; nothing else changes. 0.4.1 fixes the note <code>hw::plan()</code> gives when no catalog chat model fits: it no longer names another application’s command and says to add a smaller GGUF model. 0.4.0 adds the <code>hw</code> module and makes the <code>agent</code> feature depend on weirdnet-agent <code>=0.4.0</code> (it was <code>=0.3.0</code>), so apps on agent 0.4 can use <code>LocalModel</code>. This is breaking for <code>agent</code> users only; <code>ModelBackend</code> is unchanged and nothing changes without the <code>agent</code> feature. Adding variants to <code>Error</code> (0.2.0) is a breaking change. The API may change while Morph’s Companions are built on it. Real-model tests are ignored by default; CI builds llama.cpp on CPU only. Measured by the Morph team: Gemma 4 E4B on CPU (16 cores, warm load) takes about 1.6 s to load and give the first token, then runs at about 9 tokens/s with about 7 GiB peak RAM.',
  ),
  Crate(
    slug: 'backends',
    version: '0.4.9',
    tagline: 'The model-node wrapper: llama.cpp, vLLM and MLX-LM adapters, LoRA adapters on a base model with live changes and per-request scale, node reservations, uploads and node-to-node copies of models under a write policy, per-model capabilities with limits measured at load, speech-to-text models served over infer/2, a supervisor with swap groups, idle unload and crash backoff, raw infer/2 serving, /weirdnet-backends/node/1 with signed capability records, and owner-only model downloads over /weirdnet-backends/models/1.',
    about: [
      'A model node runs models and takes requests, like a llama.cpp, vLLM or MLX-LM server; it can even be one, a stock server it only wraps. weirdnet-backends starts and stops the engines and serves them to inference nodes. It decides nothing beyond the node: what to load, and where, is the caller’s decision. It has no app-specific types.',
      'Requests and errors are <a href="/crates/agent">weirdnet-agent</a> 0.5 infer/2 types, so a model node serves raw <code>/weirdnet-agent/infer/2</code> through <code>ModelHost</code>, an <code>InferHost</code>. The <code>node</code> feature adds <code>/weirdnet-backends/node/1</code> over <a href="/crates/net">weirdnet-net</a> 0.8: inference nodes subscribe to signed capability records and send <code>Load</code>, <code>Unload</code>, <code>Drain</code>, <code>GroupUp</code>/<code>GroupDown</code> and <code>Health</code>.',
    ],
    parts: [
      'Measured limits (0.4.9): when a model loads, the supervisor reads what its GGUF and projector headers say images and audio cost (<a href="/crates/model">weirdnet-model</a> 0.5.4 <code>limits::measure</code>; llama.cpp <code>--image-max-tokens</code> caps a size-dependent projector’s cost) and asks the engine for its context per sequence (llama-server <code>/props</code>, vLLM <code>/v1/models</code>). The operator’s limits win field by field and unknown figures stay absent. <code>Supervisor::measured_limits</code>, <code>Supervisor::set_limits_store</code> (records kept next to the model files and read back after a restart) and <code>ModelStatus::context_tokens</code>, which <code>apply_to</code> prefers over the configured context.',
      'Transcription (0.4.9): <code>ModelLaunch::with_transcribe</code> gives a model the transcription role; <code>Capabilities::transcribe</code> (llama.cpp with an audio projector, such as Voxtral, or vLLM, such as Whisper) and <code>ModelLaunch::purpose</code>, <code>ModelStatus::purpose</code> and <code>ModelStatus::catalog_model</code> publish it as catalog/1 <code>Purpose::Transcribe</code>. <code>ModelHost</code> serves infer/2 <code>Transcribe</code> (<code>InferHost::open_transcribe</code>) through <code>Supervisor::transcribe</code>: a chat request with a base64 <code>input_audio</code> part on llama.cpp, <code>/v1/audio/transcriptions</code> (with timed segments when asked) on vLLM. Needs <a href="/crates/agent">weirdnet-agent</a> 0.5.8.',
      'Media limits (0.4.8): <code>Capabilities::limits</code>, a <a href="/crates/agent">weirdnet-agent</a> 0.5.7 <code>MediaLimits</code>, set by the operator with <code>ModelLaunch::with_limits</code> and carried in every <code>ModelStatus</code> and capability record; <code>intersect</code> keeps the stricter limits, and <code>Capabilities::apply_to</code> and <code>ModelStatus::apply_to</code> fill a catalog entry’s inputs, limits and context window.',
      '<code>EngineConfig</code>, <code>ModelLaunch</code>: how <code>llama-server</code>, <code>vllm serve</code> and MLX-LM’s <code>mlx_lm.server</code> are launched: loopback only, a random port, a per-process API key in the environment (never the command line), context, slots and GPU layers. <code>Wrap</code> attaches to a stock OpenAI-compatible server on loopback without owning it.',
      '<code>mlx</code> (0.1.3): <code>EngineKind::Mlx</code> runs <code>mlx_lm.server</code> on macOS on Apple silicon behind a proxy that checks the node’s API key, rewrites <code>model</code> to <code>default_model</code>, refuses image, audio and embedding requests, and reports ready only after a one-token completion; <code>mlx::install</code> puts a pinned <code>mlx-lm</code> (0.32.2) into a venv with <code>uv</code> or <code>python3</code>.',
      '<code>Capabilities</code> (0.1.3): what each model takes (chat, embeddings, images, audio), from <code>ModelLaunch::capabilities</code> and in every <code>ModelStatus</code> and capability record, so routing keeps image, audio and embedding requests off models that can’t serve them.',
      'Images and audio (0.2.0): weirdnet-agent 0.5 content parts (<code>image_url</code> with a <code>data:</code> URL, <code>input_audio</code>) reach llama.cpp unchanged, in the OpenAI shape. llama.cpp models with a multimodal projector (<code>--mmproj</code>) take images and audio; vLLM and MLX-LM models are text only. <code>ModelHost</code> refuses parts a model’s <code>Capabilities</code> lack (<code>Unsupported</code>, so a pool tries another node) and remote image URLs (<code>BadRequest</code>); <code>Capabilities::inputs</code> gives the <code>Modalities</code> for the inference node’s catalog entry.',
      '<code>Supervisor</code>: load with a readiness probe, drain and unload; <b>swap groups</b> (loading one model of a group unloads the others); <b>idle unload</b> (<code>reap_idle</code>, <code>spawn_reaper</code>); crash restarts with exponential backoff and crash-loop detection (an explicit forced load clears it); <code>SupervisorEvent</code>s and per-model logs; chat, completion and embedding forwarding. <code>add_model</code> and <code>remove_model</code> (0.3.0) serve a new model, or stop serving one, without a restart (<code>SupervisorEvent::Added</code>, <code>Removed</code>); <code>launches</code> lists the models.',
      '<code>models</code> (feature <code>node</code>, 0.3.0): <code>/weirdnet-backends/models/1</code> for the node’s owner only (<code>ModelsService</code> takes an <code>Authorize</code> such as <code>RosterAuth</code>): Hugging Face Hub search, a repo’s models measured against the node’s memory budget, pull with progress (split GGUFs too, the largest that fits by default) and serving it without a restart, list and remove. <code>ModelsServer</code> and <code>ModelsClient</code>. The node’s Hugging Face token stays on the node.',
      '<code>LoraAdapter</code> (0.4.0): LoRA adapters served on a base model (<code>ModelLaunch::with_adapters</code>, <code>served_ids</code>, <code>check_adapters</code>, which reads llama.cpp adapters’ GGUF headers with <a href="/crates/model">weirdnet-model</a>). A request names the base or an adapter id; <code>openai::Target</code> (<code>Base</code> or <code>Adapter</code>) picks the engine body. llama.cpp gets one <code>--lora</code> per adapter with <code>--lora-init-without-apply</code> and a <code>lora</code> list per request; vLLM gets <code>--enable-lora</code>, <code>--lora-modules</code> and <code>--max-loras</code>. <code>Supervisor::add_adapter</code> and <code>remove_adapter</code> return an <code>AdapterChange</code> (<code>Live</code> or <code>NextLoad</code>), and <code>ModelStatus::base</code> gives each adapter its own row.',
      'Live adapters and scale (0.4.1): <code>add_adapter_live</code> and <code>remove_adapter_live</code> load and unload adapters on a running vLLM engine (<code>ModelLaunch::lora_slots</code>); <code>set_adapter_scale</code> changes an adapter’s strength on llama.cpp without a restart, and <code>Request::adapter_scale</code> (<a href="/crates/agent">weirdnet-agent</a> 0.5.2) sets it for one request, up to <code>MAX_ADAPTER_SCALE</code>. models/1 adds <code>ServeAdapter</code>, <code>UnserveAdapter</code> and <code>AdapterScale</code>.',
      'Reservations (0.4.3): <code>Supervisor::reserve</code> stops the node’s engines and holds its accelerators for one holder (<code>Reservation</code>, <code>reservation_changes</code>), refusing every load until <code>release</code>; node/1 adds <code>Command::Reserve</code> and <code>Release</code> (<code>NodeClient::reserve</code>, <code>release</code>), and capability records and health carry <code>reserved</code>.',
      'Uploads (0.4.4): <code>ModelsCommand::Upload</code> sends local files to a node in 48 KiB chunks (<code>Upload</code>, <code>UploadFrame</code>, <code>CHUNK</code>, <code>ModelsClient::upload</code>). The node checks names, size, free space, engine and base before the first byte, each header as it arrives and every SHA-256 at the end, then places the files with <a href="/crates/model">weirdnet-model</a> 0.5.3 <code>ModelStore::import</code> and can serve them: GGUF, safetensors and MLX models, adapters (live on their base) and vision projectors. A closed upload resumes from its staged parts; <code>AbandonUpload</code> drops them.',
      'Copies between nodes (0.4.4): <code>ModelsCommand::Fetch</code>, <code>Pull::from_peer</code> (<code>PullSource::Peer</code>, <code>ModelsService::with_peer_dialer</code>) and <code>ModelsClient::replicate</code>, which has several nodes pull an upload from the node it landed on, all at once.',
      '<code>WritePolicy</code> (0.4.4): a separate write <code>Authorize</code>, an uploads switch (<code>with_uploads</code>, 0.4.7), <code>max_upload</code>, <code>quota</code> and <code>KeepFree</code> (10 percent or 20 GiB by default, the larger) for uploads, removes and peer copies. <code>ModelsCommand::Disk</code> returns a <code>DiskReport</code>; <code>List</code> shows provenance, safetensors and MLX models and projectors; refusals carry stable reasons (<code>refusal</code>, <code>refusal_reason</code>).',
      'Placement hooks (0.4.5): <code>ModelsService::on_placed</code> (<code>OnPlaced</code>) runs after each upload, peer copy or Hub pull is placed, with a <code>Placed</code> (the <code>StoredEntry</code>, the <code>Pulled</code> answer, <code>PlacedVia</code> and <code>serve_error</code>); <code>with_node_info</code> keeps the capability record current from it. <code>ModelEntry::origin</code> and <code>license</code> in capability records, set with <code>NodeService::set_model_origin</code> or from provenance (<code>Placed::origin_and_license</code>).',
      'Projectors (0.4.4): <code>ModelLaunch::with_mmproj</code> starts llama.cpp with <code>--mmproj</code> and reports image input; <code>Supervisor::set_projector_live</code> sets or clears it, applied at the next load.',
      '<code>ChunkDecoder</code>, <code>ToolCalls</code>: OpenAI server-sent events decoded into <code>Chunk</code>s: text, reasoning (<code>reasoning_content</code> or <code>reasoning</code>), tool-call fragments joined into calls, finish reason and usage with cached and reasoning tokens.',
      '<code>openai</code>: engine request bodies from infer/2 requests: messages, sampling, seed, response format, tools, and assistant-prefix continuation (vLLM’s <code>continue_final_message</code>).',
      '<code>ModelHost</code>: an <code>InferHost</code> serving raw infer/2, embeddings and transcription (0.4.9) from the supervisor’s models. Cancel aborts the engine request; prefixes resume; a model that is not loaded is refused unless the request waits for it; draining refuses new requests; prefill and decode speed and time to first token are measured.',
      '<code>node</code> feature: <code>NodeService</code>, <code>NodeServer</code> (node/1 and raw inference on a <code>weirdnet-net</code> node, announced as <code>weirdnet-backends-node</code>), <code>NodeServerOptions</code>, <code>RAW_INFER_PROTOCOL</code> and <code>RawInferDialer</code> (0.1.1), <code>NodeClient</code>, <code>Subscription</code>, <code>Verifier</code>, and <code>GroupWorkers</code> for the application’s cross-machine group workers.',
    ],
    dependsOn: ['agent', 'model', 'net', 'sync'],
    example: r'''# Cargo.toml
weirdnet-backends = { version = "0.4", features = ["node"] }

// main.rs
use std::sync::Arc;
use weirdnet_backends::{EngineConfig, EngineKind, LoraAdapter, ModelHost, ModelLaunch, Supervisor, SupervisorOptions};
use weirdnet_backends::node::{NodeServer, NodeService};

let chat = ModelLaunch::new("qwen3-8b", EngineKind::Llamacpp, "/models/qwen3-8b-q4_k_m.gguf");
let sup = Supervisor::new(vec![EngineConfig::llamacpp("llama-server")], vec![chat], SupervisorOptions::default());
let _reaper = sup.spawn_reaper(std::time::Duration::from_secs(30));
// A LoRA adapter on the base (0.4.0): requests for "qwen3-8b-support" use it.
sup.add_adapter("qwen3-8b", LoraAdapter::new("qwen3-8b-support", "/models/support-lora.gguf"))?;
let host = Arc::new(ModelHost::new(sup, auth.clone())); // auth: weirdnet_agent::serve::RosterAuth
let service = Arc::new(NodeService::new(host, node_keypair, Some(node_cert), auth).with_hardware(hw, budget));
let _server = NodeServer::start(&node, service)?; // node/1 + raw inference on /weirdnet-backends/infer/1 and infer/2

// On the inference node: dial model nodes on the new id, falling back to infer/2 for 0.1.0 nodes.
let dialer = Arc::new(weirdnet_backends::RawInferDialer::new(net_dialer));''',
    notes: 'Version 0.4.9 is on <a href="https://crates.io/crates/weirdnet-backends/0.4.9">crates.io</a> (<a href="https://docs.rs/weirdnet-backends/0.4.9">docs.rs</a>). 0.4.9 is additive and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.8 and <a href="/crates/model">weirdnet-model</a> 0.5.4: limits measured at load, the transcription role with <code>Purpose::Transcribe</code>, and infer/2 transcription through <code>ModelHost</code>; records from older nodes read as before (no transcription, no measured context). 0.4.8 is additive and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.7: per-model media and request limits in <code>Capabilities</code>, <code>ModelLaunch</code> and <code>ModelStatus</code>; records without them read as before. 0.4.7 is additive: <code>WritePolicy::uploads</code> and <code>with_uploads(false)</code> refuse uploads alone with <code>not-allowed</code> while pulls, peer copies and removals keep working (uploads stay on by default), and <code>StoredEntry::from_model</code>, <code>from_adapter</code>, <code>from_projector</code> (and <code>From</code>), <code>with_served</code>, <code>with_base</code> and <code>StoredEntry::list(&amp;ModelStore)</code> build and list entries without serde or a running service. 0.4.6 changes no API: the <code>node</code> feature accepts weirdnet-sync 0.8 (<code>&gt;=0.5, &lt;0.9</code>) and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.5, which accepts it too. 0.4.5 is additive: placement hooks (<code>ModelsService::on_placed</code>, <code>OnPlaced</code>, <code>Placed</code>, <code>PlacedVia</code>, <code>ModelsService::with_node_info</code>) and a model’s origin and license in capability records (<code>ModelEntry::origin</code> and <code>license</code>, <code>NodeService::set_model_origin</code>, <code>Placed::origin_and_license</code>), left out of the record when unset. 0.4.4 is additive and needs <a href="/crates/model">weirdnet-model</a> 0.5.3: models/1 uploads (<code>ModelsCommand::Upload</code>, <code>Upload</code>, <code>UploadFrame</code>, 48 KiB <code>CHUNK</code>s, <code>UploadReady</code>, <code>Uploaded</code>, <code>ModelsClient::upload</code>, resumable from staged parts, <code>AbandonUpload</code>), copies between nodes (<code>ModelsCommand::Fetch</code>, <code>PullSource::Peer</code>, <code>Pull::from_peer</code>, <code>ModelsService::with_peer_dialer</code>, <code>ModelsClient::replicate</code>), <code>WritePolicy</code> (write <code>Authorize</code>, <code>max_upload</code>, <code>quota</code>, <code>KeepFree</code>), <code>ModelsCommand::Disk</code> and <code>DiskReport</code>, stable refusal reasons (<code>refusal</code>, <code>refusal_reason</code>), <code>StoredEntry::projector</code> and <code>provenance()</code>, and projectors (<code>ModelLaunch::with_mmproj</code>, <code>Supervisor::set_projector_live</code>). <code>Remove</code> now follows the <code>WritePolicy</code>, a served model reloads when its projector changes, and nodes before 0.4.4 refuse the new commands. 0.4.3 is additive: node reservations (<code>Supervisor::reserve</code>, <code>release</code>, <code>Reservation</code>, <code>reservation_changes</code>; node/1 <code>Command::Reserve</code> and <code>Release</code>, <code>NodeClient::reserve</code> and <code>release</code>; <code>Capability::reserved</code>, <code>Health::reserved</code>). 0.4.2 fixes a port race: an engine is ready only when <code>/v1/models</code> answers with the launch’s key and model id, and a launch that lost its port to another process tries a new port up to 3 times without counting as a crash. 0.4.1 is additive: live adapter changes on vLLM (<code>add_adapter_live</code>, <code>remove_adapter_live</code>, <code>ModelLaunch::lora_slots</code>), adapter scale on llama.cpp (<code>set_adapter_scale</code>, <code>Request::adapter_scale</code> with <a href="/crates/agent">weirdnet-agent</a> 0.5.2, <code>complete_scaled</code>, <code>MAX_ADAPTER_SCALE</code>) and models/1 <code>ServeAdapter</code>, <code>UnserveAdapter</code> and <code>AdapterScale</code>. 0.4.0 adds LoRA adapters (<code>LoraAdapter</code>, <code>ModelLaunch::with_adapters</code>, <code>openai::Target</code>, <code>Supervisor::add_adapter</code> and <code>remove_adapter</code>, <code>AdapterChange</code>, <code>ModelStatus::base</code>, <code>Pull::adapter_for</code>, <code>RepoFits::adapters</code>); it is breaking: <code>ModelLaunch</code> is <code>#[non_exhaustive]</code> (build it with <code>ModelLaunch::new</code> and the <code>with_</code> methods), <code>StoredEntry::model</code> is an <code>Option</code> beside new <code>adapter</code> and <code>base</code> fields, <code>StoredEntry</code> and <code>RepoFits</code> are no longer <code>Eq</code>, and <a href="/crates/model">weirdnet-model</a> 0.5.2 is always a dependency. 0.3.0 adds <code>/weirdnet-backends/models/1</code> and <code>Supervisor::add_model</code>; it is breaking for <code>node</code> users because the feature now needs <a href="/crates/model">weirdnet-model</a> 0.5.1 and no longer takes 0.4 (<code>hw::Hardware</code> and <code>hw::Budget</code> in capability records are its types), so move to weirdnet-model 0.5.1 with it. The node/1 and raw inference protocols are unchanged. 0.2.0 needs weirdnet-agent 0.5 (content parts), which is breaking because its public API uses the agent types: move to agent 0.5 with it. Image and audio parts reach llama.cpp unchanged, and <code>ModelHost</code> refuses them for models without those capabilities; <code>Capabilities::inputs</code> and <code>Capabilities::lacking</code> are new. 0.1.3 is additive: an MLX-LM engine for Apple silicon (<code>EngineKind::Mlx</code>, <code>EngineConfig::mlx</code>, the <code>mlx</code> module), text only and without embeddings, and per-model <code>Capabilities</code> (chat, embeddings, vision, audio) in capability records; <code>Supervisor::embed</code> refuses MLX models. 0.1.2 is additive: capability records carry the node’s private links (<code>Capability::links</code>, <code>NodeService::set_links</code>, <code>link::local_links</code>; never public or CGNAT addresses), <code>Verifier::with_roster</code> refuses records from revoked or unknown nodes, and it needs weirdnet-agent 0.4.4 and accepts weirdnet-sync 0.5 to 0.7. 0.1.1 serves raw inference on its own protocol id, <code>/weirdnet-backends/infer/1</code> (<code>RAW_INFER_PROTOCOL</code>, the infer/2 framing), so one node can be an inference node and a model node; infer/2 is still served by default for 0.1.0 inference nodes (<code>NodeServerOptions::with_legacy_infer2(false)</code> turns it off), and <code>RawInferDialer</code> tries the new id and falls back to infer/2. It also serves raw prompts and reports embedding tokens (agent 0.4.1) and depends on weirdnet-agent <code>"0.4.1"</code> and weirdnet-model <code>"0.4"</code>. Extracted from Ymir’s <code>ymir-backends</code>. The supervisor runs on Unix and Windows; graceful stop, process groups and dying with the parent are Unix-only (see the platform table below), vLLM is Linux-only and MLX-LM runs on macOS on Apple silicon only. Ray and <code>rpc-server</code> group workers are not included: <code>GroupUp</code> goes to the application’s <code>GroupWorkers</code>. The API may change while Ymir moves onto it.',
    origin: 'Ymir',
  ),
  Crate(
    slug: 'openai',
    version: '0.2.5',
    tagline: 'A loopback-only OpenAI-compatible bridge over a weirdnet-agent inference pool (chat, embeddings, speech and transcription), with a token, a Host check and no CORS.',
    about: [
      'Local tools that speak the OpenAI API (editors, notebooks, <code>curl</code>) reach the user’s inference nodes through it: chat completions, streaming or not, the model list, embeddings, speech and transcription, all through a <a href="/crates/agent">weirdnet-agent</a> 0.5 <code>Pool</code>, so failover, resume and stand-ins come with it.',
      'It binds <code>127.0.0.1</code> only, checks the <code>Host</code> header against its own address, requires a bearer token and sends no CORS headers, so web pages can’t call it.',
    ],
    parts: [
      'Speech (0.2.5): <code>POST /v1/audio/speech</code> over <a href="/crates/agent">weirdnet-agent</a> 0.5.11 <code>Pool::speak</code> and <code>Pool::speak_stream</code>. OpenAI’s <code>input</code>, <code>model</code>, <code>voice</code> (a name or <code>{"id": ...}</code>), <code>instructions</code>, <code>response_format</code> (<code>wav</code>, <code>pcm</code>, <code>mp3</code>, <code>opus</code>, <code>flac</code>; absent: the model’s first format), <code>speed</code> and <code>stream_format: "audio"</code> (bytes as they come; <code>sse</code> is refused), plus <code>weirdnet</code> extensions: <code>language</code>, <code>seed</code>, <code>sample_rate</code>, <code>design</code>, <code>ref_audio</code> (a <code>data:</code> URL only) with <code>ref_text</code> and <code>consent</code>, <code>script</code> and <code>raw</code>. Each request is checked against the catalog first, so a voice, format or feature the model lacks is a 400 that names what it has: OpenAI voices such as <code>alloy</code> are never mapped to another voice. The answer’s <code>Content-Type</code> is the real format (<code>audio/pcm;rate=24000</code> for raw PCM), with <code>x-audio-sample-rate</code>, <code>x-weirdnet-audio-channels</code> and <code>x-weirdnet-ignored</code>; a stream that fails after audio has left ends early instead of splicing another take. <code>request::speech</code> parses the body.',
      'Transcription (0.2.5): <code>POST /v1/audio/transcriptions</code> (multipart) over <code>Pool::transcribe</code>: <code>file</code>, <code>model</code>, <code>language</code>, <code>prompt</code>, <code>response_format</code> (<code>json</code>, <code>verbose_json</code>, <code>text</code>, <code>srt</code>, <code>vtt</code>) and <code>timestamp_granularities[]=segment</code>. Subtitles come from the transcriber’s timed segments; one that times nothing gets a 501, not invented cues. Both audio endpoints share the request size limit and its 413, and neither is cached.',
      'Video (0.2.5): chat messages may carry <code>video_url</code> parts with a <code>data:video/...</code> URL (weirdnet-agent 0.5.10 <code>ContentPart::VideoUrl</code>); the pool sends them only to a model that reads video. Remote and non-video URLs are a 400; nothing is fetched.',
      'Request size (0.2.4): <code>Bridge::with_max_request_bytes</code> sets the largest body (default <code>DEFAULT_MAX_REQUEST_BYTES</code>, 32 MiB); a larger one gets a 413 <code>request_too_large</code> that names the limit, also in <code>x-weirdnet-max-request-bytes</code>. <code>/v1/models</code> reports <code>weirdnet.max_request_bytes</code> and the model’s <code>weirdnet.limits</code>.',
      '<code>POST /v1/chat/completions</code>: SSE streaming with <code>data: [DONE]</code>, or one JSON answer; reasoning as <code>reasoning_content</code>, tool calls, usage with cached and reasoning tokens. Dropping the response cancels the pool request. <code>continue_final_message: true</code> (0.1.2, vLLM’s parameter) continues the last assistant message and answers with only the new text.',
      '<code>POST /v1/completions</code> (0.1.1): a raw prompt, whole or streamed as <code>text_completion</code> chunks; <code>n</code>/<code>best_of</code> above 1, <code>echo</code>, <code>suffix</code> and <code>logprobs</code> are refused with 400.',
      'Images and audio (0.2.0): chat messages may carry <code>image_url</code> parts with a <code>data:image/...</code> URL and <code>input_audio</code> parts; they go to the pool unchanged, which sends them only to a model that takes them. With no <code>model</code> the pool picks one; a named text-only model, or a pool with none that can, is a 400 that says so. Request bodies may be up to 32 MiB.',
      '<code>GET /v1/models</code>: the pool catalog, with state, purpose (<code>chat</code>, <code>embed</code>, <code>transcribe</code>, <code>speak</code>, ...), replicas, context, revision, <code>vision</code>, <code>audio</code>, <code>video</code> and <code>inputs</code> (0.2.5), a speaking model’s <code>speech</code> profile when reported (0.2.5), and a LoRA adapter’s <code>base</code> (0.2.2; <code>null</code> for models), and <code>origin</code> and <code>license</code> (0.2.3; <code>null</code> when the node doesn’t say) under <code>weirdnet</code>. <code>POST /v1/embeddings</code>: float vectors.',
      '<code>x-weirdnet-model</code>, <code>x-weirdnet-cache: hit</code> and <code>x-weirdnet-standin</code> headers; <code>x-wait: 1</code> waits for the requested model instead of a stand-in.',
      'Answer cache (0.2.1): <code>"cache": false</code> or <code>x-weirdnet-cache: off</code> skips the nodes’ answer cache; <code>"cache": "refresh"</code> or <code>x-weirdnet-cache: refresh</code> refreshes it. The stricter of body and header wins; other values are a 400.',
      'Adapter scale (0.2.2): <code>"adapter_scale"</code> in a chat or completion body sets how strongly a LoRA adapter model applies for that request (weirdnet-agent <code>Request::adapter_scale</code>); a value that is not a finite number is a 400.',
      '<code>GET /metrics</code>: Prometheus counters <code>weirdnet_bridge_{requests,errors,cache_hits,standin}_total</code>.',
      '<code>request</code>: OpenAI bodies to infer/2 requests. <code>new_token()</code> makes a 32-byte hex token.',
    ],
    dependsOn: ['agent'],
    example: r'''# Cargo.toml
weirdnet-openai = "0.2"

// main.rs
use std::sync::Arc;
use weirdnet_openai::{Bridge, BridgeOptions, new_token};

let token = new_token(); // show it to the user once; keep it in their keychain
let bridge = Bridge::bind(BridgeOptions::new(11435, token)).await?;
bridge.serve(Arc::new(pool), shutdown).await?; // pool: weirdnet_agent::remote::pool::Pool''',
    notes: 'Version 0.2.5 is on <a href="https://crates.io/crates/weirdnet-openai/0.2.5">crates.io</a> (<a href="https://docs.rs/weirdnet-openai/0.2.5">docs.rs</a>). 0.2.5 is additive and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.11: <code>POST /v1/audio/speech</code> and <code>POST /v1/audio/transcriptions</code>, <code>video_url</code> parts in chat, and <code>weirdnet.video</code>, <code>weirdnet.inputs</code>, <code>weirdnet.speech</code> and the video limits in <code>/v1/models</code>. 0.2.4 is additive and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.7: a configurable request size limit with a 413 that names it, and media limits in <code>/v1/models</code>. Extracted from Ymir’s <code>ymir-openai</code>. 0.2.3 is additive and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.4: <code>weirdnet.origin</code> (<code>hub</code>, <code>upload</code> or <code>train</code>) and <code>weirdnet.license</code> in <code>/v1/models</code>. 0.2.2 is additive and needs <a href="/crates/agent">weirdnet-agent</a> 0.5.2: <code>"adapter_scale"</code> in chat and completion bodies, and <code>weirdnet.base</code> in <code>/v1/models</code> for LoRA adapters. 0.2.1 is additive and needs weirdnet-agent 0.5.1: the <code>cache</code> parameter and <code>x-weirdnet-cache</code> request header, and <code>request::cache_header</code> / <code>request::stricter</code>. 0.2.0 needs weirdnet-agent 0.5 (breaking, since it takes an agent <code>Pool</code>): image and audio content parts pass through to the pool instead of a 400, <code>/v1/models</code> reports <code>vision</code> and <code>audio</code>, and request bodies may be up to 32 MiB (16 MiB before). 0.1.2 (on weirdnet-agent <code>"0.4.2"</code>) adds <code>continue_final_message</code>: with no node that can continue it is a 501, and with <code>add_generation_prompt: true</code> or a last message that is not a plain assistant message, a 400. 0.1.1 (on weirdnet-agent <code>"0.4.1"</code>) makes <code>/v1/completions</code> work as an infer/2 raw prompt, whole or streamed (a node that can’t take raw prompts answers 501); streamed answers carry <code>x-weirdnet-cache: hit</code> from early metadata; <code>/v1/embeddings</code> reports real <code>usage.prompt_tokens</code> and keeps a node’s bad request a 400. Unknown parameters are ignored (<a href="https://github.com/WeirdBrains/weirdnet-openai/issues/1">#1</a>); <code>Retry-After</code> is 1 s until busy nodes report a delay (<a href="https://github.com/WeirdBrains/weirdnet-openai/issues/2">#2</a>).',
    origin: 'Ymir',
  ),
  Crate(
    slug: 'semcache',
    version: '0.2.3',
    tagline: 'The answer cache for inference nodes: the AnswerCache seam, a store trait, an exact-match cache for deterministic requests, similarity lookup by embedding, and pool mode: one cache shared across a pool’s inference nodes.',
    about: [
      'Before an inference node routes a prompt it asks the cache; afterwards it offers the finished answer. Requests and answers are <a href="/crates/agent">weirdnet-agent</a> 0.5.1 infer/2 types, and the store is a trait, so answers can live in memory, on disk or be shared between nodes.',
    ],
    parts: [
      '<code>AnswerCache</code>: <code>get(model, request)</code> and <code>put(model, request, answer)</code>; <code>NoCache</code> caches nothing.',
      '<code>CachedAnswer</code>: text, reasoning, tool calls, finish reason, usage and model, from a pool <code>Answer</code>.',
      '<code>AnswerStore</code>: opaque bytes under 32-byte keys. <code>MemoryStore</code> is bounded and least-recently-used.',
      '<code>ExactCache</code>: answers only byte-identical deterministic requests (temperature 0, no tools, inline messages, same model, seed, response format and raw flag) and keeps only answers that finished with <code>stop</code> or <code>length</code>. The key is SHA-256 over their CBOR.',
      '<code>may_read</code> and <code>may_store</code> (0.2.1): the request’s <code>CacheMode</code>. <code>ExactCache</code> never reads for <code>bypass</code> or <code>refresh</code> and never stores for <code>bypass</code>.',
      '<code>AnswerCache::get_rev</code> / <code>put_rev</code> and <code>exact_key_rev</code> (0.2.1): keys that include the model revision, so new weights under the same id don’t replay old answers. With no revision the key is unchanged.',
      '<code>SemanticCache</code> (0.2.2): similarity lookup by embedding. The nearest stored embedding in the same scope stands in when its cosine similarity reaches the threshold (default 0.95); <code>lookup</code> returns <code>Lookup::Hit { value, score, id }</code> or <code>Lookup::Miss { best }</code>. Bounded and least-recently-used, with an optional TTL, stats and a CBOR <code>snapshot</code> / <code>restore</code>.',
      '<code>scope_key</code>, <code>cosine_similarity</code> and <code>normalize</code> (0.2.2): a scope over the model, revision and system prompt so answers never cross them, and the vector helpers.',
      '<code>ShardRing</code> / <code>ShardPlan</code> (0.2.3): rendezvous hashing of a scope or exact key to a home node and one replica, so a shared lookup is one call; a leaving node’s shards move to their replica, and a joining node takes only the shards it now ranks first for.',
      '<code>SharedCacheReq</code> / <code>SharedCacheResp</code> and <code>SharedCacheHost</code> (0.2.3): the versioned CBOR lookup / insert / remove / exact protocol on <code>/weirdnet-semcache/shared/1</code>, answered from a node’s own cache within <code>HostLimits</code>.',
      '<code>pool::PooledSemanticCache</code> (0.2.3, <code>pool</code> feature): L1, the home, the replica when the home fails, per-call timeouts, down-node skipping, background replica writes, optional read repair and shared exact entries. A cache outage is a miss, never a stalled prompt. <code>pool::DialerTransport</code> and <code>pool::serve</code> run it over weirdnet-agent channels behind your <code>Authorize</code>.',
    ],
    dependsOn: ['agent'],
    example: r'''# Cargo.toml
weirdnet-semcache = "0.2"

// main.rs
use weirdnet_semcache::{AnswerCache, CachedAnswer, ExactCache};

let cache = ExactCache::new(256);
if let Some(hit) = cache.get_rev("qwen3-8b", Some(revision), &request) {
    // replay hit.text and mark the answer as a cache hit (infer/2 Meta::cache_hit)
}
cache.put_rev("qwen3-8b", Some(revision), &request, &CachedAnswer::from(&answer));

// similarity lookup: you embed the prompt
use weirdnet_semcache::{Lookup, SemanticCache, SemanticConfig, scope_key};

let semantic: SemanticCache = SemanticCache::with_config(SemanticConfig::new(1024).with_threshold(0.92));
let scope = scope_key(&["qwen3-8b", revision, &system_prompt_hash]);
if let Lookup::Hit { value, score, .. } = semantic.lookup(&scope, &embedding)? {
    // replay value.text; score is the cosine similarity
}
semantic.insert(&scope, &embedding, CachedAnswer::from(&answer))?;

// pool mode (features = ["pool"]): one cache across the pool's inference nodes
use std::sync::Arc;
use weirdnet_semcache::pool::{DialerTransport, PoolConfig, PoolLookup, PooledSemanticCache};

let shard = Arc::new(SemanticCache::with_config(SemanticConfig::new(4096).with_threshold(0.92)));
let pooled: PooledSemanticCache = PooledSemanticCache::new(my_peer_id, shard, Arc::new(DialerTransport::new(dialer)), PoolConfig::new());
pooled.set_nodes(inference_node_peer_ids); // this node included; serve pooled.host() with pool::serve
if let PoolLookup::Hit { value, .. } = pooled.lookup(&scope, &embedding).await? {
    // replay value.text; peers that fail or time out are a miss, never an error
}
pooled.insert(&scope, &embedding, CachedAnswer::from(&answer)).await?;''',
    notes: 'Version 0.2.3 is on <a href="https://crates.io/crates/weirdnet-semcache/0.2.3">crates.io</a> (<a href="https://docs.rs/weirdnet-semcache/0.2.3">docs.rs</a>). 0.2.3 is additive: <code>ShardRing</code>, <code>ShardPlan</code>, <code>SharedCacheReq</code>, <code>SharedCacheResp</code>, <code>SharedCacheHost</code>, <code>HostLimits</code>, <code>PROTOCOL</code> and <code>WIRE_VERSION</code> in the default build, with no new dependencies, and the opt-in <code>pool</code> feature (<code>PooledSemanticCache</code>, <code>CacheTransport</code>, <code>DialerTransport</code>, <code>serve</code>), whose <code>tokio</code> and <code>async-trait</code> already come with weirdnet-agent. Requested for Ymir’s shared semantic cache. 0.2.2 is additive, with no new dependencies: <code>SemanticCache</code>, <code>SemanticConfig</code>, <code>Lookup</code>, <code>SemanticError</code>, <code>SemanticStats</code>, <code>scope_key</code>, <code>cosine_similarity</code> and <code>normalize</code>. 0.2.1 is additive and needs weirdnet-agent 0.5.1: <code>may_read</code>, <code>may_store</code>, <code>AnswerCache::get_rev</code> / <code>put_rev</code> (default methods) and <code>exact_key_rev</code>. 0.2.0 needs weirdnet-agent 0.5 (content parts), which is breaking because <code>AnswerCache</code> takes agent <code>Request</code>s: move to agent 0.5 with it. Requests with image or audio parts are keyed like text ones, so a different image is a different request. 0.1.1 depends on weirdnet-agent <code>"0.4"</code> instead of <code>=0.4.0</code>, so it builds with agent 0.4.1; raw prompts (agent 0.4.1 <code>Input::Prompt</code>) are not cached. Extracted from Ymir’s <code>ymir-semcache</code>.',
    origin: 'Ymir',
  ),
  Crate(
    slug: 'media',
    version: '0.1.0',
    status: Status.fresh,
    tagline: 'Audio and video processing for clients and nodes: WAV and PCM in pure Rust, 16 kHz resampling, silence-aware chunking, long-audio transcription and long-text speech plans, SRT and WebVTT, video frame planning and extraction, and a hardened ffmpeg runner with a test fake.',
    about: [
      'The media work an app does before it sends audio or video to a model and after it gets speech back, in one place. WAV, PCM, resampling, chunking, plans and subtitles are pure Rust; everything else goes through <code>ffmpeg</code> and <code>ffprobe</code> in child processes behind a hardened runner, and a fake runner answers in tests so they never need ffmpeg.',
      'There are no defaults that stand in for a model’s limits. Plans take what the model reports (<code>audio_max_seconds</code>, <code>max_request_bytes</code>, <code>max_input_chars</code>, frame counts and sizes, as <a href="/crates/agent">weirdnet-agent</a> catalogs carry them) and refuse, naming the missing setting, when it is absent. Nothing is fetched: inputs are files the caller chose or bytes it holds.',
    ],
    parts: [
      '<code>probe</code>: WAV headers read in Rust (8 to 32-bit PCM, 32 and 64-bit float, extensible headers, streamed sizes); any other container through <code>ffprobe</code> into a <code>MediaInfo</code>.',
      '<code>pcm</code>: decode and write WAV, mono mixing, windowed-sinc resampling to 16 kHz for transcribers, equal-power <code>crossfade</code>, and <code>concat</code> with crossfade, pause or cut joins (every piece must share rate and channels).',
      '<code>vad::silence_cuts</code>: 30 ms RMS frames, each cut at the quietest frame in the last fifth of its window, no overlap.',
      '<code>transcribe</code>: <code>plan</code> sends a clip whole when it fits and cuts it at silences when it is longer than <code>audio_max_seconds</code>; <code>prompt_from</code> carries the last 200 characters to the next piece; <code>realign</code> shifts segments onto the clip and marks pieces without segments as <code>coarse</code>.',
      '<code>speak::TextPlan</code>: narration or a script split to fit <code>max_input_chars</code> at paragraph, sentence, clause, then word boundaries, never inside a word or mixing speakers, with the joins to stitch the audio (10 ms crossfade inside a paragraph, 300 ms pause between paragraphs and turns).',
      '<code>subtitles</code>: SRT and WebVTT from segments.',
      '<code>audio</code>: normalization to 16 kHz mono WAV, soundtrack extraction from audio or video, and encoding to WAV, MP3, Opus or FLAC.',
      '<code>video</code>: <code>FrameSource</code> (<code>FfmpegSource</code> over the runner, <code>FakeSource</code> for tests), <code>plan_frames</code> (uniform, scene, hybrid, keyframes, fixed intervals), <code>extract_frames</code>, <code>thumbnail</code>, <code>soundtrack</code> and stream-copied <code>clip</code>s.',
      '<code>ffmpeg::Runner</code>: protocol and demuxer allowlists, no URLs and no shell, input as a canonical file or on a pipe, bounded output, time, address-space and priority limits, a Linux network namespace when allowed. <code>FakeRunner</code> validates jobs the same way and answers from rules or a <code>FakeMedia</code>.',
    ],
    example: r'''# Cargo.toml
weirdnet-media = "0.1"

// main.rs
use weirdnet_media::ffmpeg::{Input, Runner};
use weirdnet_media::video::{FfmpegSource, FrameRequest, Mode, extract_frames};

let runner = Runner::locate(Some("MYAPP_FFMPEG"))?;
let source = FfmpegSource::new(&runner, Input::file("clip.mp4"));
// count and edge come from the model's reported limits
let (probe, frames) = extract_frames(&source, &FrameRequest::new(count).max_edge(edge).mode(Mode::Hybrid))?;''',
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-media/0.1.0">crates.io</a> (<a href="https://docs.rs/weirdnet-media/0.1.0">docs.rs</a>, <a href="https://github.com/WeirdBrains/weirdnet-media">repository</a>). Its only dependencies are serde, serde_json and, on Unix, libc. The ffmpeg-backed tests run where ffmpeg is installed; the rest run against the fake runner.',
    origin: 'Bragi’s video sampler',
  ),
  Crate(
    slug: 'alerts',
    version: '0.2.2',
    tagline: 'Host alerts for nodes: weirdnet-rules over observations, a default rule pack, probes, and SMTP, webhook and push-wake sinks.',
    about: [
      'An application feeds the alerter observations (an engine crashed, the default route moved to Wi-Fi, a disk is nearly full, a GPU is hot); <a href="/crates/rules">weirdnet-rules</a> specs turn them into failing, recovered and one-off alerts, deduped per key, and sinks deliver them.',
    ],
    parts: [
      '<code>Alerter</code>, <code>Observation</code>, <code>Action</code> (<code>fail</code>, <code>ok</code>, <code>event</code>), <code>Alert</code>, <code>AlertStatus</code>: evaluation, per-key dedupe with a repeat interval, and recovery notices.',
      '<code>rules</code>: <code>default_rules</code> and <code>Thresholds</code>: engine crash loops, failed loads and crashes; the default route; free disk; GPU temperature with hysteresis.',
      '<code>probe</code>: <code>route</code>, <code>disk</code>, <code>gpus</code> (Linux and Unix).',
      '<code>sinks</code>: <code>Sink</code>, <code>SmtpSink</code>, <code>WebhookSink</code>, <code>LogSink</code>, <code>MemorySink</code>, and <code>PushSink</code> (feature <code>push</code>).',
      '<code>config</code>: <code>AlertsConfig</code> builds the alerter and its sinks; secrets are <code>env:</code> or <code>file:</code> references only.',
      '<code>engine</code> (feature <code>backends</code>): <code>observation</code>, <code>probes</code> and <code>monitor</code> for <a href="/crates/backends">weirdnet-backends</a> supervisor events (0.2 to 0.4 since 0.2.2, 0.2 or 0.3 in 0.2.0 and 0.2.1; a model or adapter removed at run time clears its engine alert).',
    ],
    dependsOn: ['rules', 'push', 'backends'],
    example: r'''# Cargo.toml
weirdnet-alerts = "0.2"

// main.rs
use weirdnet_alerts::{AlertsConfig, Observation};

let cfg: AlertsConfig = toml::from_str(&std::fs::read_to_string("alerts.toml")?)?;
let alerter = cfg.alerter("gpu-01")?.with_product("my-node");
alerter.observe(&Observation::new("disk", serde_json::json!({"path": "/", "free_pct": 4.0}))).await;''',
    notes: 'Version 0.2.2 is on <a href="https://crates.io/crates/weirdnet-alerts">crates.io</a> (<a href="https://docs.rs/weirdnet-alerts/0.2.2">docs.rs</a>). 0.2.2 lets the <code>backends</code> feature take <a href="/crates/backends">weirdnet-backends</a> 0.4 (LoRA adapters) as well as 0.2 and 0.3, with no API changes; adapters added or removed at run time are <code>engine.added</code> and <code>engine.removed</code> observations like models. 0.2.1 changes only package metadata and docs. 0.2.0 is breaking for <code>backends</code> users: the feature takes <a href="/crates/backends">weirdnet-backends</a> 0.2 or 0.3 (on weirdnet-agent 0.5) instead of 0.1, so apps on agent 0.5 get one copy of each. The default rules clear an engine’s alert when its model is removed at run time (<code>engine.removed</code>). Nothing changes without the <code>backends</code> feature. Extracted from Ymir’s <code>ymir-alerts</code>. Push alerts are wake-ups only: the alert text stays on the node. The <code>push</code> feature pulls in aws-lc through reqwest.',
    origin: 'Ymir',
  ),
  Crate(
    slug: 'plugin',
    version: '0.1.1',
    group: 'Extensions and plugins',
    tagline: 'The plugin SDK: the stable C ABI (v2), host API, frames and result views.',
    about: [
      'The SDK for Weirdnet code space plugins. A plugin is a <code>cdylib</code> exporting <code>weirdnet_plugin_abi</code>, <code>weirdnet_plugin_info</code> and <code>weirdnet_plugin_run</code>; the crate has no dependencies, so plugins build offline. Hosts load plugins with <code>weirdnet-code-spaces</code>.',
      'This in-process ABI is for trusted first-party plugins only; untrusted extensions run out of process in a sandbox.',
    ],
    parts: [
      'The stable C ABI, version 2 (version 1’s layout; only symbol names and the version differ).',
      'The safe <code>Host</code> API over the host’s JSON methods, frames of loaded records and series helpers.',
      'Result views (table, chart, text, tiles), the ingest-connector methods, and the <code>plugin!</code> macro.',
    ],
    usedBy: ['weirdnet-code-spaces'],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'code-spaces',
    version: '0.1.2',
    group: 'Extensions and plugins',
    tagline: 'Math, Polars, Rust and typed Python sources compiled into plugins against the plugin SDK.',
    about: [
      'Code spaces: small programs compiled into native plugins against <code>weirdnet-plugin</code> and run against the application’s data through host methods.',
      'Plugins run as native code with the application’s rights. Approving one is trusting it; this crate checks hashes and the ABI, it does not sandbox.',
    ],
    parts: [
      '<b>Languages</b>: math formulas, Polars expressions, Rust, typed Python translated in process (no libpython), and prebuilt libraries.',
      '<b>Builds</b>: generated crates against the bundled SDK, a shared target directory, libraries cached by a content key.',
      '<b>Loading</b> once per process after checking symbols and the ABI version; <b>trust</b> hashes an owner approves.',
      '<b>Spaces</b>: <code>@imports</code>, renames, and the cycle and depth check. <b>Result views</b> parsed, checked and cut to their limits.',
    ],
    dependsOn: ['plugin'],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'pipelines',
    version: '0.1.1',
    tagline: 'DAGs of application-defined sources, steps and sinks with validation, ordering and a runner.',
    about: [
      'Pipelines as graphs of nodes whose meaning belongs to the application. The runner reaches the application only through <code>Host</code>; lookups, permissions, approvals and storage stay in the application.',
    ],
    parts: [
      '<code>Kind</code>: the application’s node type. <code>Graph&lt;K&gt;</code>: nodes (<code>ID=KIND</code>, <code>+TEE</code>) and edges (<code>A&gt;B[:NAME]</code>).',
      '<code>Graph::order</code> (cycles are errors naming their nodes) and <code>Graph::check</code> (duplicates, missing nodes, self-loops, no source or sink, and more).',
      '<code>execute</code>: each node once, in order, with fan-out, fan-in and tees; a failing node skips the nodes below it.',
      '<code>frame</code>: JSON column frames from rows, CSV, JSON or NDJSON, with union, select, filter and Markdown output.',
    ],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'rules',
    version: '0.1.1',
    tagline: 'If-this-then-that rule specs, conditions, schedules and a loop-protected engine.',
    about: [
      'If-this-then-that over an event history, without knowing what the events or the actions are. The crate does no I/O and decides no permissions.',
    ],
    parts: [
      '<code>RuleSpec&lt;T&gt;</code>: <code>on</code> event patterns, <code>if</code> conditions, <code>then</code> actions of the application’s type, optional schedule, versioned JSON.',
      '<code>syntax</code>, <code>compare</code>: conditions such as <code>inserted &gt; 0</code> or <code>title ~ "btc halving"</code>.',
      '<code>schedule</code>: <code>every 6h</code> and five-field cron in any zone. <code>template</code>: <code>{field}</code>, <code>{rule}</code>, <code>{now}</code>.',
      '<code>engine</code>: matching, loop protection (no re-entry, bounded depth and runs), running actions in order, due scheduled rules.',
    ],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'render',
    version: '0.1.1',
    tagline: 'Tables and line charts (or JSON describing them) drawn to PNG with input checks and size limits.',
    about: [
      'Structured data drawn to PNG. Inputs are plain data, not any application’s types, and every entry point checks its input against <code>Limits</code> instead of drawing something unbounded.',
    ],
    parts: [
      '<code>Table</code>: column names and rows drawn as a grid with an 8×8 bitmap font.',
      '<code>Chart</code>: x values and named series (gaps allowed) drawn as a line chart, with a legend.',
      'JSON describing either one: <code>{"columns":…,"rows":…}</code>, arrays of objects or rows, or <code>{"x":…,"series":…}</code>.',
    ],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'themes',
    version: '0.2.0',
    tagline: 'A TOML theme format: dark and light variants, semantic colour roles, contrast checks, NO_COLOR, and helpers for theme editors and switchers.',
    about: [
      'A theme format for terminal and GUI front ends: one TOML file per theme with <code>[meta]</code>, <code>[dark]</code> and <code>[light]</code> tables, 21 required semantic colour roles plus 6 optional ones, eight built-in palettes (Bragi’s among them), WCAG contrast checks and lightness-inverted variants.',
      '0.2.0 adds the optional roles (surface, code background, diff backgrounds, link, dim text), <a href="https://no-color.org">NO_COLOR</a> support, the terminal’s own background in 16 colours, a per-user themes folder with editing and switching helpers, and makes the terminal and OS light/dark probes opt-in.',
    ],
    parts: [
      'Storage is yours: <code>load</code>, <code>save</code>, <code>list</code>, <code>materialize</code> and <code>reset</code> work through the <code>ThemeDirs</code> trait; <code>UserDir::for_app</code> is the per-user default (0.2.0).',
      'Editors and switchers: <code>entries</code>, <code>duplicate</code>, <code>rename</code>, <code>delete</code>, <code>import</code>, <code>export</code>, <code>unique_name</code>, <code>cycle</code>, <code>VariantDef::set_role</code> (0.2.0).',
      '<code>OPTIONAL_ROLES</code> and <code>VariantDef::color</code>, which derives the optional roles a theme leaves out (0.2.0).',
      '<code>Mode::{Light, Dark, System}</code>; <code>resolve_variant</code> probes nothing, <code>resolve_variant_with</code> and <code>detect::Probe</code> opt in to the terminal and OS queries (0.2.0).',
      '<code>ColorDepth</code> with <code>None</code> for NO_COLOR and <code>TERM=dumb</code>; <code>VariantDef::resolve(role)</code> gives RGB and <code>to_hex</code> gives <code>#rrggbb</code>; optional ratatui colours by colour depth.',
    ],
    usedBy: ['Muninn', 'Bragi (moving onto it)'],
    origin: 'Muninn',
    notes: 'Version 0.2.0 is on <a href="https://crates.io/crates/weirdnet-themes">crates.io</a> (<a href="https://docs.rs/weirdnet-themes/0.2.0">docs.rs</a>). It is breaking: <code>terminal-background</code> is no longer a default feature, <code>Mode::System</code> no longer probes unless asked, <code>ColorDepth</code> has a <code>None</code> variant and the ratatui <code>Theme</code> is <code>#[non_exhaustive]</code>. See the <a href="https://github.com/WeirdBrains/weirdnet-themes/blob/main/CHANGELOG.md">CHANGELOG</a> and “Moving to 0.2.0” below.',
  ),
  Crate(
    slug: 'text',
    version: '0.1.1',
    status: Status.fresh,
    tagline: 'Toolkit-independent editing rules for text fields: grapheme-aware caret and selection, inline completions, input-method composition, UTF-16 offsets.',
    about: [
      'The behaviour behind a text field, kept out of the UI toolkit so it can be tested headless and shared by every app’s inputs. The app’s widget draws the field and feeds it keys and input-method events; <code>TextField</code> decides what they do.',
    ],
    parts: [
      '<code>TextField::new</code> (one line: pasted line breaks become spaces) and <code>TextField::multiline</code> (line breaks kept, <code>\\r\\n</code> normalised).',
      'Typing and pasting at the caret (<code>replace</code>), Backspace and Delete by whole grapheme clusters, Left, Right, Home and End with and without Shift, select-all and <code>selected_text</code>.',
      '<code>append_selected</code>: an inline completion that typing replaces, Backspace removes and Right accepts. <code>set_text_selected</code>: replace the text and select it, as an address bar does on focus.',
      '<code>replace_and_mark</code>, <code>marked</code>, <code>unmark</code>: input-method composition; <code>offset_to_utf16</code>, <code>range_from_utf16</code> and friends for platform input APIs.',
    ],
    usedBy: ['Morph and Bragi (moving onto it)'],
    origin: 'Morph',
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-text">crates.io</a> (<a href="https://docs.rs/weirdnet-text/0.1.0">docs.rs</a>), extracted unchanged from Morph’s <code>morph-ui</code> text module. Offsets are UTF-8 byte offsets on grapheme boundaries. The GPUI widget that uses it stays in each app: GPUI is not on crates.io at the revision the apps use, so a shared widget crate can’t be published yet.',
  ),
  Crate(
    slug: 'sync',
    version: '0.8.5',
    group: 'Network',
    status: Status.fresh,
    tagline: 'Linked-device sync: hybrid logical clocks, an op log, LWW and OR-set merge, sealed pages, large and sealed records, a device roster with key rotation on revoke, signed device grants, seedless service devices, and majority-vote leases, plans and jobs.',
    about: [
      'Sync between one person’s devices over <code>weirdnet-net</code>: a hybrid logical clock, an append-only per-node op log, last-writer-wins registers, OR-set merge, tombstone garbage collection, pages sealed under a typed <code>SyncKey</code>, a device roster with self-issued node certificates and revocation, the <code>/weirdnet/sync/2</code> pull protocol, and (0.4.0) records too big for one page, split into hash-checked chunks, and sealed records that a device revoked before a write cannot open.',
      'Record types (bookmarks, history, settings, notes) and persistence stay in the application; <code>OpLog</code> is the in-memory log it snapshots.',
    ],
    parts: [
      '<code>Hlc</code>, <code>NodeId</code>: hybrid logical clocks with <code>tick</code> and <code>receive</code>.',
      '<code>OpLog</code>, <code>LogEntry</code>: per-node sequences, per-(node, type) cursors, pages and <code>integrate</code>.',
      '<code>lww</code>, <code>OrSet</code>, <code>edit_vs_delete</code>, <code>can_gc_tombstone</code>, <code>folder_cycle</code>: the merge rules.',
      '<code>SyncState</code>, <code>SyncHandler</code>, <code>start_node</code>, <code>pull_from</code>: the protocol over a weirdnet-net node.',
      '<code>SyncState::snapshot</code>, <code>merge_back</code> (<code>MergeOutcome</code>), <code>pull_from_shared</code>, <code>pull_from_outcome</code> and <code>PullOutcome</code>: pull without holding the shared lock, and keep the count of pages applied when a pull stops early (0.5.1).',
      '<code>Roster</code>, <code>DeviceKey</code>, <code>Rotation</code>, <code>KeyChain</code>, <code>EpochKeys</code>, <code>KeyStatus</code>: certificates, revocation, key rotation and re-admission.',
      '<code>sync_key</code>, <code>seal_page</code>, <code>open_page</code>: typed keys and sealed pages.',
      '<code>SyncState::configure</code>, <code>write</code>, <code>read</code>, <code>reseal_stale</code>, <code>pull_chunks</code>; <code>Limits</code>, <code>RecordOptions</code>, <code>RecordValue</code>: large and sealed records (0.4.0).',
      '<code>Roster::check_caller</code>, <code>CallerCheck</code>: is the authenticated caller of an app call one of the user’s linked devices (0.4.0).',
      '<code>Identity</code>, <code>LinkSettings</code>, <code>Tick</code> (0.6.0): the on-disk identity store every app with linked devices needs (seed, node key and certificate, epoch keys, roster), parameterised on the app’s sync type, with <code>create</code>, <code>adopt</code> after a device link, <code>approve</code>, <code>revoke</code> and a <code>tick</code> that syncs with every linked device.',
      '<code>DeviceGrant</code>, <code>DeviceClass</code>, <code>Roster::roles_of</code>, <code>SyncState::new_service</code>, <code>LinkBundle</code>, <code>Identity::service_bundle</code> / <code>adopt_service</code>, <code>SecretStore</code> (0.7.0): device roles and seedless service devices.',
      '<code>Voters</code>, <code>Voter</code>, <code>Leases</code>, <code>Elector</code>, <code>Term</code>, <code>FenceGuard</code>, <code>Identity::enable_voter</code> / <code>disable_voter</code> (0.8.0): majority-vote leases with fencing terms, for one device that decides.',
      '<code>SyncState::publish_plan</code>, <code>current_plan</code>; <code>Jobs</code>, <code>JobSpec</code>, <code>Leases::claim_job</code> (0.8.0): signed plans ordered by term, and a job log with per-job claims.',
      '<code>JobRules</code>, <code>Jobs::pause</code> / <code>resume</code>, <code>JobEvent::Note</code>, <code>LeaseLimits</code>, <code>Voter::with_limits</code> (0.8.1): who may claim a job, a takeover wait after a lapsed claim, a backoff after a failure, pausing without using an attempt, and holder notes.',
      '<code>Roster::scoped_types</code>, <code>Roster::may_sync</code>, <code>EpochKeys::get_scoped</code>, <code>Envelope::seal_scoped</code> / <code>open_scoped</code>, <code>LEASE_TYPE</code> (0.8.3): type-scoped keys for service devices, and their grants enforced on every request.',
      '<code>SyncState::seals_scoped</code>, <code>Roster::service_granted</code>, <code>seal_record_scoped</code> / <code>open_record_scoped</code>, <code>scoped_record_key</code> (0.8.4): sealed records a service device granted the type can read and write.',
      '<code>pull_types</code>, <code>pull_types_shared</code>, <code>PullTypesOutcome</code> (0.8.5): several record types from one peer in one session, one hello for all of them, each type under its own key.',
    ],
    dependsOn: ['net', 'keys'],
    usedBy: ['Morph (bookmarks and linked devices)'],
    notes: 'Not audited. See <a href="https://github.com/WeirdBrains/weirdnet-sync/blob/main/SECURITY.md">SECURITY.md</a> in the repository. 0.5.0 moves to <a href="/crates/net">weirdnet-net</a> 0.8 and protocol <code>/weirdnet/sync/2</code>, and does not talk to 0.4 nodes: upgrade every device together. Stored data is unchanged. 0.5.1 is additive: <code>SyncState</code> snapshots and <code>merge_back</code>, <code>pull_from_shared</code>, and <code>PullOutcome</code>; <code>take_keys_from</code> is deprecated in favour of <code>merge_back</code>. 0.5.2 fixes a device linked on one device not reaching the others in one pass (wire-compatible). 0.6.0 adds <code>Identity</code>, extracted from Ymir’s <code>membership</code> and Bragi’s <code>identity</code> modules (same files on disk), and makes <code>SyncError</code> non-exhaustive with <code>Io</code> and <code>Identity</code> variants: breaking only for code that matches it exhaustively. 0.7.0 adds service devices linked without the seed and user-signed device grants (roles, class, sync types) in the roster; it is breaking (<code>SyncState::seed</code> is an <code>Option</code>, <code>Roster</code>, <code>KeyStatus</code>, <code>Envelope</code> and <code>SyncError</code> grow). Full 0.6 and 0.7 devices interoperate; a service device needs 0.7 peers. 0.8.0 adds majority-vote leases with fencing terms, signed plans and a job log with per-job claims; it is breaking (<code>SyncState</code> has a <code>voter</code> field and <code>Message</code> has lease variants). Pulls between 0.7 and 0.8 devices are unchanged; every voter needs 0.8. 0.8.1 is additive: job rules (candidates, a role, a takeover wait and a retry backoff, enforced when folding and by voters), pausing and resuming jobs, holder notes and per-prefix voter limits; jobs without rules behave as in 0.8.0, and 0.7.1 sealed records read and write unchanged. 0.8.2 makes an owner’s pause spare the claim in progress even when its holder’s lease ran out before the holder recorded its own pause. 0.8.3 is additive and wire-compatible: a service device with sync types holds type-scoped keys for its granted types only, never an epoch key, so a node granted <code>ymir.train</code> cannot open <code>ymir.context</code>; devices also refuse a service peer’s requests for types outside its grant. Upgrade full devices to 0.8.3 before relying on it. 0.8.4 is additive: a service device granted a sealed record type (such as <code>ymir.context</code>) reads and writes its records under a type-scoped record key; full devices use that key only while an active service device is granted the type, so older devices keep reading the rest. Every full device that reads a type shared with a service device needs 0.8.4. 0.8.5 is additive and wire-compatible: <code>pull_types</code> pulls several record types in one session (one hello for all of them, each type under its own key), also from 0.7.1 and 0.8.0 to 0.8.4 peers; servers refuse a <code>Pull</code> sealed under another type than the one it asks for. Version 0.8.5 is on <a href="https://crates.io/crates/weirdnet-sync/0.8.5">crates.io</a> (<a href="https://docs.rs/weirdnet-sync/0.8.5">docs.rs</a>). See Moving to 0.7.0 and Moving to 0.8.0 in the guide.',
  ),
  Crate(
    slug: 'push',
    version: '0.1.1',
    group: 'Network',
    tagline: 'Push wake-up: 96-byte sealed wake payloads, rotating wake handles, and a self-hostable server for APNs, FCM and relays.',
    about: [
      'A suspended phone can’t keep a connection, so a peer or its home relay asks a push service to wake it. This crate is that service, its client and the payload format, built so that Apple, Google and the push service see only ciphertext.',
    ],
    parts: [
      '<code>wake</code>: <code>PushKey</code>, <code>Payload96</code>, <code>Reason</code>, <code>seal</code>, <code>ReplayGuard</code>.',
      '<code>handle</code>: <code>WakeHandle</code>, <code>WakeCard</code>, <code>ControlSecret</code> (rotate and revoke).',
      '<code>PushClient</code>: register, rotate, unregister, wake, follow announcements.',
      '<code>relaywake</code>: the <code>/weirdnet/wake/1</code> relay wake path.',
      '<code>server</code> and the <code>weirdnet-push</code> binary: APNs, FCM HTTP v1 and relay delivery.',
    ],
    dependsOn: ['keys'],
    usedBy: ['weirdnet-relay'],
  ),
  Crate(
    slug: 'device-link',
    version: '0.4.2',
    group: 'Identity and access',
    tagline: 'Move a Weirdnet identity to another device over a QR offer, a 6-digit code check and a sealed transfer.',
    about: [
      '<code>weirdnet-device-link/v1</code>: move a user identity to another device of the same person without typing its recovery words. Built in Morph as “Login over QR” and moved here; 0.3.0 folds in the rest of Morph’s copy: compact codes, relay reach and relay status.',
    ],
    parts: [
      '<code>offer</code>: <code>Offer</code>, <code>VerifiedOffer</code>, <code>encode_link</code>, <code>decode_link</code>, <code>offer_addrs</code>.',
      '<code>compact</code>: <code>KNOWN_RELAYS</code>, <code>pack_addr</code>, <code>unpack_addr</code>: the compact (version 2) code encoding.',
      '<code>invite</code>: the reverse direction, where the existing device shows the QR.',
      '<code>session</code>: <code>Host</code> and <code>Sender</code>, both sides without the network, and <code>make_transfer</code> / <code>make_transfer_with</code>.',
      '<code>net</code>: <code>HostNode</code> and <code>Pairing</code> over weirdnet-net on <code>/weirdnet/link/2</code> (and invites on <code>/weirdnet/link-invite/2</code>).',
      '<code>reach</code>: <code>with_link_limits</code> and <code>relay_groups</code>.',
      '<code>relays</code>: <code>RelayProbe</code>, <code>RelayState</code>, <code>relay_states</code>: real relay state for a settings page.',
      '<code>wire</code>: <code>LinkRequest</code>, <code>LinkReply</code>, <code>Transfer</code>, <code>Credential</code> (CBOR).',
      '<code>Pairing::send_credential</code>, <code>take_any</code>, <code>Received</code> (0.4.0): service links that carry a certificate and a sync bundle, never the seed.',
      '<code>offer_scheme</code>, <code>is_offer</code>, <code>known_relays</code>, <code>parse_relays</code>, <code>relays_from_env</code>, <code>link_node_config</code> (0.4.2, and 0.3.3 on the 0.3 line): pair with several apps’ codes, and set up a link node’s relays and configuration.',
    ],
    dependsOn: ['net', 'keys'],
    usedBy: ['Morph'],
    origin: 'Morph',
  ),
  Crate(
    slug: 'access',
    version: '0.1.2',
    group: 'Identity and access',
    tagline: 'Access policy: Private/Public and Open/Gated, a shared permission core apps extend, ranked roles, and the enforcement order.',
    about: [
      'Access policy for Weirdnet apps. It answers “may this peer do this to this resource?” the same way in every app, from facts the app has already checked.',
    ],
    parts: [
      '<code>Visibility</code>, <code>Access</code>: the two independent settings.',
      '<code>Catalog</code>, <code>Permission</code>: the core permissions, app permissions and implications.',
      '<code>Role</code>, <code>RoleSet</code>, <code>Actor</code>, <code>presets</code>, <code>check_grant</code>, <code>check_over</code>: ranked roles and rank rules.',
      '<code>decide</code>, <code>Facts</code>, <code>Settings</code>, <code>Decision</code>, <code>Transport</code>: enforcement.',
    ],
    usedBy: ['Muninn (org roles)', 'Morph'],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'schemes',
    version: '0.1.1',
    group: 'Identity and access',
    tagline: 'The URL scheme registry: signed prefixes and schemes, the canonical list, a resolver, and OS handler registration.',
    about: [
      'The registry every Weirdnet app shares, so a <code>weirdnet-&lt;app&gt;://</code> link means the same thing on every device and to every app. Prefixes beginning with <code>weirdnet</code> are reserved for WeirdBrains.',
    ],
    parts: [
      '<code>names</code>: prefix and scheme rules, reserved and standard schemes, <code>first_party</code>.',
      '<code>PrefixRecord</code>, <code>SchemeRecord</code>, <code>CanonicalList</code>, <code>RootRotation</code>, <code>TrustAnchors</code>, <code>Signed</code>: signed records.',
      '<code>Registry</code>, <code>Resolution</code>: the local resolver with pins and conflict rules.',
      '<code>Link</code>, <code>Action</code>: join, answer and resource links.',
      '<code>os</code>: Linux, Windows, Apple and Android handler registration.',
    ],
    usedBy: ['Morph', 'weirdnetctl'],
  ),
  Crate(
    slug: 'weirdnetctl',
    crateName: 'weirdnetctl',
    docsRs: false,
    version: '0.1.1',
    group: 'Identity and access',
    binary: true,
    tagline: 'Holds and rotates Weirdnet signing keys, signs scheme records, and builds the signed canonical list.',
    about: [
      'The maintainer’s CLI for Weirdnet signing keys and the records they sign: the <a href="https://weirdbrains.com">WeirdBrains</a> root key, prefix and scheme records for weirdnet-schemes, countersignatures for reserved prefixes, and the canonical list.',
    ],
    parts: [
      '<code>key new|show|check|rotate</code>: passphrase-sealed Ed25519 key files.',
      '<code>prefix</code>, <code>scheme</code>: sign registrations and withdrawals.',
      '<code>countersign --as root|transfer</code>, <code>list</code>, <code>verify</code>.',
    ],
    dependsOn: ['schemes'],
    usedBy: ['<a href="https://weirdbrains.com">WeirdBrains</a> (the root key)', 'app publishers'],
  ),
  Crate(
    slug: 'ext',
    version: '0.1.1',
    group: 'Extensions and plugins',
    tagline: 'The extension host: signed packages, install and update rules, capability grants, a per-OS sandbox and a supervisor.',
    about: [
      'What an app such as Morph needs to install and run third-party extensions safely: out of process, sandboxed, and reaching the app only through a gRPC broker on a private socket.',
    ],
    parts: [
      '<code>package</code>: <code>Package</code>, <code>Installer</code>, <code>Plan</code>, <code>Installed</code>, <code>build</code>.',
      '<code>manifest</code>: <code>Manifest</code>, <code>Capability</code>, signing and verification.',
      '<code>Grants</code>: what the user granted, checked on every call.',
      '<code>sandbox</code>: <code>Policy</code>, <code>Require</code>, <code>probe</code> (Landlock and seccomp, macOS sandbox).',
      '<code>supervisor</code> and <code>broker</code>: <code>Config</code>, <code>Handle</code>, <code>Status</code>, the <code>Services</code> trait.',
    ],
    dependsOn: ['ext-proto'],
    usedBy: ['Morph'],
    notes: 'Not audited. See <code>SECURITY.md</code> in the repository for the threat model.',
  ),
  Crate(
    slug: 'ext-proto',
    repo: 'weirdnet-ext',
    version: '0.1.1',
    group: 'Extensions and plugins',
    tagline: 'weirdnet.ext.v1: the protobuf contract between an extension host and its extensions, with tonic stubs.',
    about: [
      'The wire contract for Weirdnet extensions: lifecycle, handshake, capabilities, logging and health. App-specific services travel inside it as prost-encoded bytes. It lives in the weirdnet-ext repository.',
    ],
    parts: [
      '<code>v1</code>: the generated messages and the <code>Host</code> service (client and server).',
      '<code>API_VERSION</code>, <code>ENV_SOCKET</code>, <code>ENV_FD</code>, <code>ENV_TOKEN</code>, <code>ENV_ID</code>, <code>SESSION_HEADER</code>.',
    ],
    usedBy: ['weirdnet-ext', 'weirdnet-ext-sdk'],
  ),
  Crate(
    slug: 'ext-sdk',
    repo: 'weirdnet-ext',
    version: '0.1.1',
    group: 'Extensions and plugins',
    tagline: 'Write Weirdnet extensions: connect to the host, call app services, log, report health, handle events.',
    about: [
      'The SDK for extension authors. It lives in the weirdnet-ext repository.',
    ],
    parts: [
      '<code>Extension</code>: <code>connect</code>, <code>granted</code>, <code>has</code>, <code>call</code>, <code>log</code>, <code>health</code>, <code>run</code>.',
      '<code>Event</code>, <code>Capability</code>, <code>Error</code>.',
    ],
    dependsOn: ['ext-proto'],
  ),
];

Crate crateBySlug(String slug) => crates.firstWhere((c) => c.slug == slug);

/// The crate's name for a slug, or `weirdnet-<slug>` when it has no entry.
String crateNameOf(String slug) => crates.where((c) => c.slug == slug).map((c) => c.name).firstOrNull ?? 'weirdnet-$slug';
