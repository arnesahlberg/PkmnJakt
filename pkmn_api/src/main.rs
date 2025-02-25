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

    let mut builder = SslAcceptor::mozilla_intermediate(SslMethod::tls())?;
    builder.set_private_key_file("dev-certs/localhost+2-key.pem", SslFiletype::PEM)?;
    builder.set_certificate_chain_file("dev-certs/localhost+2.pem")?;
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