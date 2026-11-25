// Open encrypted databases with raw keys, keep a hot standby current, and protect records
// for seven years.
use std::sync::Arc;
use weirdnet_storage::replicate::{Manual, Primary, ReplError, Standby};
use weirdnet_storage::retention::{self, Period, Policy};
use weirdnet_storage::open;

const MIGRATIONS: &[&str] = &["CREATE TABLE invoices (id INTEGER PRIMARY KEY, at_ms INTEGER NOT NULL, total REAL NOT NULL)"];

fn main() -> Result<(), ReplError> {
    let dir = std::env::temp_dir().join("weirdnet-storage-example");
    let _ = std::fs::remove_dir_all(&dir);
    // In an app: keys from weirdnet-keys' keyring, never constants. Each node has its own.
    let (primary_key, standby_key) = ([7u8; 32], [8u8; 32]);

    // The primary records every change in a hash-chained log, in the same transaction.
    let leader = Manual::granted(1); // or a weirdnet-sync lease with the `lease` feature
    let mut primary = Primary::open(open(&dir.join("primary.db"), Some(&primary_key), "primary")?, "node-a", Arc::new(leader))?;
    primary.migrate(MIGRATIONS, MIGRATIONS.len())?;
    let policy = Policy::new("invoices", "at_ms", Period::years(7)).immutable();
    let now_ms = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_millis() as i64;
    let protect = retention::protect_sql(primary.connection(), &policy, now_ms)?;
    primary.schema(&protect)?;
    primary.write(|tx| -> Result<(), ReplError> {
        tx.execute("INSERT INTO invoices (at_ms, total) VALUES (?1, 42.0)", [now_ms])?;
        retention::seal(tx, "invoices")?;
        Ok(())
    })?;

    // A hot standby pulls the log (here in process; over weirdnet-net with `replication-service`).
    let mut standby = Standby::open(open(&dir.join("standby.db"), Some(&standby_key), "standby")?, "node-b")?;
    standby.catch_up(&primary)?;
    assert!(retention::verify(standby.connection())?.is_intact());

    // A young invoice can't be deleted, on either node.
    assert!(primary.write(|tx| -> Result<usize, ReplError> { Ok(tx.execute("DELETE FROM invoices", [])?) }).is_err());
    Ok(())
}
