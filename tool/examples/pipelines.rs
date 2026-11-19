// A three-node pipeline: numbers > double > print, with the meaning of each node in the app.
use serde_json::{Value, json};
use weirdnet_pipelines::{Graph, Host, Kind, Node, PipelineError, Role, execute, frame};

#[derive(Debug, Clone, PartialEq, serde::Serialize, serde::Deserialize)]
#[serde(tag = "kind")]
enum Step {
    Numbers,
    Double,
    Print,
}

impl Kind for Step {
    type Error = PipelineError;
    fn parse(s: &str) -> Result<Step, PipelineError> {
        match s {
            "numbers" => Ok(Step::Numbers),
            "double" => Ok(Step::Double),
            "print" => Ok(Step::Print),
            _ => Err(PipelineError::invalid("node", format!("`{s}`: numbers, double or print"))),
        }
    }
    fn text(&self) -> String {
        format!("{self:?}").to_lowercase()
    }
    fn role(&self) -> Role {
        match self {
            Step::Numbers => Role::Source,
            Step::Double => Role::Step,
            Step::Print => Role::Sink,
        }
    }
}

struct App(Vec<String>);

impl Host<Step> for App {
    type Error = String;
    fn output(&mut self, node: &Node<Step>, inputs: &[(String, Value)]) -> Result<Value, String> {
        let all = frame::union(&node.id, &inputs.iter().map(|(_, f)| f).collect::<Vec<_>>());
        let n = |v: i64| json!({ "n": v }).as_object().unwrap().clone();
        Ok(match node.kind {
            Step::Numbers => frame::rows_frame("numbers", &[n(1), n(2)]),
            Step::Double => {
                let rows: Vec<_> = all["columns"]["n"].as_array().unwrap().iter().map(|v| n(v.as_i64().unwrap() * 2)).collect();
                frame::rows_frame("doubled", &rows)
            }
            Step::Print => {
                self.0.push(frame::markdown(&all, 10));
                all
            }
        })
    }
    fn tee(&mut self, _: &Node<Step>, tee: &str, _: &Value) -> Result<String, String> {
        Err(format!("no tee {tee}"))
    }
}

fn main() {
    let g: Graph<Step> = Graph::parse(&["a=numbers".into(), "b=double".into(), "c=print".into()], &["a>b>c".into()]).unwrap();
    assert!(g.check(None).is_empty());
    let mut app = App(vec![]);
    let run = execute("demo", &g, &mut app).unwrap();
    assert!(run.ok());
    assert_eq!(app.0, vec!["| n |\n|---|\n| 2 |\n| 4 |\n"]);
}
