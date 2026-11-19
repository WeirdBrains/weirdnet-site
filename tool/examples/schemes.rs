// First-party scheme names, the reserved prefix, and parsing an invite link.
use weirdnet_schemes::{Action, Link, names};

fn main() -> weirdnet_schemes::Result<()> {
    assert_eq!(names::first_party("morph"), "weirdnet-morph");
    assert!(names::is_reserved("weirdnet-morph")); // only on the WeirdBrains-signed list
    let link = Link::parse("weirdnet-morph://join/abc123")?;
    assert_eq!(link.action, Action::Join("abc123".into()));
    Ok(())
}
