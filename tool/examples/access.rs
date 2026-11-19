// A public, members-only resource: a member may write (sealed), a stranger must join first.
use weirdnet_access::*;

fn main() -> Result<()> {
    let mut catalog = Catalog::core();
    catalog.add("files.read", "download files", false)?;
    catalog.add("files.write", "upload and change files", false)?;
    catalog.imply("files.write", &["files.read"])?;
    let roles = presets::ranked(&catalog, &["files.write"], &["files.read"])?;

    let settings = Settings { visibility: Visibility::Public, access: Access::Gated };
    // From weirdnet-net: the node cert, the trust list, and `check_presented` on the membership.
    let member = Facts { user: Some("ulf".into()), membership_role: Some("user".into()), ..Default::default() };
    assert!(matches!(decide(&catalog, &roles, settings, &member, "files.write"), Decision::Allow { transport: Transport::Sealed, .. }));
    let stranger = Facts { user: Some("someone".into()), ..Default::default() };
    assert_eq!(decide(&catalog, &roles, settings, &stranger, "files.read"), Decision::JoinFirst);
    Ok(())
}
