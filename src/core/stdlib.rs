use crate::core::{components::Component, interface::DocumentModel};
use catlog::{
    dbl::{model::*, theory::*},
    stdlib::th_category,
    zero::{QualifiedName, name},
};
use std::{fmt::Display, rc::Rc};

/// DocumentModel is the parameter so we don't have to populate type parameters. But maybe an Article is actually a Model which also implements DocumentModel.
pub struct Article(Rc<DiscreteDblTheory>);

impl Article {
    pub fn model(th: Rc<DiscreteDblTheory>) -> DiscreteDblModel {
        let mut model = DiscreteDblModel::new(th);
        model.add_ob(name("Buffer"), name("Object"));
        model
    }
}

impl Default for Article {
    fn default() -> Self {
        Article(Rc::new(th_category()))
    }
}

// Article implements "DocumentModel" in that this is how we construct a model for our given theory.
impl DocumentModel for Article {
    fn objects(&self) -> Vec<QualifiedName> {
        vec![name("Buffer")]
    }

    // /// Renders an interface which is simply an article
    fn interface(&self) -> Component {
        Component::EditableBuffer(name("Buffer"))
    }
}

/// Has a vector of buffers which act as a single document. It's conceivable that a list can be
/// migrated into a single article by flattening its structure. After all, articles may have lists!
pub struct TodoList(Rc<ModalDblTheory>);

// impl DocumentModel for TodoList {
//     fn objects(&self) -> Vec<QualifiedName> {
//         vec![]
//     }

//     // fn interface(&self) -> Interface {
//     //     Interface()
//     // }
// }

/// A nontrivial way where articles are associated to lists is through commenting. Comments are
/// tiny buffers of text associated to regions in the article.
pub fn article_with_comments(th: Rc<ModalDblTheory>) -> ModalDblModel {
    let (ob_type, op) = (ModalObType::new(name("Buffer")), name("tensor"));
    let mut model = ModalDblModel::new(th);
    model.add_ob(name("Buffer"), ob_type);
    model
}
// TODO

/// Presentations are different models of modal double theories. While to-do lists might be
/// tree-like, presentations might have additional structure. Furthermore, it's more plausible that
/// the UI of a presentation is different, as they can be slideshows or "ZUIs." In such cases, the
/// interface for a presentation is different despite it possibly having the same content.
pub fn presentation(th: Rc<ModalDblTheory>) -> ModalDblModel {
    let mut model = ModalDblModel::new(th);
    model
}
