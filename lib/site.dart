/// Public URLs and copy used across the Weirdnet site.
library;

const siteUrl = 'https://net.weirdbrains.com';
const siteTitle = 'Weirdnet';
const siteTagline = 'The peer-to-peer net under WeirdBrains apps';
const siteDescription =
    'Weirdnet is a set of open-source Rust crates for peer-to-peer apps: a libp2p node, '
    'signed key exchanges and invitations, sealed messaging, identities, relays, and the '
    'building blocks Morph, Muninn, TAUR and Salty Gull share.';
const orgUrl = 'https://github.com/WeirdBrains';
const mainSiteUrl = 'https://www.weirdbrains.com';
const morphSiteUrl = 'https://morph.weirdbrains.com';
const relayRepoUrl = 'https://github.com/WeirdBrains/weirdnet-relay';

String repoUrl(String crate) => 'https://github.com/WeirdBrains/$crate';
String cratesIoUrl(String crate) => 'https://crates.io/crates/$crate';
String docsRsUrl(String crate) => 'https://docs.rs/$crate';
