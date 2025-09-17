use crate::{core::components::EditableBuffer, gui::Draw};
use eframe::egui::{Context, ScrollArea, TextEdit};

impl Draw for EditableBuffer {
    fn render(&self, ctx: &Context) {
        let editor_id = self.mapping.get_by_left(&self.name).unwrap().clone();
        let mut must_parse = None;

        // TODO
        egui::CentralPanel::default().show(ctx, |ui| {
            ScrollArea::vertical().show(ui, |ui| {
                let buffer = self.instance.get_mut(&self.name).unwrap();

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
            self.parse(self.name, buffer.rope.slice(0..).as_str().expect("!"));
        }
    }
}
