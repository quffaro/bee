use steel::{SteelVal, rerrs::SteelErr, steel_vm::engine::Engine};

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
        Self {
            engine: Some(engine),
        }
    }

    pub fn run(&mut self, input: String) -> Result<Vec<SteelVal>, SteelErr> {
        self.engine.as_mut().unwrap().run(input)
    }
}

impl Default for DocumentEngine {
    fn default() -> Self {
        DocumentEngine::startup()
    }
}
