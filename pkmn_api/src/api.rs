use actix_web::{web, HttpResponse};
use serde::{Deserialize, Serialize};
use crate::model::{FoundPkmn, User, UserScore};
use crate::databaseconnection;

fn get_env_dbpath() -> String {
    match std::env::var("DATABASE_PATH") {
        Ok (value) => value,
        Err(_) => {
            panic!("DATABASE_PATH not set.");
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub id: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub id: String,
    pub name: Option<String>,
    pub message: String,
}

pub async fn login(info: web::Json<LoginRequest>) -> HttpResponse {
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
pub struct CreateUserRequest {
    pub id: String,
    pub name: String,
}

pub async fn create_user(info: web::Json<CreateUserRequest>) -> HttpResponse {
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
pub struct SetUserNameRequest {
    pub id: String,
    pub name: String,
}

pub async fn set_user_name(info: web::Json<SetUserNameRequest>) -> HttpResponse {
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
pub struct LogoutResponse {
    pub logged_out: bool,
    pub message: String,
}

pub async fn logout() -> HttpResponse {
    let response = LogoutResponse {
        logged_out: true,
        message: "Logged out".to_string(),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
pub struct FoundPokemonRequest {
    pub id: String,
    pub pokemon_id: String,
}

#[derive(Debug, Serialize)]
pub struct FoundPokemonResponse {
    pub id: String,
    pub pokemon_id: String,
    pub message: String,
}

pub async fn found_pokemon(info: web::Json<FoundPokemonRequest>) -> HttpResponse {
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
    let found_before =
        databaseconnection::check_if_you_found_pokemon_before(&info.id, &info.pokemon_id, &conn).unwrap();
    if found_before {
        let response = FoundPokemonResponse {
            id: info.id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("Already found pokemon {}", info.pokemon_id),
        };
        return HttpResponse::Ok().json(response);
    }
    databaseconnection::found_pokemon(&info.id, &info.pokemon_id, &conn).unwrap();
    let response = FoundPokemonResponse {
        id: info.id.clone(),
        pokemon_id: info.pokemon_id.clone(),
        message: format!("Caught pokemon {}", info.pokemon_id),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
pub struct ViewFoundPokemonRequest {
    pub id: String,
    pub n: i32,
}

#[derive(Debug, Serialize)]
pub struct ViewFoundPokemonResponse {
    pub id: String,
    pub pokemon_found: Vec<FoundPkmn>,
    pub message: String,
}

pub async fn view_found_pokemon(info: web::Json<ViewFoundPokemonRequest>) -> HttpResponse {
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


#[derive(Debug, Serialize)]
pub struct GetHighScoreResponse {
    pub user_scores : Vec<UserScore>
}

pub async fn get_statistics_highscore() -> HttpResponse  {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let scores = databaseconnection::statistics_users_most_found(10, &conn).unwrap();
    let res = 
        GetHighScoreResponse {
            user_scores : scores
        };
    HttpResponse::Ok().json(res)
}


#[derive(Debug, Serialize)]
pub struct GetLatestFoundPokemonResponse {
    pub found_pokemon : Vec<FoundPkmn>
}

pub async fn get_statistics_latest_pokemon_found() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let found_pokemon = databaseconnection::statistics_latest_pokemon_found(10, &conn).unwrap();
    let res = GetLatestFoundPokemonResponse {
        found_pokemon : found_pokemon
    };
    HttpResponse::Ok().json(res)
}



// registers all routes.
pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.route("/login", web::post().to(login))
       .route("/logout", web::post().to(logout))
       .route("/create_user", web::post().to(create_user))
       .route("/set_user_name", web::post().to(set_user_name))
       .route("/found_pokemon", web::post().to(found_pokemon))
       .route("/view_found_pokemon", web::post().to(view_found_pokemon))
       .route("/statistics_highscore", web::get().to(get_statistics_highscore))
         .route("/statistics_latest_pokemon_found", web::get().to(get_statistics_latest_pokemon_found))
       ;
}

