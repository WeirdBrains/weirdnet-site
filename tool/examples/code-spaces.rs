// The trust hash an owner approves, and (with a Rust toolchain) building and loading.
use weirdnet_code_spaces::{self as cs, Lang, WEIRDNET};

fn main() -> cs::Result<()> {
    let src = "fast = sma(close, 10)";
    let hash = cs::trust_hash_of(&WEIRDNET, Lang::Math, src)?;
    assert!(cs::approved(&WEIRDNET, Lang::Math, src, Some(&hash)));
    assert!(!cs::approved(&WEIRDNET, Lang::Math, "fast = sma(close, 20)", Some(&hash))); // edited: ask again

    if std::env::var_os("BUILD_PLUGIN").is_some() {
        let env = cs::Env::new("/tmp/app/code", "/tmp/app/code/target");
        let built = cs::build(&WEIRDNET, &env, Lang::Math, src, &mut |line| eprintln!("{line}"))?;
        let _plugin = cs::load(&WEIRDNET, &built.path)?; // then plugin.run with the app's host table
    }
    Ok(())
}
