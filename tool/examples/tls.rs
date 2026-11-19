// Serve TLS now (self-signed), then let ACME replace the certificate in the background.
use std::sync::Arc;
use weirdnet_tls::*;

#[tokio::main]
async fn main() -> weirdnet_tls::Result<()> {
    let names = vec!["example.com".to_string(), "www.example.com".to_string()];
    let resolver = Arc::new(Resolver::with_self_signed(&names)?);
    let mut cfg = AcmeConfig::new("main", names);
    cfg.contact = vec!["admin@example.com".into()];
    let acme = Arc::new(Acme::new(cfg, Arc::new(FileStore::new("/var/lib/myapp/tls")), resolver.clone())?);
    acme.load()?;
    let _renewer = acme.clone().spawn();
    let _tls = resolver.server_config(&[b"h2", b"http/1.1"])?; // hand to tokio-rustls, hyper, ...
    Ok(())
}
