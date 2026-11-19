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
    version: '0.6.0',
    group: 'Network',
    tagline: 'The libp2p node, streams, app calls, key exchanges, invitations, sealed messaging, identities and certificates.',
    about: [
      'Peer-to-peer networking for applications that keep their own data. The application brings its own request and response types, its own storage and its own policy; the crate brings the wire.',
      'Every identifier on the wire or under a signature comes from a <code>Profile</code>. <code>WEIRDNET</code> is the default (<code>/weirdnet/net/1</code>, <code>wnet-x1-offer:</code>, port 4747 and so on). Key cryptography is not here: every derivation, seal and open goes through <code>weirdnet-keys</code>.',
    ],
    parts: [
      '<code>node</code>: a <code>Node&lt;Q, R&gt;</code> over TCP and QUIC (or an in-memory transport for tests) with Noise and Yamux, mDNS, Kademlia, identify, ping, a relay client and an opt-in relay server, DCUtR hole punching and AutoNAT. The swarm runs on its own thread; the handle is blocking. Requests are the application’s <code>Q</code>, answers its <code>R</code> (CBOR).',
      '<code>names</code>: signed peer records and withdrawals, a names (rendezvous) server, checked DHT records under <code>SHA-256("weirdnet/peer/" + user id)</code>, <code>_weirdnet.&lt;name&gt;</code> TXT bindings, and key-only dialing (<code>request_key</code>, <code>request_user</code>).',
      '<code>app</code>: app calls for <code>weirdnet-&lt;app&gt;://</code> URLs. <code>Node::serve_app</code> serves an app (and announces it through identify), <code>Node::resolve_app</code> finds the peers serving it for a peer id, user id or bound name, and <code>Node::app_call</code> sends an HTTP-like request with a streamed body and gets a streamed response, directly or through relays. One stream per call on <code>/weirdnet/app/1</code> with CBOR heads; heads capped at 16 KiB, bodies uncapped, a 60-second idle timeout.',
      '<code>stream</code>: byte streams with no size cap, backpressure and per-protocol limits, moving between relayed and direct paths without losing a byte; sealed streams bound to an exchange.',
      '<code>exchange</code>: signed offers and answers (Ed25519 node keys, fresh X25519 keys), the derived exchange key, a ten-digit short code and a fingerprint to compare out of band, tokens and links, scopes with an expiry, sealed messages bound to the exchange and direction.',
      '<code>sealed</code>: send a sealed request through the application’s envelope and open the answer (<code>call</code>), and answer one only for the exchange’s own, Noise-authenticated peer (<code>serve</code>).',
      '<code>invite</code>: invitation automation: connect, offers answered on the spot or kept for the owner, poll and settle, crossing offers settled on one exchange, trust on first use and impostor warnings.',
      '<code>identity</code>, <code>user</code>, <code>sync</code>, <code>shard</code>, <code>addr</code>: node identities, user certificates, revocations, cards and link grants, the linked-node sync key, dark-shard blobs and address helpers.',
    ],
    dependsOn: ['keys'],
    usedBy: ['Morph', 'Muninn', 'weirdnet-relay', 'weirdnet-sync', 'weirdnet-device-link'],
    origin: 'Muninn',
    notes: 'Not audited. Tested over libp2p’s in-memory transport with real Noise, Yamux and request-response. See <code>SECURITY.md</code> in the repository for what the crate enforces and what it leaves to the application.',
  ),
  Crate(
    slug: 'relay',
    version: '0.5.0',
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
      'A names server (<code>/weirdnet/names/1</code>) for signed peer records, kept in the same database.',
      'An info page: HTML at <code>/</code> and <code>/.well-known/weirdnet-relay.json</code>.',
      'A TOML config file, flags and environment variables; structured logs; a hardened systemd unit.',
    ],
    dependsOn: ['net', 'storage', 'push', 'update'],
    usedBy: ['WeirdBrains public relays', 'self-hosters'],
  ),
  Crate(
    slug: 'tls',
    version: '0.2.0',
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
    version: '0.1.1',
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
    version: '0.1.0',
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
    usedBy: ['Morph', 'weirdnet-relay', 'weirdnet-tls'],
    origin: 'Muninn',
  ),
  Crate(
    slug: 'update',
    version: '0.2.0',
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
    usedBy: ['Salty Gull', 'weirdnet-relay'],
    origin: 'Salty Gull',
  ),
  Crate(
    slug: 'accounts',
    version: '0.1.0',
    group: 'Identity and access',
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
    usedBy: ['TAUR', 'Salty Gull'],
    origin: 'TAUR',
  ),
  Crate(
    slug: 'mcp',
    version: '0.1.0',
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
    slug: 'agent',
    version: '0.1.0',
    tagline: 'The agent runtime: a model-agnostic loop with streaming and cancel, tool sources, tiered approvals, research budgets and traces with citation checks.',
    about: [
      'The shared agent loop for WeirdBrains apps; Morph’s Companions are its first user. The app brings the model, the tools and the approval UI; the crate runs each task, enforces the policy and budget, and records what happened. It has no app-specific types.',
      'Tool results reach the model wrapped as untrusted data, and nothing inside them can widen a permission. Local inference (<code>weirdnet-model</code>, with its <code>agent</code> feature) plugs in through its <code>ModelBackend</code> trait; MCP client transports (<code>weirdnet-mcp</code>) and remote agents over <code>weirdnet-net</code> plug in through its traits <span class="tag wip">in progress</span>.',
    ],
    parts: [
      '<code>AgentSession::run</code>: one task. Calls the <code>ModelBackend</code>, checks each tool call against the <code>Policy</code>, asks the app’s <code>Approver</code> when needed, charges the budget, runs the tool with a timeout and a <code>CancelToken</code>, and streams <code>AgentEvent</code>s: text, approvals, skipped-approval notices, tool start and finish, trace steps.',
      '<code>Tool</code>, <code>ToolSource</code>, <code>ToolRegistry</code>: in-process tools now, MCP servers and remote nodes as further sources. Per-source and per-tool switches; a tier override can only make a tool stricter.',
      '<code>Policy</code>: tiers <code>Read</code> (attached content), <code>Navigate</code>, <code>Research</code>, <code>Interact</code> and <code>Never</code>; per-agent, per-site <code>Off</code>, <code>Ask</code> and <code>Act</code>; approvals for once or for the task; revocable “Always allow” for navigate (a site or everywhere) and research (optionally one provider), for one agent or all. Off always wins, signed-in research is never covered by Always allow, and an all-agents allow covers an outside agent only after its first approval.',
      '<code>Budget</code>: searches, pages (with extensions), concurrency, per-page and per-task time, tokens kept per page, model steps. Defaults: 3 searches, 12 pages (+5), 2 at a time, 15 s a page, 90 s a task.',
      '<code>Trace</code>, <code>Citation</code>: every search, fetch, tool call, approval and notice is a step with its agent, node and session (logged out or signed in). <code>validate_citations</code> rejects a cited URL that none of its steps fetched; a citation without a step is never shown.',
      'Serde on everything that is stored or synced. The <code>testing</code> feature has a scripted model, approver and closure tools.',
    ],
    usedBy: ['Morph (Companions, in progress)'],
    dependsOn: [],
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-agent">crates.io</a> (<a href="https://docs.rs/weirdnet-agent/0.1.0">docs.rs</a>). The API may change while Morph’s Companions are built on it.',
  ),
  Crate(
    slug: 'model',
    version: '0.1.0',
    tagline: 'Local models: consent-gated Hugging Face GGUF downloads with resume and checksum, a Gemma 4 catalog, and streaming llama.cpp inference on a worker thread with cancel.',
    about: [
      'The shared local-model layer for WeirdBrains apps. It downloads a GGUF only after the user agrees to that exact model, loads it with llama.cpp and streams tokens from one worker thread that any thread can cancel. It was extracted from Mouser’s <code>mouser-llm</code> and has no app-specific types; switching Mouser over to it is a follow-up for Mouser’s owner <span class="tag wip">in progress</span>.',
      'llama.cpp and the agent backend are optional features, so a build that only needs downloads and the catalog has no native dependencies.',
    ],
    parts: [
      '<code>catalog</code>: Gemma 4 E2B (about 2.8 GB, for phones and small laptops) and E4B (about 4.6 GB, for desktop) as Q4_0 GGUFs from <code>ggml-org</code> on Hugging Face, with pinned size and SHA-256. <code>default_for(Device)</code> picks one.',
      '<code>ModelStore</code>, <code>download</code>: a cache directory (<code>WEIRDNET_MODEL_DIR</code> overrides it), a <code>Consent</code> that must name the model, <code>Progress</code> callbacks, <code>.part</code> resume and a checksum check before the file is kept. Nothing downloads without consent.',
      '<code>hf</code>: lists a repo’s GGUF files and sizes for a model picker.',
      '<code>prompt</code>: chat turns rendered through the model’s own chat template, and a streaming parser that turns <code>&lt;tool_call&gt;</code> tags into tool calls.',
      '<code>Worker</code>, <code>Engine</code>: the engine lives on one thread; <code>generate</code> returns a <code>Generation</code> that streams <code>Chunk</code>s and cancels from any thread. Tests use a mock engine.',
      '<code>llama</code> feature: <code>LlamaEngine</code> on llama.cpp (CPU; needs cmake and a C++ compiler). <code>vulkan</code> and <code>metal</code> add GPU offload.',
      '<code>agent</code> feature: <code>LocalModel</code> implements <code>weirdnet_agent::ModelBackend</code>, streaming text to the agent loop and returning parsed tool calls.',
    ],
    usedBy: ['Morph (Companions, in progress)'],
    dependsOn: ['agent'],
    example: r'''use std::sync::Arc;
use weirdnet_model::{agent::LocalModel, catalog, llama::{LlamaEngine, LlamaOptions}, ModelStore, Worker};

let spec = catalog::default_for(catalog::Device::Desktop);
let store = ModelStore::from_env();
// After the user agrees: weirdnet_model::download(&store, &spec, &consent, &mut on_progress)?; // on_progress returns false to cancel
let worker = Arc::new(Worker::spawn(LlamaEngine::loader(store.path(&spec), LlamaOptions::default())));
let model = LocalModel::new(spec.id.clone(), worker); // a weirdnet_agent::ModelBackend''',
    notes: 'Version 0.1.0 is on <a href="https://crates.io/crates/weirdnet-model">crates.io</a> (<a href="https://docs.rs/weirdnet-model/0.1.0">docs.rs</a>). The API may change while Morph’s Companions are built on it. Real-model tests are ignored by default; CI builds llama.cpp on CPU only.',
  ),
  Crate(
    slug: 'plugin',
    version: '0.1.0',
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
    version: '0.1.0',
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
    version: '0.1.0',
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
    version: '0.1.0',
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
    version: '0.1.0',
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
    version: '0.1.0',
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
  Crate(
    slug: 'sync',
    version: '0.3.1',
    group: 'Network',
    status: Status.fresh,
    tagline: 'Linked-device sync: hybrid logical clocks, an op log, LWW and OR-set merge, sealed pages, a device roster with key rotation on revoke.',
    about: [
      'Sync between one person’s devices over <code>weirdnet-net</code>: a hybrid logical clock, an append-only per-node op log, last-writer-wins registers, OR-set merge, tombstone garbage collection, pages sealed under a typed <code>SyncKey</code>, a device roster with self-issued node certificates and revocation, and the <code>/weirdnet/sync/1</code> pull protocol.',
      'Record types (bookmarks, history, settings, notes) and persistence stay in the application; <code>OpLog</code> is the in-memory log it snapshots.',
    ],
    parts: [
      '<code>Hlc</code>, <code>NodeId</code>: hybrid logical clocks with <code>tick</code> and <code>receive</code>.',
      '<code>OpLog</code>, <code>LogEntry</code>: per-node sequences, per-(node, type) cursors, pages and <code>integrate</code>.',
      '<code>lww</code>, <code>OrSet</code>, <code>edit_vs_delete</code>, <code>can_gc_tombstone</code>, <code>folder_cycle</code>: the merge rules.',
      '<code>SyncState</code>, <code>SyncHandler</code>, <code>start_node</code>, <code>pull_from</code>: the protocol over a weirdnet-net node.',
      '<code>Roster</code>, <code>DeviceKey</code>, <code>Rotation</code>, <code>KeyChain</code>, <code>EpochKeys</code>, <code>KeyStatus</code>: certificates, revocation, key rotation and re-admission.',
      '<code>sync_key</code>, <code>seal_page</code>, <code>open_page</code>: typed keys and sealed pages.',
    ],
    dependsOn: ['net', 'keys'],
    usedBy: ['Morph (bookmarks and linked devices)'],
    notes: 'Not audited. The README’s status line still says key rotation is unreleased; it shipped in 0.3.0.',
  ),
  Crate(
    slug: 'push',
    version: '0.1.0',
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
    version: '0.1.0',
    group: 'Identity and access',
    tagline: 'Move a Weirdnet identity to another device over a QR offer, a 6-digit code check and a sealed transfer.',
    about: [
      '<code>weirdnet-device-link/v1</code>: move a user identity to another device of the same person without typing its recovery words. Built in Morph as “Login over QR” and moved here unchanged.',
    ],
    parts: [
      '<code>offer</code>: <code>Offer</code>, <code>VerifiedOffer</code>, <code>encode_link</code>, <code>decode_link</code>, <code>offer_addrs</code>.',
      '<code>invite</code>: the reverse direction, where the existing device shows the QR.',
      '<code>session</code>: <code>Host</code> and <code>Sender</code>, both sides without the network, and <code>make_transfer</code>.',
      '<code>net</code>: <code>HostNode</code> and <code>Pairing</code> over weirdnet-net on <code>/weirdnet/link/1</code>.',
      '<code>wire</code>: <code>LinkRequest</code>, <code>LinkReply</code>, <code>Transfer</code> (CBOR).',
    ],
    dependsOn: ['net', 'keys'],
    usedBy: ['Morph'],
    origin: 'Morph',
  ),
  Crate(
    slug: 'access',
    version: '0.1.1',
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
    version: '0.1.0',
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
    version: '0.1.0',
    group: 'Identity and access',
    binary: true,
    tagline: 'Holds and rotates Weirdnet signing keys, signs scheme records, and builds the signed canonical list.',
    about: [
      'The maintainer’s CLI for Weirdnet signing keys and the records they sign: the WeirdBrains root key, prefix and scheme records for weirdnet-schemes, countersignatures for reserved prefixes, and the canonical list.',
    ],
    parts: [
      '<code>key new|show|check|rotate</code>: passphrase-sealed Ed25519 key files.',
      '<code>prefix</code>, <code>scheme</code>: sign registrations and withdrawals.',
      '<code>countersign --as root|transfer</code>, <code>list</code>, <code>verify</code>.',
    ],
    dependsOn: ['schemes'],
    usedBy: ['WeirdBrains (the root key)', 'app publishers'],
  ),
  Crate(
    slug: 'ext',
    version: '0.1.0',
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
    version: '0.1.0',
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
    version: '0.1.0',
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
