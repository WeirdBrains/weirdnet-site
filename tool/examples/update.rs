// An org root (one root key, one release key), a signed manifest, and the client's check.
use weirdnet_update::{
    Client, Delegation, Domain, FileEntry, Root, Signed, SigningKey, Timestamp, UpdateBundle, UpdateKind, UpdateManifest,
    VerifyOptions, manifest::Labels,
};

fn main() -> weirdnet_update::Result<()> {
    let now = Timestamp::now();
    let (root_key, release_key) = (SigningKey::from_seed(&[1; 32]), SigningKey::from_seed(&[2; 32]));
    let root = Root {
        version: 1,
        org: "example".into(),
        keys: vec![root_key.public()],
        threshold: 1,
        release: vec![Delegation::any(release_key.public())],
        release_threshold: 1,
        timestamp: vec![],
        timestamp_threshold: 0,
        expires: None,
    };
    let root_env = Signed::sign(Domain::Root, &root, &[&root_key])?;

    let manifest = UpdateManifest {
        app: "com.example.notes".into(),
        channel: "stable".into(),
        update_id: "2026-11-18-ui".into(),
        seq: 1,
        kind: UpdateKind::Assets,
        version: semver::Version::new(1, 0, 1),
        base_releases: vec![],
        files: vec![FileEntry::describe("ui/main.rfw", b"widget bytes")],
        min_client: None,
        max_client: None,
        capabilities: vec![],
        labels: Labels::default(),
        targeting: None,
        rollout: None,
        rollback_of: None,
        notes: "New home screen".into(),
        created: now,
        expires: now.plus(7 * 86_400),
    };
    let bundle = UpdateBundle { roots: vec![], manifest: Some(Signed::sign(Domain::Manifest, &manifest, &[&release_key])?), freshness: None };

    // On the device: the app ships the root pin, and the client keeps anti-rollback state.
    let mut client = Client::new(root.pin(), &root_env, now)?;
    let update = client.verify("com.example.notes", "stable", &bundle, &VerifyOptions::new(now, semver::Version::new(1, 0, 0)))?;
    println!("accepted {} seq {}", update.manifest.update_id, update.manifest.seq);
    Ok(())
}
