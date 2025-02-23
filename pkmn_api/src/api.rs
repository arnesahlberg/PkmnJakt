use actix_web::{web, HttpResponse, HttpRequest};
use serde::{Deserialize, Serialize};
use crate::misc::{self, validate_token};
use crate::model::{FoundPkmn, Token, User, UserScore};
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
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub id: String,
    pub token: Option<Token>,
    pub name: Option<String>,
    pub message: String,
}

pub async fn login(info: web::Json<LoginRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if !user_exists {
        let response = LoginResponse {
            id: info.id.clone(),
            token: None,
            name: None,
            message: format!("Create new user first {}", info.id),
        };
        return HttpResponse::Ok().json(response);
    }
    let (user, token) = match databaseconnection::login_and_get_user_by_id_pwd(&info.id, &info.password, &conn).unwrap() {
        Some((user, token)) => (user, token),
        None => {
            let response = LoginResponse {
                id: info.id.clone(),
                token: None,
                name: None,
                message: "Invalid password".to_string(),
            };
            return HttpResponse::Ok().json(response);
        }
    };
    let response = LoginResponse {
        id: user.user_id,
        token : Some(token),
        name: Some(user.name.clone()),
        message: format!("Logged in as {}", user.name),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub id: String,
    pub name: String,
    pub password: String
}

pub async fn create_user(info: web::Json<CreateUserRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if user_exists {
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            token : None,
            message: format!("User already exists {}", info.id),
        };
        return HttpResponse::Ok().json(response);
    }
    let (user, token) = databaseconnection::create_user(&info.id, &info.name, &info.password, &conn).unwrap();
    let response = LoginResponse {
        id: user.user_id,
        name: Some(user.name),
        token : Some(token),
        message: format!("Created new user {}", info.name),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
pub struct SetUserNameRequest {
    pub name: String,
}

#[derive(Debug, Serialize)]
pub struct SetUserNameResponse {
    pub id: String,
    pub name: Option<String>,
    pub message: String,
}

pub async fn set_user_name(req: HttpRequest, info: web::Json<SetUserNameRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get("Authorization")
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: "Invalid token.".to_string(),
        };
        return HttpResponse::BadRequest().json(response);
    }

    let user_exists = databaseconnection::user_exists(&user_id, &conn).unwrap();
    if !user_exists {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: format!("User does not exist {}", user_id),
        };
        return HttpResponse::BadRequest().json(response);
    }
    databaseconnection::set_user_name(&user_id, &info.name, &conn).unwrap();
    let response = SetUserNameResponse {
        id: user_id.clone(),
        name: Some(info.name.clone()),
        message: format!("Updated user name to '{}'", info.name),
    };
    HttpResponse::Ok().json(response)
}


#[derive(Debug, Serialize)]
pub struct LogoutResponse {
    pub logged_out: bool,
    pub message: String,
}

pub async fn logout(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get("Authorization")
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");

    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = LogoutResponse {
            logged_out: false,
            message: "Invalid token. Already logged out, it seems.".to_string(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    databaseconnection::remove_token(&user_id, token, &conn).unwrap();
    let response = LogoutResponse {
        logged_out: true,
        message: "Logged out".to_string(),
    };
    HttpResponse::Ok().json(response)
}


// logout everywhere (remove all tokens for user)
pub async fn logout_everywhere(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get("Authorization")
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = LogoutResponse {
            logged_out: false,
            message: "Invalid token.".to_string(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    databaseconnection::remove_all_tokens_for_user(&user_id, &conn).unwrap();
    let response = LogoutResponse {
        logged_out: true,
        message: "Logged out everywhere".to_string(),
    };
    HttpResponse::Ok().json(response)
}


#[derive(Debug, Deserialize)]
pub struct FoundPokemonRequest {
    pub pokemon_id: String,
}

#[derive(Debug, Serialize)]
pub struct FoundPokemonResponse {
    pub user_id: String,
    pub pokemon_id: String,
    pub message: String,
}

pub async fn register_found_pokemon(req: HttpRequest, info: web::Json<FoundPokemonRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get("Authorization")
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    println!("token: {}", token);
    let user_id = misc::get_user_id_from_token(token).unwrap();
    println!("user_id: {}", user_id);
    if !validate_token(&user_id, token, &conn) {
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: "Invalid token".to_string(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    let user_exists = databaseconnection::user_exists(&user_id, &conn).unwrap();
    if !user_exists {
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("User does not exist {}", user_id),
        };
        return HttpResponse::BadRequest().json(response);
    }
    let pokemon_exists = databaseconnection::check_if_pokemon_exists(&info.pokemon_id, &conn).unwrap();
    if !pokemon_exists {
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("Pokemon does not exist {}", info.pokemon_id),
        };
        return HttpResponse::BadRequest().json(response);
    }
    let found_before =
        databaseconnection::check_if_you_found_pokemon_before(&user_id, &info.pokemon_id, &conn).unwrap();
    if found_before {
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: info.pokemon_id.clone(),
            message: format!("Already found pokemon {}", info.pokemon_id),
        };
        return HttpResponse::Ok().json(response);
    }
    databaseconnection::found_pokemon(&user_id, &info.pokemon_id, &conn).unwrap();
    let response = FoundPokemonResponse {
        user_id: user_id.clone(),
        pokemon_id: info.pokemon_id.clone(),
        message: format!("Caught pokemon {}", info.pokemon_id),
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
pub struct ViewFoundPokemonRequest {
    pub n: i32,
}

#[derive(Debug, Serialize)]
pub struct ViewFoundPokemonResponse {
    pub id: String,
    pub pokemon_found: Vec<FoundPkmn>,
    pub message: String,
}

pub async fn view_found_pokemon(req: HttpRequest, info: web::Json<ViewFoundPokemonRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get("Authorization")
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = ViewFoundPokemonResponse {
            id: user_id.clone(),
            pokemon_found: vec![],
            message: "Invalid token".to_string(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    let user_exists = databaseconnection::user_exists(&user_id, &conn).unwrap();
    if !user_exists {
        let response = ViewFoundPokemonResponse {
            id: user_id.clone(),
            pokemon_found: vec![],
            message: format!("User does not exist {}", user_id),
        };
        return HttpResponse::BadRequest().json(response);
    }
    let pokemon = databaseconnection::view_found_pokemon(&user_id, info.n, &conn).unwrap();
    let response = ViewFoundPokemonResponse {
        id: user_id.clone(),
        pokemon_found: pokemon,
        message: format!("Found pokemon {}", user_id),
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

#[derive(Debug, Serialize)]
pub struct GetUserResponse {
    pub user: Option<User>,
    pub message: String,
}

pub async fn get_user(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user = databaseconnection::get_user_by_id(&user_id, &conn).unwrap();
    match user {
        Some(user) => {
            let res = GetUserResponse {
                user: Some(user),
                message: format!("User found {}", user_id),
            };
            HttpResponse::Ok().json(res)
        },
        None => {
            let res = GetUserResponse {
                user: None,
                message: format!("User not found {}", user_id),
            };
            HttpResponse::NotFound().json(res)
        }
    }
}

// user exists request
#[derive(Debug, Serialize)]
pub struct UserExistsResponse {
    pub exists: bool,
}

pub async fn user_exists(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let exists = databaseconnection::user_exists(&user_id, &conn).unwrap();
    let res = UserExistsResponse {
        exists: exists,
    };
    HttpResponse::Ok().json(res)
}



// get pokemon request
pub async fn get_pokemon(path: web::Path<u32>) -> HttpResponse {
    let number = path.into_inner();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let pokemon = databaseconnection::get_pokemon(number, &conn).unwrap();
    match pokemon {
        Some(pokemon) => {
            let res = pokemon;
            HttpResponse::Ok().json(res)
        },
        None => {
            HttpResponse::NotFound().finish()
        }
    }
}

// registers all routes.
pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.route("/login", web::post().to(login))
        .route("/logout", web::post().to(logout))
        .route("/logout_everywhere", web::post().to(logout_everywhere))
        .route("/create_user", web::post().to(create_user))
        .route("/set_user_name", web::post().to(set_user_name))
        .route("/found_pokemon", web::post().to(register_found_pokemon))
        .route("/view_found_pokemon", web::post().to(view_found_pokemon))
        .route("/statistics_highscore", web::get().to(get_statistics_highscore))
        .route("/statistics_latest_pokemon_found", web::get().to(get_statistics_latest_pokemon_found))
        .route("/get_user/{user_id}", web::get().to(get_user))
        .route("/get_pokemon/{number}", web::get().to(get_pokemon))
        .route("/user_exists/{user_id}", web::get().to(user_exists))
        ;
}

