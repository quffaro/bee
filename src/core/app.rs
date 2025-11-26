use crate::core::document::Document;
use catlog::zero::name;
use eframe::egui;
use regex::Regex;
use ropey::Rope;
use std::{any::TypeId, fs::read_to_string, ops::Range, path::PathBuf};

#[derive(Debug, Default)]
pub struct App {
    document: Document,
}

impl From<String> for App {
    fn from(string: String) -> App {
        let document: Document = string.into();
        App { document }
    }
}

impl App {
    // do we do anything with this context...?
    pub fn new(cc: &eframe::CreationContext<'_>) -> Self {
        let mut app = Default::default();
        app
    }

    #[inline]
    pub fn render(&mut self, ctx: &eframe::egui::Context) {
        self.document.render(ctx)
    }

    // TODO preprocess is inherited and should have the same return
    pub fn save(&mut self) {
        if let Some(path) = rfd::FileDialog::new().save_file() {
            match path.extension().and_then(|ext| ext.to_str()) {
                Some("md") => {
                    self.preprocess(path);
                }
                _ => {
                    if let Ok(buffer) = self.document.dump() {
                        std::fs::write(path, buffer);
                    }
                }
            }
        }
    }

    // TODO this hideously populates each buffer with the same text
    pub fn load(&mut self) {
        if let Some(path) = rfd::FileDialog::new().pick_file() {
            match std::fs::read_to_string(path) {
                Ok(text) => self.document = Document::from(text),
                Err(err) => eprintln!("Error loading file: {}", err),
            }
        }
    }

    #[inline]
    pub fn lozenge(&mut self) {
        self.document.lozenge()
    }

    // TODO what am I doing here
    pub fn parse(&mut self, target: &str) {
        let name = name("Buffer");
        let object = self.document.instance.clone();
        let buffer = object.get(&name).unwrap();
        self.document
            .parse(name, buffer.rope.slice(0..).as_str().expect("!"), target);
    }

    pub fn preprocess(&mut self, path: PathBuf) {
        if let Ok(buffer) = self.document.preprocess() {
            std::fs::write(path, buffer);
        }
    }

    pub fn template(&mut self, output: PathBuf, target: &str, template: PathBuf) {
        self.parse(target);
        if let Ok(buffer) = self.document.preprocess() {
            dbg!(&self.document);
            if let Ok(body) = read_to_string(&template) {
                if let Ok(re) = Regex::new(r"◊\(body\)") {
                    let out: String = re.replace(&body, buffer).to_string();
                    std::fs::write(output, out).expect("!");
                }
            }
        }
    }

    pub fn handler(&mut self, ctx: eframe::egui::Context) {
        if ctx.input(|i| i.key_pressed(egui::Key::Comma) && i.modifiers.ctrl) {
            self.lozenge();
        }
        if ctx.input(|i| i.key_pressed(egui::Key::Period) && i.modifiers.ctrl) {
            self.preprocess(PathBuf::from("output.md"))
        }
        if ctx.input(|i| i.key_pressed(egui::Key::S) && i.modifiers.ctrl) {
            self.save()
        }
        if ctx.input(|i| i.key_pressed(egui::Key::L) && i.modifiers.ctrl) {
            self.load()
        }
    }
}
