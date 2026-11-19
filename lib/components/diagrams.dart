/// Diagrams as inline SVG (no script, so they render in the static HTML).
library;

const _defs = '''
<defs>
  <linearGradient id="dg" x1="0" y1="0" x2="1" y2="0">
    <stop offset="0" stop-color="#facc15"/><stop offset="0.5" stop-color="#a855f7"/><stop offset="1" stop-color="#ec4899"/>
  </linearGradient>
  <marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0 0 L10 5 L0 10 z" fill="#c084fc"/>
  </marker>
  <marker id="ahy" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0 0 L10 5 L0 10 z" fill="#facc15"/>
  </marker>
</defs>''';

String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

String _box(num x, num y, num w, num h, String title, [String sub = '', String stroke = 'url(#dg)']) {
  final cx = x + w / 2;
  final ty = sub.isEmpty ? y + h / 2 + 6 : y + h / 2 - 3;
  return '<rect x="$x" y="$y" width="$w" height="$h" rx="10" fill="#00224d" stroke="$stroke" stroke-width="1.6"/>'
      '<text x="$cx" y="$ty" text-anchor="middle" fill="#fff" font-size="16" font-weight="650">${_esc(title)}</text>'
      '${sub.isEmpty ? '' : '<text x="$cx" y="${ty + 20}" text-anchor="middle" fill="#b8bec7" font-size="12.5">${_esc(sub)}</text>'}';
}

String _arrow(num x1, num y1, num x2, num y2, [String label = '', bool dashed = false, String color = '#c084fc']) {
  final m = color == '#facc15' ? 'ahy' : 'ah';
  final mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
  return '<line x1="$x1" y1="$y1" x2="$x2" y2="$y2" stroke="$color" stroke-width="1.8" ${dashed ? 'stroke-dasharray="6 5"' : ''} marker-end="url(#$m)"/>'
      '${label.isEmpty ? '' : '<text x="$mx" y="${my - 8}" text-anchor="middle" fill="#dfe3ea" font-size="12.5">${_esc(label)}</text>'}';
}

String _svg(int w, int h, String body, String caption) =>
    '<figure class="diagram"><svg viewBox="0 0 $w $h" font-family="Inter, ui-sans-serif, system-ui, sans-serif" role="img" aria-label="${_esc(caption)}">$_defs$body</svg>'
    '<figcaption>${_esc(caption)}</figcaption></figure>';

/// Apps over the crates over libp2p.
final overviewDiagram = _svg(
  960,
  360,
  '${_box(30, 20, 170, 60, 'Morph', 'browser')}${_box(220, 20, 170, 60, 'Muninn', 'data workspace')}'
      '${_box(410, 20, 170, 60, 'TAUR', 'package server')}${_box(600, 20, 170, 60, 'Salty Gull', 'app updates')}'
      '${_box(790, 20, 140, 60, 'Your app')}'
      '<text x="480" y="112" text-anchor="middle" fill="#b8bec7" font-size="13">apps bring their own data, storage, policy and /app/... protocols</text>'
      '${_box(30, 130, 210, 70, 'weirdnet-net', 'node, exchanges, sealed msgs')}${_box(260, 130, 210, 70, 'weirdnet-keys', 'keys, seal, words, shards')}'
      '${_box(490, 130, 210, 70, 'weirdnet-storage', 'SQLCipher, migrations')}${_box(720, 130, 210, 70, 'weirdnet-relay', 'relay + bootstrap')}'
      '<text x="480" y="232" text-anchor="middle" fill="#b8bec7" font-size="13">plus sync, push, access, accounts, agent, model, ext, schemes, update and 12 more crates</text>'
      '<rect x="30" y="255" width="900" height="80" rx="12" fill="#00122b" stroke="#00316b" stroke-width="1.6"/>'
      '<text x="480" y="288" text-anchor="middle" fill="#fff" font-size="16" font-weight="650">libp2p 0.57</text>'
      '<text x="480" y="312" text-anchor="middle" fill="#b8bec7" font-size="13">TCP · QUIC · Noise · Yamux · Kademlia · identify · mDNS · AutoNAT · circuit relay v2 · DCUtR</text>',
  'Weirdnet sits between the apps and libp2p: the apps keep their own data, the crates bring the wire and the cryptography.',
);

/// User key certifying node keys.
final identityDiagram = _svg(
  960,
  300,
  '${_box(360, 20, 240, 70, 'User key', 'Ed25519 · the person · 24 words')}'
      '${_box(40, 190, 240, 70, 'Desktop node', 'node key = PeerId')}${_box(360, 190, 240, 70, 'Phone node', 'node key = PeerId')}'
      '${_box(680, 190, 240, 70, 'Old laptop', 'revoked', '#ec4899')}'
      '${_arrow(420, 92, 180, 186, 'NodeCert')}${_arrow(480, 92, 480, 186, 'NodeCert')}${_arrow(540, 92, 780, 186, 'revocation', true, '#facc15')}'
      '<text x="480" y="290" text-anchor="middle" fill="#b8bec7" font-size="13">A Card = user public key + its node certificates; peers check it before treating a node as acting for a user.</text>',
  'Identities: one user key across apps, one node key per device, certificates and revocations signed by the user key.',
);

/// Offer, answer, short code.
final exchangeDiagram = _svg(
  960,
  420,
  '${_box(40, 20, 220, 60, 'Anna’s node')}${_box(700, 20, 220, 60, 'Ben’s node')}'
      '<line x1="150" y1="80" x2="150" y2="400" stroke="#00316b" stroke-width="2"/><line x1="810" y1="80" x2="810" y2="400" stroke="#00316b" stroke-width="2"/>'
      '<text x="150" y="112" text-anchor="middle" fill="#dfe3ea" font-size="13">offer: node key + fresh X25519 + scope + expiry</text>'
      '<text x="150" y="130" text-anchor="middle" fill="#b8bec7" font-size="12.5">signed (Ed25519)</text>'
      '${_arrow(160, 160, 800, 160, 'invitation link  weirdnet://join/…  (or connect over the node)')}'
      '<text x="810" y="196" text-anchor="middle" fill="#dfe3ea" font-size="13">verify signature, scope, expiry</text>'
      '${_arrow(800, 230, 160, 230, 'signed answer, bound to SHA-256 of the offer')}'
      '<text x="480" y="282" text-anchor="middle" fill="#fff" font-size="14" font-weight="600">both derive: exchange key = HKDF(X25519 secret, transcript)</text>'
      '<rect x="300" y="305" width="360" height="56" rx="10" fill="#00122b" stroke="#facc15" stroke-width="1.6"/>'
      '<text x="480" y="331" text-anchor="middle" fill="#facc15" font-size="20" font-weight="700" font-family="ui-monospace, monospace">12345-67890</text>'
      '<text x="480" y="352" text-anchor="middle" fill="#b8bec7" font-size="12">short code, compared out of band</text>'
      '${_arrow(296, 333, 160, 333, '', true, '#facc15')}${_arrow(664, 333, 800, 333, '', true, '#facc15')}',
  'A key exchange: a signed offer (the invitation), a signed answer bound to it, the same key and short code on both sides.',
);

/// Sealed request and answer.
final sealedDiagram = _svg(
  960,
  250,
  '${_box(30, 70, 200, 80, 'plaintext', 'app request')}'
      '${_box(290, 50, 260, 120, 'seal (XChaCha20-Poly1305)', 'key: exchange key')}'
      '<text x="420" y="152" text-anchor="middle" fill="#facc15" font-size="12" font-family="ui-monospace, monospace">AAD: msg|exchange|from|to</text>'
      '${_box(610, 70, 320, 80, 'serve() on the peer', 'opens only for the exchange’s own peer')}'
      '${_arrow(232, 110, 286, 110)}${_arrow(552, 110, 606, 110, 'app envelope')}'
      '<text x="480" y="225" text-anchor="middle" fill="#b8bec7" font-size="13">The answer is sealed the other way. Moving a message to another exchange or turning it around fails to open.</text>',
  'Sealed messaging over an exchange: the exchange id, both peer ids and the direction are bound as associated data.',
);

/// mDNS, Kademlia, relays found by provider record.
final discoveryDiagram = _svg(
  960,
  330,
  '<rect x="20" y="20" width="300" height="290" rx="14" fill="none" stroke="#00316b" stroke-dasharray="6 6"/>'
      '<text x="170" y="46" text-anchor="middle" fill="#b8bec7" font-size="13">local network</text>'
      '${_box(50, 70, 240, 60, 'Desktop', 'mDNS on')}${_box(50, 210, 240, 60, 'Laptop', 'mDNS on')}'
      '${_arrow(170, 132, 170, 206, 'mDNS: found, dial')}'
      '${_box(420, 40, 240, 70, 'Bootstrap / relay', 'Kademlia server')}${_box(420, 210, 240, 70, 'Relay', 'provides /weirdnet/relay/1')}'
      '${_box(740, 120, 200, 70, 'Phone', 'behind NAT')}'
      '${_arrow(292, 95, 416, 80, 'bootstrap')}${_arrow(540, 206, 540, 114, 'provider record')}'
      '${_arrow(736, 140, 664, 90, 'get_providers')}${_arrow(736, 170, 664, 235, 'reserve')}',
  'Finding peers: mDNS on the local network, Kademlia from bootstrap nodes, and relays announced under a provider key.',
);

/// Phone behind CGNAT reached through a relay, with a hole punch attempt.
final relayDiagram = _svg(
  960,
  330,
  '${_box(30, 120, 220, 80, 'Phone', 'carrier NAT, dial-out only')}${_box(370, 30, 220, 80, 'Home relay', 'weirdnet-relay')}'
      '${_box(710, 120, 220, 80, 'Desktop', 'anywhere')}'
      '${_arrow(150, 118, 380, 96, '1 · reservation')}${_arrow(812, 118, 582, 96, '2 · dial …/p2p-circuit/p2p/PHONE')}'
      '<path d="M250 175 C 420 260, 540 260, 706 175" fill="none" stroke="#facc15" stroke-width="2" stroke-dasharray="7 6" marker-end="url(#ahy)"/>'
      '<text x="480" y="268" text-anchor="middle" fill="#facc15" font-size="13">3 · DCUtR hole punch: a direct connection when NAT allows</text>'
      '<text x="480" y="300" text-anchor="middle" fill="#b8bec7" font-size="13">If punching fails the circuit stays: relays are the fallback that always works.</text>',
  'Relays and hole punching: reserve a slot, get dialed through the circuit, upgrade to a direct path when possible.',
);
