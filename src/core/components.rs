use catlog::zero::QualifiedName;

// TODO QualifiedName, monad
/// A component is an object of the model which has a state and behavior.
pub enum Component {
    EditableBuffer(QualifiedName),
    SplitBuffer(QualifiedName, QualifiedName),
}
// pub trait Component {
//     fn input_handler(&self);
// }

// This renders as an editable buffer component. In the `egui` package, this becomes the TextEdit component. The actual buffer state is stored in the Document. This just exists to control behavior.
// pub struct EditableBuffer {
//     /// Name of the object this is the buffer of.
//     pub name: QualifiedName,
// }

// These are keystrokes which an EditableBuffer contribute to the app
// impl Component for EditableBuffer {
//     fn input_handler(&self) {}
// }
