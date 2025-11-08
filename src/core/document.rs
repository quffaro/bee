use crate::{
    core::{
        buffer::Buffer,
        model::{article, DocumentModel, Layout},
    },
    gui,
};
use catlog::zero::QualifiedName;
use eframe::egui::Id;
use std::collections::HashMap;
use steel::{rerrs::SteelErr, steel_vm::engine::Engine, SteelVal};

pub struct DocumentEngine {
    pub engine: Option<Engine>,
}

impl DocumentEngine {
    fn startup() -> Self {
        let mut engine = Engine::new();
        let parsing = include_str!("../busybee/parsing.scm");
        engine.run(format!(r"{}", parsing));
        let setup = include_str!("../busybee/busybee.scm");
        engine.run(format!(r"{}", setup));
        let markdown = include_str!("../busybee/markdown.scm");
        engine.run(format!(r"{}", markdown));
        let latex = include_str!("../busybee/another.scm");
        engine.run(format!(r"{}", latex));
        Self {
            engine: Some(engine),
        }
    }

    fn run(&mut self, input: String) -> Result<Vec<SteelVal>, SteelErr> {
        self.engine.as_mut().unwrap().run(input)
    }
}

impl Default for DocumentEngine {
    fn default() -> Self {
        DocumentEngine::startup()
    }
}

/// A document is an instance of a document model
pub struct Document {
    /// The document model. Document models may be articles, todo-lists, presentations, kanban
    /// boards, etc. How the data is stored in the document, how the document appears in the UI,
    /// and how the user interacts with the UI is dictated by an interpretation of the document model.
    pub model: Box<dyn DocumentModel>,

    /// An instantiation of the document model.
    pub instance: HashMap<QualifiedName, Buffer>,

    /// This helpful bimap associates Qualified Names to their Id in the frontend. However, this
    /// hardcodes the UI backend into the document.
    pub mapping: bimap::BiMap<QualifiedName, egui::Id>,

    /// AST parsed from Steel
    pub parsed: HashMap<QualifiedName, Result<Vec<SteelVal>, SteelErr>>,

    /// Steel engine is responsible for parsing the model. Model migration uses the parsed
    /// document structure as a guide.
    pub engine: DocumentEngine,

    /// Document focus
    pub focus: Option<egui::Id>,
}

impl Default for Document {
    fn default() -> Self {
        let model = Box::new(article(catlog::stdlib::th_category().into()));
        // let model = Box::new(todo_list(catlog::stdlib::th_sym_monoidal_category().into()));

        let mut instance: HashMap<QualifiedName, Buffer> = HashMap::from_iter(
            model
                .objects()
                .into_iter()
                .map(|ob| (ob, Default::default())),
        );
        let mapping: bimap::BiMap<QualifiedName, egui::Id> = bimap::BiMap::from_iter(
            model
                .objects()
                .into_iter()
                .map(|ob| (ob.clone(), Id::new(ob.to_string()))),
        );
        let parsed: HashMap<QualifiedName, Result<Vec<SteelVal>, SteelErr>> = Default::default();
        let engine: DocumentEngine = Default::default();
        Self {
            model,
            instance,
            mapping,
            parsed,
            engine,
            focus: None,
        }
    }
}

impl From<String> for Document {
    fn from(value: String) -> Self {
        let mut document: Document = Default::default();
        document.instance = HashMap::from_iter(
            document
                .instance
                .into_iter()
                .map(|(ob, _)| (ob, Buffer::from(value.clone()))),
        );
        document
    }
}

impl Document {
    // TODO this should be render
    pub fn parse(
        &mut self,
        name: QualifiedName,
        input: &str,
        target: &str,
    ) -> Option<Result<Vec<SteelVal>, SteelErr>> {
        let parsed = self
            .engine
            .run(format!(r#" (render "{}" "{}"))) "#, target, input));
        self.parsed.insert(name, parsed)
    }

    pub fn dump(&self) -> Result<String, String> {
        let string_buffer = self
            .instance
            .iter()
            .map(|(_, buf)| buf.rope.get_slice(0..).and_then(|s| s.as_str()).unwrap())
            .collect::<Vec<&str>>();
        Ok(string_buffer.join("\n"))
    }

    pub fn insert(&mut self, value: &str) {
        if let Some(id) = self.focus {
            let name = self.mapping.get_by_right(&id).expect("!");
            if let Some(buffer) = self.instance.get_mut(name) {
                buffer.rope.insert(buffer.current_ccursor, value);
                buffer.ccursor_to_set = Some(buffer.current_ccursor + value.len());
            }
        }
    }

    /// This converts the parsed code into the target format.
    pub fn preprocess(&mut self) -> Result<String, SteelErr> {
        let mut out: String = Default::default();
        for value in self.parsed.values() {
            if let Ok(steel_vals) = value {
                for value in steel_vals {
                    match value {
                        SteelVal::StringV(s) => out.push_str(s),
                        _ => todo!(),
                    }
                }
            }
        }
        Ok(out)
    }

    #[inline]
    pub fn lozenge(&mut self) {
        self.insert("◊")
    }

    #[inline]
    pub fn layout(&self) -> Layout {
        self.model.layout()
    }
}
