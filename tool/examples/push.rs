// A sender seals a 96-byte wake for a device; only the device can open it, once.
use std::time::Duration;
use weirdnet_push::{PushKey, Reason, ReplayGuard, WakeHandle, wake};

fn main() -> weirdnet_push::Result<()> {
    let key = PushKey::generate(); // stays on the device
    let handle = WakeHandle::generate(); // shared, sealed, with the home relay and trusted peers

    let payload = wake::seal(&key.public(), &handle, Reason::MessageWaiting)?; // a sender
    let w = key.open(&handle, &payload)?; // the device
    let mut guard = ReplayGuard::new(Duration::from_secs(300), 1024);
    guard.check_now(&w)?;
    assert!(guard.check_now(&w).is_err()); // the same wake again is refused
    Ok(())
}
