use crate::core::components::Component;
use catlog::zero::QualifiedName;

/// These variants allow us to specify a Layout
#[derive(Debug, Clone)]
pub enum Layout {
    Single(QualifiedName),
    Split {
        left: Box<Layout>,
        right: Box<Layout>,
    },
}

/// Components are organized here
// pub enum Tree {
//     Leaf(Box<dyn Component>),
//     Tree(Vec<Box<Tree>>),
// }

// pub struct Interface(pub Tree);

// impl Interface {
//     pub fn add_leaf(&mut self, component: Component) {

//     }
// }

pub trait DocumentModel {
    fn objects(&self) -> Vec<QualifiedName>;
    fn interface(&self) -> Component;
}

#[cfg(test)]
mod tests {
    use super::*;

    // Tree::Leaf()
}
