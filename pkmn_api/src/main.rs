use actix_web::{App, HttpServer};
use actix_cors::Cors;

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
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}