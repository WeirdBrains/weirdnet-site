// A code space plugin (crate-type = ["cdylib"]): a chart of the close column.
use weirdnet_plugin::prelude::*;

pub fn run(host: &Host) -> Result<View> {
    let bars = host.input()?;
    let close = bars.f64("close")?;
    Ok(View::chart("close").x("timestamp", bars.f64("timestamp")?, true).line("close", close))
}

weirdnet_plugin::plugin!(run);
