// The merge rules underneath linked-device sync: hybrid logical clocks, LWW and an OR-set.
use weirdnet_sync::{Hlc, Lww, NodeId, OrSet, lww};

fn main() {
    let (laptop, phone) = (NodeId::new("laptop"), NodeId::new("phone"));
    let t1 = Hlc::tick(None, 1_000, laptop.clone());
    // The phone's clock is behind, but it has seen t1, so its next write still orders after it.
    let t2 = Hlc::receive(None, &t1, 900, phone.clone());
    assert!(t2.strictly_later_than(&t1));
    assert_eq!(lww(&t1, &t2), Lww::TakeRemote);

    let mut on_laptop = OrSet::new();
    on_laptop.add("rust", t1.clone());
    let mut on_phone = OrSet::new();
    on_phone.add("p2p", t2.clone());
    on_laptop.merge(&on_phone); // concurrent adds of different tags keep both
    assert!(on_laptop.contains(&"rust") && on_laptop.contains(&"p2p"));
}
