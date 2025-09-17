use crate::core::{
    app::App, buffer::Buffer, components::EditableBuffer, document::Document, interface::Interface,
};
use catlog::zero::QualifiedName;
use eframe::egui::{
    Color32, Context, CornerRadius, FontData, FontDefinitions, FontFamily, Id, ScrollArea, Stroke,
    Style, TextBuffer, TextEdit, Ui,
    style::{Visuals, WidgetVisuals, Widgets},
    text::{CCursor, CCursorRange},
};
use egui_extras::syntax_highlighting::{CodeTheme, highlight};
use std::collections::HashMap;

pub trait Draw {
    fn render(&self);
}
pub mod components;

impl Buffer {
    fn set_cursor(&mut self, id: Id, ui: &Ui) {
        if let Some(pos_to_set) = self.ccursor_to_set {
            if let Some(mut state) = TextEdit::load_state(ui.ctx(), id) {
                let ccursor = CCursor::new(pos_to_set);
                let crange = CCursorRange::one(ccursor);
                state.cursor.set_char_range(Some(crange));
                TextEdit::store_state(ui.ctx(), id, state);
                self.ccursor_to_set = None;
            }
        }
    }
}

impl Draw for Document {
    // TODO move to a trait which dispatches on DocumentModel
    /// Render
    fn render(&mut self, ctx: &Context) {
        let mut buffers_to_parse: HashMap<QualifiedName, Buffer> = Default::default();
        egui::TopBottomPanel::top("menu_bar").show(ctx, |ui| egui::menu::bar(ui, |ui| {}));
        // TODO we now dynamically generate the layout
        // self.interface(ctx);
        match self.interface() {
            Layout::Single(buffer) => buffer.render(ctx),
            Layout::Split { left, right } => {
                match (*left, *right) {
                    (Layout::Single(ref left), Layout::Single(ref right)) => {
                        let left_id = self.mapping.get_by_left(&left);
                        let right_id = self.mapping.get_by_left(&right);
                        egui::SidePanel::left(*left_id.unwrap()).show(ctx, |ui| {
                            let editor = TextEdit::multiline(self.instance.get_mut(&left).unwrap())
                                .desired_width(f32::INFINITY)
                                .interactive(true)
                                .code_editor()
                                .id_salt(*left_id.unwrap());
                            let output = editor.show(ui);

                            if let Some(cursor_range) = output.cursor_range {
                                self.instance.get_mut(&left).unwrap().current_ccursor =
                                    cursor_range.primary.index;
                            }
                            self.focus = ui.memory(|mem| mem.focused());
                            // if output.response.change() {
                            //     buffers_to_parse.insert(left.clone(), buffer.clone());
                            // }
                        });
                        egui::SidePanel::right(*right_id.unwrap()).show(ctx, |ui| {
                            let editor =
                                TextEdit::multiline(self.instance.get_mut(&right).unwrap())
                                    .desired_width(f32::INFINITY)
                                    .interactive(true)
                                    .code_editor()
                                    .id_salt(*right_id.unwrap());
                            let output = editor.show(ui);

                            if let Some(cursor_range) = output.cursor_range {
                                self.instance.get_mut(&right).unwrap().current_ccursor =
                                    cursor_range.primary.index;
                            }

                            self.focus = ui.memory(|mem| mem.focused());

                            // if output.response.change() {
                            //     buffers_to_parse.insert(left.clone(), buffer.clone());
                            // }
                        });
                    }
                    _ => {
                        todo!()
                    }
                }
            }
        };
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &eframe::egui::Context, _frame: &mut eframe::Frame) {
        self.handler(ctx.clone());
        let mut layouter = |ui: &Ui, string: &str, wrap_width: f32| {
            let mut layout_job =
                highlight(ui.ctx(), ui.style(), &CodeTheme::light(12.0), string, "hs");
            ui.fonts(|f| f.layout_job(layout_job))
        };

        self.render(ctx)
    }
}
