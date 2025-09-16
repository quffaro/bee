use eframe::egui::TextBuffer;
use eframe::egui::text::{CCursor, CCursorRange};
use ropey::Rope;
use std::{any::TypeId, ops::Range};

/// a buffer is a diagram of a model for any text, a buffer implements TextBuffer
#[derive(Clone, Debug, Default)]
pub struct Buffer {
    pub rope: Rope,
    pub current_ccursor: usize,
    pub ccursor_to_set: Option<usize>,
}

impl From<String> for Buffer {
    fn from(val: String) -> Self {
        Buffer {
            rope: Rope::from(val),
            ..Default::default()
        }
    }
}

impl TextBuffer for Buffer {
    fn is_mutable(&self) -> bool {
        true
    }

    fn as_str(&self) -> &str {
        let range = 0..self.rope.len_chars();
        if let Some(out) = self.rope.slice(range).as_str() {
            out
        } else {
            ""
        }
    }

    fn insert_text(&mut self, text: &str, char_index: usize) -> usize {
        self.rope.insert(char_index, text);
        text.len()
    }

    fn delete_char_range(&mut self, char_range: Range<usize>) {
        self.rope.remove(char_range)
    }

    fn type_id(&self) -> TypeId {
        TypeId::of::<Self>()
    }
}
