// Keep a credential sealed, let a bot use it without seeing it, approve one operator to
// retrieve it, refuse a dry-run caller, and check the audit log.
use std::sync::Arc;
use weirdnet_vault::*;

fn main() -> Result<()> {
    let policy = Arc::new(RolePolicy::with_example_roles());
    policy.define_role("operator", &[Action::List, Action::ReadMeta, Action::Reveal]);
    let tenant = Scope::new(["tenant-7"])?;
    let account = tenant.child("provider-a")?;
    policy.assign("admin", &Scope::root(), "admin")?;
    policy.assign("bot", &tenant, "trader")?;
    policy.assign("ops", &tenant, "operator")?;

    // A real server opens a file: Vault::unlock (password), open_with_keystore or open_with_key.
    let vault = Vault::open_in_memory(policy, VaultOptions::new())?;
    let admin = Caller::live("admin");
    let key = vault.create(&admin, NewSecret::new(account.clone(), "api", Environment::Live).kind("api-key"), b"key:secret")?;

    // The bot may use the credential; it never gets the plaintext back.
    vault.grant(&admin, GrantTarget::Scope(account), "bot", &[GrantAction::Use], None)?;
    let len = vault.use_secret(&Caller::live("bot"), &key.id, |s| s.len())?;
    println!("signed with {len} bytes of credentials");
    println!("dry-run: {}", vault.use_secret(&Caller::test("bot"), &key.id, |_| ()).unwrap_err());
    println!("bot reveal: {}", vault.reveal(&Caller::live("bot"), &key.id).unwrap_err());

    // An approved operator may retrieve it.
    vault.grant(&admin, GrantTarget::Secret(key.id.clone()), "ops", &[GrantAction::Reveal], None)?;
    println!("ops retrieved {} bytes", vault.reveal(&Caller::live("ops"), &key.id)?.len());

    let head = vault.verify_audit()?;
    println!("audit log verified: {} records", head.seq);
    for r in vault.audit(&admin, &AuditQuery::new().action(Action::Reveal))? {
        println!("#{} {} {} {}", r.seq, r.actor, r.action, r.outcome.as_str());
    }
    Ok(())
}
