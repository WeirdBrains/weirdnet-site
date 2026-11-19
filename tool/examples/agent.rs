// One task through the agent loop with the `testing` feature's scripted model and approver.
// A real app implements ModelBackend (for example over weirdnet-model) and Approver (its UI).
use std::sync::Arc;
use weirdnet_agent::testing::{ScriptedApprover, ScriptedModel};
use weirdnet_agent::{AgentConfig, AgentIdentity, AgentKind, AgentSession, CancelToken, ModelTurn, Policy, StopReason, ToolRegistry};

#[tokio::main]
async fn main() {
    let model = ScriptedModel::new(vec![ModelTurn { text: "hello there".into(), tool_calls: vec![] }]);
    let mut tools = ToolRegistry::new();
    tools.refresh().await.unwrap();
    let cfg = AgentConfig::new(AgentIdentity::new("atlas", "Atlas", AgentKind::Local));
    let mut session = AgentSession::new(cfg, Arc::new(model), Arc::new(tools), Policy::new().shared(), Arc::new(ScriptedApprover::default()));

    let (events, mut rx) = tokio::sync::mpsc::unbounded_channel();
    let outcome = session.run("say hello", Some(events), CancelToken::new()).await;
    assert_eq!(outcome.stop, StopReason::Completed);
    while let Ok(event) = rx.try_recv() {
        println!("{event:?}");
    }
    println!("{} ({} trace steps)", outcome.text, outcome.trace.steps.len());
}
