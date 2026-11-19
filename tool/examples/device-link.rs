// Both sides of a device link without the network (HostNode and Pairing carry it over
// weirdnet-net): offer, matching 6-digit codes, confirm, then the sealed transfer.
use weirdnet_device_link::{Host, HostStatus, LinkReply, Sender, decode_link};
use weirdnet_keys::Key32;
use weirdnet_net::Keypair;

const SCHEME: &str = "weirdnet-morph://";

fn main() {
    // The new device shows the offer as a QR code.
    let node = Keypair::generate_ed25519();
    let host = Host::new(SCHEME, &node, vec!["/ip4/192.168.1.5/tcp/4747".into()], "Morph on desk", 0).unwrap();

    // The existing device scans it and says hello.
    let phone = Keypair::generate_ed25519().public().to_peer_id();
    let (sender, hello) = Sender::start(decode_link(SCHEME, host.link()).unwrap(), 1).unwrap();
    assert_eq!(host.handle(&phone, hello, 2), LinkReply::Ok);
    let HostStatus::Paired { sas } = host.status(3) else { panic!("not paired") };
    assert_eq!(sas, sender.sas()); // the user compares the codes

    // After the user confirms, the identity moves, sealed.
    let seed = Key32::random().unwrap();
    let t = weirdnet_device_link::session::make_transfer(&seed, "Work", "{}", sender.offer(), 4).unwrap();
    assert_eq!(host.handle(&phone, sender.transfer(&t).unwrap(), 5), LinkReply::Ok);
    host.confirm();
    assert_eq!(host.take().unwrap().profile_name, "Work");
}
