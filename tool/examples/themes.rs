// A built-in theme's dark background as #rrggbb.
fn main() {
    let t = weirdnet_themes::builtin("nord").unwrap();
    assert_eq!(weirdnet_themes::to_hex(t.dark.resolve("bg").unwrap()), "#2e3440");
}
