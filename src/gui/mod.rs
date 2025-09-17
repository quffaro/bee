use crate::core::{app::App, buffer::Buffer, components::Component, document::Document};
use catlog::zero::QualifiedName;
use eframe::egui::{
    Color32, Context, CornerRadius, FontData, FontDefinitions, FontFamily, Id, ScrollArea, Stroke,
    Style, TextBuffer, TextEdit, Ui,
    style::{Visuals, WidgetVisuals, Widgets},
    text::{CCursor, CCursorRange},
};
use egui_extras::syntax_highlighting::{CodeTheme, highlight};
use std::collections::HashMap;

pub trait Draw<Context> {
    fn render(&mut self, ctx: &Context);
}

pub mod components;

// specific to egui
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

impl Document {
    fn render_editable_buffer(&mut self, name: QualifiedName, ctx: &Context) {
        let editor_id = self.mapping.get_by_left(&name).unwrap().clone();
        let mut must_parse = None;

        egui::CentralPanel::default().show(ctx, |ui| {
            ScrollArea::vertical().show(ui, |ui| {
                let buffer = self.instance.get_mut(&name).unwrap();

                buffer.set_cursor(editor_id, ui);

                let editor = TextEdit::multiline(buffer)
                    .desired_width(f32::INFINITY)
                    .interactive(true)
                    .code_editor()
                    .id(editor_id);
                let output = editor.show(ui);

                if let Some(cursor_range) = output.cursor_range {
                    buffer.current_ccursor = cursor_range.primary.index;
                }
                self.focus = ui.memory(|mem| mem.focused());
                if output.response.changed() {
                    // XXX
                    must_parse = Some(buffer.clone())
                }
            })
        });

        if let Some(buffer) = must_parse {
            self.parse(name, buffer.rope.slice(0..).as_str().expect("!"));
        }
    }
}

impl Draw<eframe::egui::Context> for Document {
    // TODO move to a trait which dispatches on DocumentModel
    fn render(&mut self, ctx: &Context) {
        let mut buffers_to_parse: HashMap<QualifiedName, Buffer> = Default::default();
        egui::TopBottomPanel::top("menu_bar").show(ctx, |ui| egui::menu::bar(ui, |ui| {}));
        // TODO we now dynamically generate the layout
        match self.model.interface() {
            Component::EditableBuffer(name) => self.render_editable_buffer(name, ctx),
            Component::SplitBuffer(left, right) => {
                // let left_id = Id::new(&left.to_string());
                // let right_id = Id::new(&right.to_string());
                egui::SidePanel::left(Id::new(&left.to_string())).show(ctx, |ui| {
                    let editor = TextEdit::multiline(self.instance.get_mut(&left).unwrap())
                        .desired_width(f32::INFINITY)
                        .interactive(true)
                        .code_editor();
                    // .id(left_id);
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
                egui::SidePanel::right(Id::new(&right.to_string())).show(ctx, |ui| {
                    let editor = TextEdit::multiline(self.instance.get_mut(&right).unwrap())
                        .desired_width(f32::INFINITY)
                        .interactive(true)
                        .code_editor();
                    // .id(right_id);
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
        };
    }
}

impl Draw<eframe::egui::Context> for App {
    fn render(&mut self, ctx: &Context) {
        self.document.render(ctx)
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
