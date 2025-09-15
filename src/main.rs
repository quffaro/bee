use bee::core::app::App;

fn main() -> Result<(), eframe::Error> {
    let options = eframe::NativeOptions {
        ..Default::default()
    };
    eframe::run_native("bee", options, Box::new(|cc| Ok(Box::new(App::new(cc)))))
}
