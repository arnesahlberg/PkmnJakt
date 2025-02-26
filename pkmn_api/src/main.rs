use actix_web::{App, HttpServer};
use actix_cors::Cors;
use openssl::ssl::{SslAcceptor, SslFiletype, SslMethod};
mod misc;
mod model;
mod databaseconnection;
mod api; 

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    match std::env::var("DATABASE_PATH") {
        Ok (_) => (),
        Err(_) => {
            println!("Environment variable DATABASE_PATH is not set. Must be set to run.");
            std::process::exit(1);
        }
    };

    let cert_path = match std::env::var("CERT") {
        Ok(path) => path,
        Err(_) => {
            println!("Environment variable CERT is not set. Must be set to run.");
            std::process::exit(1);
        }
    };

    let cert_key_path = match std::env::var("CERT_KEY") {
        Ok(path) => path,
        Err(_) => {
            println!("Environment variable CERT_KEY is not set. Must be set to run.");
            std::process::exit(1);
        }
    };

    let mut builder = SslAcceptor::mozilla_intermediate(SslMethod::tls())?;
    builder.set_private_key_file(cert_key_path, SslFiletype::PEM)?;
    builder.set_certificate_chain_file(cert_path)?;


    
    HttpServer::new(|| {
        App::new()
            .wrap(
                Cors::default()
                    .allow_any_origin()
                    .allowed_methods(["GET", "POST"])
                    .allow_any_header()
            )
            .configure(api::config)
    })
    .bind_openssl(("0.0.0.0", 8081), builder)?
    .run()
    .await
}