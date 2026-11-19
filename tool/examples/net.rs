// Anna invites Ben: a signed offer as a link, Ben's answer, and one shared short code.
use weirdnet_net::{Keypair, Profile, WEIRDNET, exchange::Token, profile::invite_scope};

// Weirdnet's profile with invitation links on the app's own scheme (WEIRDNET has none).
const GARDEN: Profile = Profile {
    join_link: "weirdnet-garden://join/",
    answer_link: "weirdnet-garden://answer/",
    link_mark: "weirdnet-garden://",
    ..WEIRDNET
};

fn main() {
    let (anna, ben) = (Keypair::generate_ed25519(), Keypair::generate_ed25519());
    let p = &GARDEN;
    let (offer, secret) = p.offer(&anna, "anna", vec![], invite_scope("garden", "member"), 0, 60_000).unwrap();
    let link = p.link(&p.offer_token(&offer).unwrap()).unwrap(); // weirdnet-garden://join/…
    let Token::Offer(seen) = p.parse_token(&link).unwrap() else { unreachable!() };
    p.verify_offer(&seen, 1).unwrap();
    let (answer, on_ben) = p.answer(&ben, &seen, "ben", vec![], 1).unwrap();
    let on_anna = p.complete(&answer, &offer, &secret[..]).unwrap();
    assert_eq!(on_anna.short_code, on_ben.short_code); // both screens show the same code
}
