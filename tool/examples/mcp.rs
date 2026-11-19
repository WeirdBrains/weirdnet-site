// One read-only tool behind an MCP server; the app's HTTP route or stdio loop calls handle().
use serde_json::{Value, json};
use weirdnet_mcp::{Param, ParamType, Server, ServerInfo, ToolError, ToolSpec, Tools, args, tool_ok};

const SPECS: &[ToolSpec] = &[ToolSpec {
    name: "echo",
    description: "Echo a message.",
    params: &[Param::required("text", ParamType::String, "What to echo")],
    auth: false,
    read_only: true,
    destructive: false,
    open_world: false,
}];

struct Echo;

impl Tools for Echo {
    fn specs(&self) -> &[ToolSpec] {
        SPECS
    }
    fn call(&self, _tool: &ToolSpec, a: &Value, _token: Option<&str>) -> Result<Value, ToolError> {
        Ok(tool_ok(&json!({ "echo": args::string(a, "text")? })))
    }
}

fn main() {
    let info = ServerInfo { name: "example".into(), title: "Example".into(), version: "0.1.0".into(), instructions: String::new() };
    let server = Server::new(info, Echo);
    let call = json!({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "echo", "arguments": {"text": "hi"}}});
    println!("{}", server.handle(None, call).unwrap());
}
