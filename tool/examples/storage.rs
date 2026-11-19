// Open an encrypted database with a raw key, migrate it, and write in a savepoint.
use weirdnet_storage::{StorageError, migrate, open};

const MIGRATIONS: &[&str] = &["CREATE TABLE notes (id INTEGER PRIMARY KEY, body TEXT NOT NULL)"];

fn main() -> Result<(), StorageError> {
    let dir = std::env::temp_dir().join("weirdnet-storage-example");
    let key = [7u8; 32]; // in an app: a key from weirdnet-keys' keyring, never a constant
    let mut conn = open(&dir.join("app.db"), Some(&key), "example database")?;
    migrate::<StorageError>(&mut conn, MIGRATIONS, MIGRATIONS.len(), |_, _| Ok(()))?;
    weirdnet_storage::begin(&conn, "add_note")?;
    conn.execute("INSERT INTO notes (body) VALUES (?1)", ["hello"])?;
    weirdnet_storage::release(&conn, "add_note")?;
    Ok(())
}
