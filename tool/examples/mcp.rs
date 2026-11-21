// Two tools behind an MCP server: a sync one (JSON) and an async one with an image result.
// The app's HTTP route, stdio::serve or stdio::serve_blocking calls the server.
use serde_json::{Value, json};
use weirdnet_mcp::{CallToolResult, Content, Param, ParamType, Server, ServerInfo, ToolError, ToolSpec, Tools, args};

const SPECS: &[ToolSpec] = &[
    ToolSpec {
        name: "echo",
        description: "Echo a message.",
        params: &[
            Param::required("text", ParamType::String, "What to echo"),
            Param::optional("tone", ParamType::Enum(&["plain", "loud"]), "How to echo it"),
        ],
        auth: false,
        read_only: true,
        destructive: false,
        open_world: false,
    },
    ToolSpec { name: "pixel", description: "A one-pixel GIF.", params: &[], auth: false, read_only: true, destructive: false, open_world: false },
];

struct App;

impl Tools for App {
    fn specs(&self) -> &[ToolSpec] {
        SPECS
    }

    async fn call_async<'a>(&'a self, tool: &'a ToolSpec, a: &'a Value, _token: Option<&'a str>) -> Result<CallToolResult, ToolError> {
        match tool.name {
            "echo" => {
                let text = args::string(a, "text")?;
                let text = if args::opt_string(a, "tone") == Some("loud") { text.to_uppercase() } else { text.to_string() };
                Ok(CallToolResult::json(&json!({ "echo": text })))
            }
            _ => Ok(CallToolResult::new(vec![Content::text("a pixel"), Content::image("R0lGODlhAQABAAAAACw=", "image/gif")])),
        }
    }
}

fn main() {
    assert!(ToolSpec::check(SPECS).is_ok());
    let info = ServerInfo { name: "example".into(), title: "Example".into(), version: "0.1.0".into(), instructions: String::new() };
    let server = Server::new(info, App);
    // These tools never wait, so the sync entry point can serve them; use handle_async otherwise.
    for name in ["echo", "pixel"] {
        let call = json!({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": name, "arguments": {"text": "hi", "tone": "loud"}}});
        println!("{}", server.handle(None, call).unwrap());
    }
}
