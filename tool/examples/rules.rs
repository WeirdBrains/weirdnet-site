// The pieces a rule is made of: an `if` condition and a schedule. The engine runs them
// through the app's `engine::Host` (rules, events, actions, run records).
use weirdnet_rules::{schedule, syntax};

fn main() -> weirdnet_rules::Result<()> {
    let cond = syntax::parse_condition("inserted > 0")?;
    println!("{} {:?} {}", cond.field, cond.op, cond.value);

    let every = schedule::parse_every("6h")?;
    println!("{}", schedule::schedule_text(&every));

    let weekdays = schedule::parse_cron("30 7 * * 1-5")?;
    println!("next run after t=0: {:?}", weekdays.next_after(0));
    Ok(())
}
