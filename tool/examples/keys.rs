// A master key as 24 words, as 2-of-3 Shamir shards, and sealing with associated data.
use weirdnet_keys::{Key32, Profile, open, seal, shards, words};

fn main() -> weirdnet_keys::Result<()> {
    let master = Key32::random()?;

    let phrase = words::to_words(&master)?;
    assert_eq!(words::from_words(&phrase)?.0, master.0);

    let parts = shards::split(&Profile::WEIRDNET, &master, 2, 3)?;
    let two = [parts[0].to_string(), parts[2].to_string()];
    assert_eq!(shards::combine(&Profile::WEIRDNET, &two)?.0, master.0);

    let sealed = seal(&master, b"hello", b"note:1")?;
    assert_eq!(&open(&master, &sealed, b"note:1")?[..], b"hello");
    assert!(open(&master, &sealed, b"note:2").is_err()); // wrong associated data
    Ok(())
}
