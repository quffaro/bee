use crate::OutputFormat;
use bee::core::{app::App, document::Document};
use std::fs::read_to_string;

// TODO get extension
pub fn convert(input: String, output: String, format: OutputFormat) {
    if let Ok(text) = read_to_string(&input) {
        let mut app: App = text.into();
        app.parse(format.extension());
        app.preprocess(output.into())
    }
}
