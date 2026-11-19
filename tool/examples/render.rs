// A table and a chart (described in JSON) drawn to PNG bytes.
use weirdnet_render::{Limits, Table, json_png, table_png};

fn main() {
    let t = Table { columns: vec!["name".into(), "temp".into()], rows: vec![vec!["north".into(), "21.5".into()]] };
    let png = table_png(&t, &Limits::default()).unwrap();
    assert_eq!(&png[1..4], b"PNG");
    let png = json_png(r#"{"series":[{"name":"t","values":[1,2,3]}]}"#, &Limits::default()).unwrap();
    assert_eq!(&png[1..4], b"PNG");
}
