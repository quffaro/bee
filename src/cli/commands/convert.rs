use bee::core::{app::App, document::Document};
use std::fs::read_to_string;

pub fn convert(input: String, output: String) {
    if let Ok(text) = read_to_string(&input) {
        let mut app: App = text.into();
        app.parse();
        app.preprocess(output.into())
    }
}
