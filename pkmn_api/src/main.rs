use actix_web::{App, HttpServer};
use actix_cors::Cors;
use openssl::ssl::{SslAcceptor, SslFiletype, SslMethod};
mod misc;
mod model;
mod databaseconnection;
mod api; 

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Check for DATABASE_PATH
    match std::env::var("DATABASE_PATH") {
        Ok(_) => (),
        Err(_) => {
            println!("Environment variable DATABASE_PATH is not set. Must be set to run.");
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

    println!("Exposing IP '{}', Listening on port {}", ip, port);

    if let (Some(cert_path), Some(cert_key_path)) = (cert, cert_key) {
        // HTTPS mode
        println!("Using SSL!");
        let mut builder = openssl::ssl::SslAcceptor::mozilla_intermediate(openssl::ssl::SslMethod::tls())?;
        builder.set_private_key_file(cert_key_path, openssl::ssl::SslFiletype::PEM)?;
        builder.set_certificate_chain_file(cert_path)?;

        HttpServer::new(|| {
            actix_web::App::new()
                .wrap(
                    actix_cors::Cors::default()
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
        println!("Not using SSL! Make sure you use SSL in some outer layer to secure traffic.");
            
        HttpServer::new(|| {
            actix_web::App::new()
                .wrap(
                    actix_cors::Cors::default()
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