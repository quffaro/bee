use crate::OutputFormat;
use bee::core::{app::App, document::Document};
use regex::Regex;
use std::{fs::read_to_string, path::PathBuf};

pub fn convert(input: String, output: String, format: OutputFormat) {
    if let Ok(text) = read_to_string(&input) {
        let mut app: App = text.into();
        app.parse(format.extension());
        app.preprocess(output.into())
    }
}

pub fn template(input: PathBuf, output: PathBuf, format: OutputFormat, template: PathBuf) {
    if let Ok(text) = read_to_string(&input) {
        let mut app: App = text.into();
        dbg!(&app);
        app.template(output, format.extension(), template)
    };
}

#[cfg(test)]
mod tests {
    use crate::{commands::convert::template, OutputFormat};
    use regex::Regex;
    use std::fs::read_to_string;

    #[test]
    fn test_template() {
        template(
            "src/busybee/test/template.bee".into(),
            "fun.tex".into(),
            OutputFormat::Latex,
            "template.tex".into(),
        )
    }
}
