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

  String get name => 'weirdnet-$slug';
}

const crates = <Crate>[
  Crate(
    slug: 'net',
    group: 'Network',
    tagline: 'The libp2p node, key exchanges, invitations, sealed messaging, identities and certificates.',
    about: [
      'Peer-to-peer networking for applications that keep their own data. The application brings its own request and response types, its own storage and its own policy; the crate brings the wire.',
      'Every identifier on the wire or under a signature comes from a <code>Profile</code>. <code>WEIRDNET</code> is the default (<code>/weirdnet/net/1</code>, <code>wnet-x1-offer:</code>, port 4747 and so on). Key cryptography is not here: every derivation, seal and open goes through <code>weirdnet-keys</code>.',
    ],
    parts: [
      '<code>node</code>: a <code>Node&lt;Q, R&gt;</code> over TCP and QUIC (or an in-memory transport for tests) with Noise and Yamux, mDNS, Kademlia, identify, ping, a relay client and an opt-in relay server, DCUtR hole punching and AutoNAT. The swarm runs on its own thread; the handle is blocking. Requests are the application’s <code>Q</code>, answers its <code>R</code> (CBOR).',
      '<code>names</code>: signed peer records and withdrawals, a names (rendezvous) server, checked DHT records under <code>SHA-256("weirdnet/peer/" + user id)</code>, <code>_weirdnet.&lt;name&gt;</code> TXT bindings, and key-only dialing (<code>request_key</code>, <code>request_user</code>).',
      '<code>exchange</code>: signed offers and answers (Ed25519 node keys, fresh X25519 keys), the derived exchange key, a ten-digit short code and a fingerprint to compare out of band, tokens and links, scopes with an expiry, sealed messages bound to the exchange and direction.',
      '<code>sealed</code>: send a sealed request through the application’s envelope and open the answer (<code>call</code>), and answer one only for the exchange’s own, Noise-authenticated peer (<code>serve</code>).',
      '<code>invite</code>: invitation automation: connect, offers answered on the spot or kept for the owner, poll and settle, crossing offers settled on one exchange, trust on first use and impostor warnings.',
      '<code>identity</code>, <code>user</code>, <code>sync</code>, <code>shard</code>, <code>addr</code>: node identities, user certificates, revocations, cards and link grants, the linked-node sync key, dark-shard blobs and address helpers.',
    ],
    dependsOn: ['keys'],
    usedBy: ['Morph', 'Muninn', 'weirdnet-relay'],
    origin: 'Muninn',
    example: '''use weirdnet_net::{WEIRDNET, Keypair, exchange::Token, profile::invite_scope};

let (anna, ben) = (Keypair::generate_ed25519(), Keypair::generate_ed25519());
let p = &WEIRDNET;
let (offer, secret) = p.offer(&anna, "anna", vec![], invite_scope("garden", "member"), 0, 60_000).unwrap();
let link = p.link(&p.offer_token(&offer).unwrap());
let Token::Offer(seen) = p.parse_token(&link).unwrap() else { unreachable!() };
p.verify_offer(&seen, 1).unwrap();
let (answer, on_ben) = p.answer(&ben, &seen, "ben", vec![], 1).unwrap();
let on_anna = p.complete(&answer, &offer, &secret[..]).unwrap();
assert_eq!(on_anna.short_code, on_ben.short_code);''',
    notes: 'Not audited. Tested over libp2p’s in-memory transport with real Noise, Yamux and request-response. See <code>SECURITY.md</code> in the repository for what the crate enforces and what it leaves to the application.',
  ),
  Crate(
    slug: 'relay',
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
      'A names server (<code>/weirdnet/names/1</code>) for signed peer records, kept in the same database.',
      'An info page: HTML at <code>/</code> and <code>/.well-known/weirdnet-relay.json</code>.',
      'A TOML config file, flags and environment variables; structured logs; a hardened systemd unit.',
    ],
    dependsOn: ['net', 'storage'],
    usedBy: ['WeirdBrains public relays', 'self-hosters'],
  ),
  Crate(
    slug: 'tls',
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
  ),
  Crate(
    slug: 'keys',
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
    usedBy: ['weirdnet-net', 'Morph'],
    origin: 'Muninn',
    notes: 'Not audited. The shard checksum catches typos, not forgery: a forged share combines into a wrong key, which verification then rejects.',
  ),
  Crate(
    slug: 'storage',
    group: 'Keys and storage',
    tagline: 'SQLCipher databases opened with a caller-supplied raw key, migrations, savepoints, sync change log.',
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
    ],
    usedBy: ['Morph', 'weirdnet-relay'],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'update',
    group: 'Building blocks',
    tagline: 'Signed update metadata: org roots, manifests, freshness, verification, targeting, rollouts, consent, boot health.',
    about: [
      'Signed update metadata and client-side checks for Weirdnet apps. Salty Gull, the WeirdBrains over-the-air update service, builds on it; nothing here is Flutter-specific.',
      'Updates are never forced: the consent policy asks for each update by default, and new capabilities always ask.',
    ],
    parts: [
      '<b>Org roots</b>: k-of-n Ed25519 root keys, release-key delegations scoped to apps and channels, optional timestamp keys, pinned by a BLAKE3 fingerprint.',
      '<b>Manifests</b>: app, channel, seq, kind (assets, Wasm, full package, store notices), per-file size and BLAKE3, targeting, staged rollout, rollback target, expiry.',
      '<b>Envelopes</b>: signatures over the exact CBOR payload with the domains <code>weirdnet-update/v1/root|manifest|freshness</code>.',
      '<b>Client</b>: the acceptance rule and anti-rollback state. <b>Targeting and rollout</b> on the device, no install id needed.',
      '<b>Consent</b> and <b>boot health</b>: trial boots, commit on ready, local rollback after two failed boots.',
    ],
    usedBy: ['Salty Gull'],
    origin: 'Salty Gull',
  ),
  Crate(
    slug: 'accounts',
    tagline: 'Argon2id passwords, hashed tokens, name rules, per-client rate limits, org-scoped API keys.',
    about: [
      'Account building blocks for WeirdBrains services, extracted from TAUR and shared with Salty Gull. Storage stays with the application; the crate holds the rules and the cryptography and never opens a database.',
    ],
    parts: [
      '<code>password</code>: Argon2id hashes (PHC strings), verification and a minimum-length rule.',
      '<code>token</code>: 256-bit random bearer tokens stored only as SHA-256, compared in constant time.',
      '<code>names</code>: AUR-style user names and a light email check.',
      '<code>ratelimit</code>: in-memory fixed-window limits per client and class, with <code>X-Forwarded-For</code> honoured only from trusted proxies.',
      '<code>apikeys</code>: org-scoped API keys shown once and stored as SHA-256, with scopes, bindings, expiry and revocation.',
    ],
    usedBy: ['TAUR'],
    origin: 'TAUR',
  ),
  Crate(
    slug: 'mcp',
    tagline: 'A transport-agnostic Model Context Protocol tools server and stdio bridge.',
    about: [
      'A stateless MCP tools server extracted from TAUR and shared with Salty Gull. The HTTP route stays in the app’s server.',
    ],
    parts: [
      '<code>Server::handle</code>: one JSON-RPC 2.0 message or batch plus the caller’s bearer token in, the reply out: <code>initialize</code> with version negotiation, <code>ping</code>, <code>tools/list</code>, <code>tools/call</code>.',
      '<code>ToolSpec</code> / <code>Param</code>: static tool tables with input schemas and read-only, destructive and open-world hints.',
      'The app implements <code>Tools::call</code>; failures become <code>isError</code> results. <code>args</code>: argument getters with uniform messages.',
      '<code>stdio::bridge</code>: the <code>&lt;app&gt;ctl mcp</code> loop that forwards stdio lines to a remote <code>/mcp</code>.',
    ],
    usedBy: ['TAUR'],
    origin: 'TAUR',
  ),
  Crate(
    slug: 'plugin',
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
    example: '''use weirdnet_plugin::prelude::*;

pub fn run(host: &Host) -> Result<View> {
    let bars = host.input()?;
    let close = bars.f64("close")?;
    Ok(View::chart("close").x("timestamp", bars.f64("timestamp")?, true).line("close", close))
}
weirdnet_plugin::plugin!(run);''',
  ),
  Crate(
    slug: 'code-spaces',
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
    tagline: 'A TOML theme format: dark and light variants, semantic colour roles, contrast checks.',
    about: [
      'A theme format for terminal and GUI front ends: one TOML file per theme with <code>[meta]</code>, <code>[dark]</code> and <code>[light]</code> tables, 21 semantic colour roles, seven built-in palettes, WCAG contrast checks and lightness-inverted variants.',
    ],
    parts: [
      'Storage is yours: <code>load</code>, <code>save</code>, <code>list</code>, <code>materialize</code> and <code>reset</code> work through the <code>ThemeDirs</code> trait.',
      '<code>Mode::{Light, Dark, System}</code>, resolved from the terminal background or the OS preference.',
      '<code>VariantDef::resolve(role)</code> gives RGB and <code>to_hex</code> gives <code>#rrggbb</code>; optional ratatui colours by colour depth.',
    ],
    origin: 'Muninn',
  ),
];

Crate crateBySlug(String slug) => crates.firstWhere((c) => c.slug == slug);
