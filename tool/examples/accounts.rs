// Passwords, bearer tokens and user names, with the storage left to the app.
use weirdnet_accounts::{names::NamePolicy, password, token};

fn main() -> weirdnet_accounts::Result<()> {
    password::check_length("correct horse battery", 12)?;
    let hash = password::hash_password("correct horse battery")?; // a PHC string to store
    assert!(password::verify_password("correct horse battery", &hash));

    NamePolicy::AUR.validate("anna")?;

    let session = token::random_token(); // shown to the client once
    let stored = token::token_hash(&session); // all the database keeps
    assert!(token::hashes_equal(&token::token_hash(&session), &stored));
    Ok(())
}
