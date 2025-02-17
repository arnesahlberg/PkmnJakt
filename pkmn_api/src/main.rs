use model::FoundPkmn;
use serde::{Deserialize, Serialize};
use actix_web::{web, App, HttpResponse, HttpServer};

mod model;
mod databaseconnection;

fn get_env_dbpath () ->String {
    std::env::var("DATABASE_PATH").unwrap()
}


#[derive(Debug, Deserialize)]
struct LoginRequest {
    id : String
}


#[derive(Debug, Serialize)]
struct LoginResponse {
    id : String,
    name : Option<String>,
    message : String
}



async fn login(info: web::Json<LoginRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if !user_exists {
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            message: format!("Create new user first {}", info.id),
        };
        return HttpResponse::Ok().json(response);
    }

    let user = databaseconnection::get_user_by_id_str(&info.id, &conn).unwrap().unwrap();
    let response = LoginResponse {
        id: user.user_id,
        name: Some(user.name.clone()),
        message: format!("Logged in as {}", user.name),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
struct CreateUserRequest {
    id : String,
    name : String
}

async fn create_user(info: web::Json<CreateUserRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if user_exists {
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            message: format!("User already exists {}", info.id),
        };
        return HttpResponse::Ok().json(response);
    }

    databaseconnection::create_user(&info.id, &info.name, &conn).unwrap();
    let response = LoginResponse {
        id: info.id.clone(),
        name: Some(info.name.clone()),
        message: format!("Created new user {}", info.name),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
struct SetUserNameRequest {
    id : String,
    name : String
}

async fn set_user_name(info: web::Json<SetUserNameRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if !user_exists {
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            message: format!("User does not exist {}", info.id),
        };
        return HttpResponse::BadRequest().json(response);
    }

    databaseconnection::set_user_name(&info.id, &info.name, &conn).unwrap();
    let response = LoginResponse {
        id: info.id.clone(),
        name: Some(info.name.clone()),
        message: format!("Updated user name {}", info.name),
    };
    HttpResponse::Ok().json(response)
}


#[derive(Debug, Serialize)]
struct LogoutResponse {
    logged_out : bool,
    message : String
}

// also logout
async fn logout() -> HttpResponse {
    let response = LogoutResponse {
        logged_out : true,
        message : "Logged out".to_string()
    };
    HttpResponse::Ok().json(response)
}


// to flag pokemon as caught
// send your id and the pokemon id string from qr code
// if you already found it just return a message saying you already found before
// if you found it for the first time, add it to your list and return a message saying you found it
// should flag the pokemon as caught in the database
#[derive(Debug, Deserialize)]
struct FoundPokemonRequest {
    id : String,
    pokemon_id : String
}

#[derive(Debug, Serialize)]
struct FoundPokemonResponse {
    id : String,
    pokemon_id : String,
    message : String
}

async fn found_pokemon(info: web::Json<FoundPokemonRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if !user_exists {
        let response = FoundPokemonResponse {
            id: info.id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("User does not exist {}", info.id),
        };
        return HttpResponse::BadRequest().json(response);
    }

    let pokemon_exists = databaseconnection::check_if_pokemon_exists(&info.pokemon_id, &conn).unwrap();
    if !pokemon_exists {
        let response = FoundPokemonResponse {
            id: info.id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("Pokemon does not exist {}", info.pokemon_id),
        };
        return HttpResponse::BadRequest().json(response);
    }
    let found_before = databaseconnection::check_if_you_found_pokemon_before(&info.id, &info.pokemon_id, &conn).unwrap();
    if found_before {
        let response = FoundPokemonResponse {
            id: info.id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("Already found pokemon {}", info.pokemon_id),
        };
        return HttpResponse::Ok().json(response);
    }

    // add to found pokemon
    databaseconnection::found_pokemon(&info.id, &info.pokemon_id, &conn).unwrap();
    let response = FoundPokemonResponse {
        id: info.id.clone(),
        pokemon_id: info.pokemon_id.clone(),
        message: format!("Caught pokemon {}", info.pokemon_id),
    };
    HttpResponse::Ok().json(response)
}


// view users n latest found pokemon
#[derive(Debug, Deserialize)]
struct ViewFoundPokemonRequest {
    id : String,
    n : i32
}

#[derive(Debug, Serialize)]
struct ViewFoundPokemonResponse {
    id : String,
    pokemon_found : Vec<FoundPkmn>,
    message : String
}

async fn view_found_pokemon(info: web::Json<ViewFoundPokemonRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if !user_exists {
        let response = ViewFoundPokemonResponse {
            id: info.id.clone(),
            pokemon_found: vec![],
            message: format!("User does not exist {}", info.id),
        };
        return HttpResponse::BadRequest().json(response);
    }

    let pokemon = databaseconnection::view_found_pokemon(&info.id, info.n, &conn).unwrap();
    let response = ViewFoundPokemonResponse {
        id: info.id.clone(),
        pokemon_found: pokemon,
        message: format!("Found pokemon {}", info.id),
    };
    HttpResponse::Ok().json(response)
}



#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/login", web::post().to(login)) 
            .route("/logout", web::post().to(logout))
            .route("/create_user", web::post().to(create_user))
            .route("/set_user_name", web::post().to(set_user_name))
            .route("/found_pokemon", web::post().to(found_pokemon))
            .route("/view_found_pokemon", web::post().to(view_found_pokemon))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}