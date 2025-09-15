use crate::core::document::Document;
use eframe::egui;
use ropey::Rope;
use std::{any::TypeId, ops::Range};

#[derive(Default)]
pub struct App {
    document: Document,
}

impl App {
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
            if let Ok(buffer) = self.document.dump() {
                std::fs::write(path, buffer);
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

    #[inline]
    pub fn preprocess(&mut self) {
        if let Ok(buffer) = self.document.preprocess() {
            std::fs::write("output.md", buffer);
        }
    }

    pub fn handler(&mut self, ctx: eframe::egui::Context) {
        if ctx.input(|i| i.key_pressed(egui::Key::Comma) && i.modifiers.ctrl) {
            self.lozenge();
        }
        if ctx.input(|i| i.key_pressed(egui::Key::Period) && i.modifiers.ctrl) {
            self.preprocess()
        }
        if ctx.input(|i| i.key_pressed(egui::Key::S) && i.modifiers.ctrl) {
            self.save()
        }
        if ctx.input(|i| i.key_pressed(egui::Key::L) && i.modifiers.ctrl) {
            self.load()
        }
    }
}
