use catlog::{
    dbl::{model::*, theory::*},
    zero::{QualifiedName, name},
};
use std::rc::Rc;

/// These variants allow us to specify a Layout
#[derive(Debug, Clone)]
pub enum Layout {
    Single(QualifiedName),
    Split {
        left: Box<Layout>,
        right: Box<Layout>,
    },
}

pub trait DocumentModel {
    fn objects(&self) -> Vec<QualifiedName>;
    fn layout(&self) -> Layout;
}

impl DocumentModel for DiscreteDblModel {
    fn objects(&self) -> Vec<QualifiedName> {
        vec![name("Buffer")]
    }
    fn layout(&self) -> Layout {
        Layout::Single(self.objects()[0].clone())
    }
}

pub fn article(th: Rc<DiscreteDblTheory>) -> DiscreteDblModel {
    let mut model = DiscreteDblModel::new(th);
    model.add_ob(name("Buffer"), name("Object"));
    model
}
