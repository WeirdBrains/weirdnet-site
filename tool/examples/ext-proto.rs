// The contract's constants: how a host hands an extension its socket and one-time token.
use weirdnet_ext_proto::{API_VERSION, ENV_SOCKET, ENV_TOKEN, v1};

fn main() {
    println!("weirdnet.ext.v1, API {API_VERSION}: socket in ${ENV_SOCKET}, token in ${ENV_TOKEN}");
    let cap = v1::Capability { name: "storage".into(), patterns: vec![] };
    println!("{cap:?}");
}
