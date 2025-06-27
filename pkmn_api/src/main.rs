use actix_web::{middleware::Logger, App, HttpServer};
use actix_cors::Cors;
use clap::Parser;
use env_logger::{Builder, Target};
use log::{info, warn};
use std::fs::OpenOptions;
use std::io::Write;

mod misc;
mod model;
mod databaseconnection;
mod api; 

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Path to the log file
    #[arg(long, default_value = "./pkmn_api.log")]
    log_file: String,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Parse command line arguments
    let args = Args::parse();
    
    // Initialize logging
    init_logging(&args.log_file);
    
    // Check for DATABASE_PATH
    match std::env::var("DATABASE_PATH") {
        Ok(path) => info!("Database path: {}", path),
        Err(_) => {
            eprintln!("Environment variable DATABASE_PATH is not set. Must be set to run.");
            std::process::exit(1);
        }
    };

    // Try to get CERT and CERT_KEY for HTTPS
    let cert = std::env::var("CERT").ok();
    let cert_key = std::env::var("CERT_KEY").ok();

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8081);
    
    let ip  = std::env::var("EXPOSE_IP") 
    .ok()
    .unwrap_or("127.0.0.1".to_string());

    info!("Server starting - IP: {}, Port: {}", ip, port);
    info!("Logging to: {}", args.log_file);

    if let (Some(cert_path), Some(cert_key_path)) = (cert, cert_key) {
        // HTTPS mode
        info!("Starting server in HTTPS mode");
        info!("Certificate: {}", cert_path);
        let mut builder = openssl::ssl::SslAcceptor::mozilla_intermediate(openssl::ssl::SslMethod::tls())?;
        builder.set_private_key_file(&cert_key_path, openssl::ssl::SslFiletype::PEM)?;
        builder.set_certificate_chain_file(&cert_path)?;

        HttpServer::new(|| {
            App::new()
                .wrap(
                    Logger::new("%{r}a \"%r\" %s %b \"%{Referer}i\" \"%{User-Agent}i\" %T")
                        .exclude("/health") // Exclude health checks from logs if needed
                )
                .wrap(
                    Cors::default()
                        .allow_any_origin()
                        .allowed_methods(["GET", "POST"])
                        .allow_any_header()
                )
                .configure(api::config)
        })
        .bind_openssl((ip.as_str(), port), builder)?
        .run()
        .await
    } else {
        warn!("Starting server in HTTP mode - NOT SECURE! Make sure you use SSL in some outer layer to secure traffic.");
            
        HttpServer::new(|| {
            App::new()
                .wrap(
                    Logger::new("%{r}a \"%r\" %s %b \"%{Referer}i\" \"%{User-Agent}i\" %T")
                        .exclude("/health") // Exclude health checks from logs if needed
                )
                .wrap(
                    Cors::default()
                        .allow_any_origin()
                        .allowed_methods(["GET", "POST"])
                        .allow_any_header()
                )
                .configure(api::config)
        })
        .bind((ip.as_str(), port))?
        .run()
        .await
    }
}

fn init_logging(log_file_path: &str) {
    // Create or open the log file
    let log_file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_file_path)
        .expect("Failed to open log file");

    // Build the logger with default level if RUST_LOG is not set
    let mut builder = Builder::new();
    
    // Set default log level to INFO if RUST_LOG env var is not set
    if let Ok(rust_log) = std::env::var("RUST_LOG") {
        builder.parse_filters(&rust_log);
    } else {
        // Default: INFO for our crate, WARN for dependencies
        builder.filter_level(log::LevelFilter::Warn);
        builder.filter_module("pkmn_api", log::LevelFilter::Info);
        builder.filter_module("actix_web", log::LevelFilter::Info);
    }
    
    builder
        .target(Target::Pipe(Box::new(log_file)))
        .format(|buf, record| {
            writeln!(
                buf,
                "[{} {} {}:{}] {}",
                chrono::Local::now().format("%Y-%m-%d %H:%M:%S"),
                record.level(),
                record.file().unwrap_or("unknown"),
                record.line().unwrap_or(0),
                record.args()
            )
        })
        .init();
    
    // Also print to stdout that logging is initialized
    println!("Logging initialized to: {}", log_file_path);
    println!("To see logs, ensure RUST_LOG is set or use default (info for pkmn_api, warn for others)");
}