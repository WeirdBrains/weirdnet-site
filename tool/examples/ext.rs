// What the user granted an extension, checked the way the host's broker checks each call.
use weirdnet_ext::{Capability, Grants};

fn main() {
    let mut grants = Grants(vec![Capability::new("storage"), Capability::with_patterns("net.fetch", &["https://api.example.com/*"])]);
    assert!(grants.allows("net.fetch", Some("https://api.example.com/v1/items")));
    assert!(!grants.allows("net.fetch", Some("https://elsewhere.example.org/")));
    grants.revoke("net.fetch");
    assert!(!grants.allows("net.fetch", Some("https://api.example.com/v1/items")));
}
