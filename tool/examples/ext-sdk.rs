// An extension: connect to the host that started it, log, and handle the app's events.
use weirdnet_ext_sdk::{Event, Extension, Level};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let ext = Extension::connect(env!("CARGO_PKG_VERSION")).await?;
    ext.log(Level::Info, "started", &[]).await?;
    let e = ext.clone();
    ext.run(move |ev| {
        let e = e.clone();
        async move {
            if let Event::App { kind, payload } = ev {
                let _ = e.call("morph.ext.v1.Notes", "Append", payload).await;
                let _ = kind;
            }
        }
    })
    .await?;
    Ok(())
}
