use clap::{Parser, Subcommand, ValueEnum};
use commands::convert::convert;
use std::fmt::Display;

mod commands;

#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
enum OutputFormat {
    Markdown,
    Forester,
    // HTML
    // Latex
    // Pdf
}

impl Display for OutputFormat {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OutputFormat::Markdown => write!(f, "markdown"),
            OutputFormat::Forester => write!(f, "forester"),
        }
    }
}

impl OutputFormat {
    fn extension(&self) -> String {
        match self {
            OutputFormat::Markdown => String::from("md"),
            OutputFormat::Forester => String::from("tree"),
        }
    }
}

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Convert {
        /// Input file (use - for stdin)
        #[arg(short, long)]
        input: String,

        /// Output file (use - for stdout)
        #[arg(short, long)]
        output: String,

        /// Output format
        #[arg(short, long, value_enum, default_value_t = OutputFormat::Markdown)]
        format: OutputFormat,
    },
}

fn write_output(path: &str, content: &str) -> Result<(), Box<dyn std::error::Error>> {
    if path == "-" {
        print!("{}", content);
    } else {
        std::fs::write(path, content)?;
    };
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let cli = Cli::parse();

    match cli.command {
        Command::Convert {
            input,
            output,
            format,
        } => convert(input, output),
    }

    Ok(())
}
