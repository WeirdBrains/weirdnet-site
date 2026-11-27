// Narration split to fit a speech model and stitched back, and a long clip cut for a
// transcriber with its transcript as SRT. Synthesis and transcription are stand-ins here.
use weirdnet_media::pcm::{concat, encode_wav, tone};
use weirdnet_media::speak::TextPlan;
use weirdnet_media::subtitles::srt;
use weirdnet_media::transcribe::{self, PieceTranscript, Segment, TranscribeLimits};

fn main() -> weirdnet_media::Result<()> {
    let chapter = "The harbor was quiet that morning. Gulls circled the masts.\n\nMara walked to the end of the pier.";
    // max_input_chars comes from the model's speech profile.
    let plan = TextPlan::text(chapter, Some(40))?;
    for p in &plan.pieces {
        println!("piece {}: {:?}", p.index + 1, p.text);
    }
    // One tone per piece stands in for the synthesized speech.
    let pieces: Vec<_> = plan.pieces.iter().map(|p| tone(24_000, 220.0, 20 * p.chars as u64, 0.3)).collect();
    let audio = concat(&pieces, &plan.default_joins())?;
    println!("{} ms, {} bytes of WAV", audio.duration_ms(), encode_wav(&audio).len());

    // 70 s of audio for a transcriber that takes 30 s per request.
    let clip = tone(16_000, 220.0, 70_000, 0.3);
    let cut = transcribe::plan(&clip, &TranscribeLimits::new(Some(30), Some(32 << 20)))?;
    let results: Vec<PieceTranscript> = cut
        .pieces
        .iter()
        .map(|p| PieceTranscript::new(format!("piece {}", p.index + 1), vec![Segment::new(0, 1_000, format!("piece {}", p.index + 1))]))
        .collect();
    let transcript = transcribe::realign(&cut, &results)?;
    print!("{}", srt(&transcript.segments));
    Ok(())
}
