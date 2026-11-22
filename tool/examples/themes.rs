// Built-in themes, a derived optional role, and the colour depth for this terminal.
use weirdnet_themes::{ColorDepth, Mode, OPTIONAL_ROLES, builtin, resolve_variant, to_hex};

fn main() {
    let nord = builtin("nord").unwrap();
    assert_eq!(to_hex(nord.dark.resolve("bg").unwrap()), "#2e3440");
    // Nord sets no optional roles, so they are derived: links use `info`.
    assert_eq!(nord.dark.color("link"), nord.dark.resolve("info"));
    // Bragi sets them.
    let bragi = builtin("bragi").unwrap();
    let v = bragi.variant(resolve_variant(Mode::Dark));
    for role in OPTIONAL_ROLES {
        println!("{role}: {}", to_hex(v.color(role).unwrap()));
    }
    // NO_COLOR or TERM=dumb give ColorDepth::None; an explicit choice wins.
    assert_eq!(ColorDepth::detect_with(Some("none")), ColorDepth::None);
    println!("this terminal: {:?}", ColorDepth::detect());
}
