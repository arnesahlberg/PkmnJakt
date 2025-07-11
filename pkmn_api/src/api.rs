use actix_web::{web, HttpResponse, HttpRequest};
use serde::{Deserialize, Serialize};
use log::{info, warn, error, debug};
use crate::misc::{self, validate_token};
use crate::model::{FoundPkmn, Pkmn, Token, User, UserScore, PokemonFoundCount, 
                  GameStatusResponse, GameStartStatusResponse, ServerTimeResponse, GameSummaryStatistics};
use crate::milestones::MilestoneDefinition;
use crate::databaseconnection;
use chrono::{Utc, DateTime};
use chrono_tz::Europe::Berlin;

pub const USER_NAME_MIN_LENGTH: usize = 3;
pub const USER_NAME_MAX_LENGTH: usize = 40;
pub const PASSWORD_MIN_LENGTH: usize = 4;

pub const AUHTORIZATION_HEADER_LABEL : &str = "Authorization";


#[derive(Debug, Clone, Copy)]
pub enum CallResultCode {
    Ok = 0,
    UserNotFound = 1,
    InvalidPassword = 2,
    UserAlreadyExists = 3,
    PokemonNotFound = 4,
    PokemonAlreadyFound = 5,
    InvalidToken = 6,
    UserNameTooShort = 7,
    UserNameTooLong = 8,
    PasswordToShort = 9,
    UserNotAdmin = 10,
} 


impl Serialize for CallResultCode {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_u32(*self as u32)
    }
}

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
    pub result_code: CallResultCode,
}

pub async fn login(info: web::Json<LoginRequest>) -> HttpResponse {
    info!("Login attempt for user: {}", info.id);
    
    let conn = match databaseconnection::get_conn(get_env_dbpath()) {
        Ok(c) => c,
        Err(e) => {
            error!("Failed to get database connection: {}", e);
            return HttpResponse::InternalServerError().json(LoginResponse {
                id: info.id.clone(),
                token: None,
                name: None,
                message: "Database connection failed".to_string(),
                result_code: CallResultCode::Ok,
            });
        }
    };
    
    let user_exists = databaseconnection::user_id_exists(&info.id, &conn).unwrap();
    if !user_exists {
        warn!("Login failed - user not found: {}", info.id);
        let response = LoginResponse {
            id: info.id.clone(),
            token: None,
            name: None,
            message: format!("Create new user first {}", info.id),
            result_code: CallResultCode::UserNotFound,
        };
        return HttpResponse::NotFound().json(response);
    }
    
    let (user, token) = match databaseconnection::login_and_get_user_by_id_pwd(&info.id, &info.password, &conn).unwrap() {
        Some((user, token)) => (user, token),
        None => {
            warn!("Login failed - invalid password for user: {}", info.id);
            let response = LoginResponse {
                id: info.id.clone(),
                token: None,
                name: None,
                message: "Invalid password".to_string(),
                result_code: CallResultCode::InvalidPassword,
            };
            return HttpResponse::Unauthorized().json(response);
        }
    };
    
    info!("Login successful for user: {} ({})", user.user_id, user.name);
    let response = LoginResponse {
        id: user.user_id,
        token: Some(token),
        name: Some(user.name.clone()),
        message: format!("Logged in as {}", user.name),
        result_code: CallResultCode::Ok,
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
    info!("User creation attempt - ID: {}, Name: {}, Name length: {}", 
          info.id, info.name, info.name.len());
    
    let conn = match databaseconnection::get_conn(get_env_dbpath()) {
        Ok(c) => c,
        Err(e) => {
            error!("Failed to get database connection: {}", e);
            return HttpResponse::InternalServerError().json(LoginResponse {
                id: info.id.clone(),
                name: None,
                token: None,
                message: "Database connection failed".to_string(),
                result_code: CallResultCode::Ok, // Should add a new error code for this
            });
        }
    };
    
    let user_exists = databaseconnection::user_id_exists(&info.id, &conn).unwrap();
    if user_exists {
        warn!("User creation failed - user already exists: {}", info.id);
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            token: None,
            message: format!("User already exists {}", info.id),
            result_code: CallResultCode::UserAlreadyExists,
        };
        return HttpResponse::BadRequest().json(response);
    }

    // check if name is too short or long
    if info.name.len() < USER_NAME_MIN_LENGTH {
        warn!("User creation failed - name too short: {} (length: {})", info.name, info.name.len());
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            token: None,
            message: format!("User name too short. Min length is {}", USER_NAME_MIN_LENGTH),
            result_code: CallResultCode::UserNameTooShort,
        };
        return HttpResponse::BadRequest().json(response);
    }

    if info.name.len() > USER_NAME_MAX_LENGTH {
        warn!("User creation failed - name too long: {} (length: {})", info.name, info.name.len());
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            token: None,
            message: format!("User name too long. Max length is {}", USER_NAME_MAX_LENGTH),
            result_code: CallResultCode::UserNameTooLong,
        };
        return HttpResponse::BadRequest().json(response);
    }

    // password check
    if info.password.len() < PASSWORD_MIN_LENGTH {
        warn!("User creation failed - password too short for user: {}", info.id);
        let response = LoginResponse {
            id: info.id.clone(),
            name: None,
            token: None,
            message: format!("Password too short. Min length is {}", PASSWORD_MIN_LENGTH),
            result_code: CallResultCode::PasswordToShort,
        };
        return HttpResponse::BadRequest().json(response);
    }

    // if good then create user
    match databaseconnection::create_user(&info.id, &info.name, &info.password, &conn) {
        Ok((user, token)) => {
            info!("User created successfully - ID: {}, Name: {}", user.user_id, user.name);
            let response = LoginResponse {
                id: user.user_id,
                name: Some(user.name.clone()),
                token: Some(token),
                message: format!("Created new user {}", user.name),
                result_code: CallResultCode::Ok,
            };
            HttpResponse::Ok().json(response)
        },
        Err(e) => {
            error!("Failed to create user {}: {}", info.id, e);
            HttpResponse::InternalServerError().json(LoginResponse {
                id: info.id.clone(),
                name: None,
                token: None,
                message: "Failed to create user".to_string(),
                result_code: CallResultCode::Ok, // Should add a new error code for this
            })
        }
    }
}


// validate password request
#[derive(Debug, Deserialize)]
pub struct VerifyPasswordRequest {
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct VerifyPasswordResponse {
    pub id: String,
    pub valid: bool,
    pub message: String,
    pub result_code: CallResultCode,
}

pub async fn validate_password(req: HttpRequest, info: web::Json<VerifyPasswordRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = VerifyPasswordResponse {
            id: user_id.clone(),
            valid: false,
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Unauthorized().json(response);
    }
    let valid = databaseconnection::validate_password(&user_id, &info.password, &conn).unwrap();

    if !valid {
        let response = VerifyPasswordResponse {
            id: user_id.clone(),
            valid: false,
            message: "Invalid password".to_string(),
            result_code: CallResultCode::InvalidPassword,
        };
        return HttpResponse::Unauthorized().json(response);
    }

    let response = VerifyPasswordResponse {
        id: user_id.clone(),
        valid: true,
        message: "Password is valid".to_string(),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}


// change password request
#[derive(Debug, Deserialize)]
pub struct SetPasswordRequest {
    pub old_password : String,
    pub new_password : String,
}

#[derive(Debug, Serialize)]
pub struct SetPasswordResponse {
    pub id: String,
    pub message: String,
    pub result_code: CallResultCode,
}

pub async fn set_user_password(req: HttpRequest, info: web::Json<SetPasswordRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = SetPasswordResponse {
            id : user_id.clone(),
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Unauthorized().json(response);
    }
    // check if user exists
    let user_exists = databaseconnection::user_id_exists(&user_id, &conn).unwrap();
    if !user_exists {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: format!("User does not exist {}", user_id),
            result_code: CallResultCode::UserNotFound,
        };
        return HttpResponse::NotFound().json(response);
    }

    // validate old password
    if !databaseconnection::validate_password(&user_id, &info.old_password, &conn).unwrap() {
        let response = SetPasswordResponse {
            id: user_id.clone(),
            message: "Invalid old password".to_string(),
            result_code: CallResultCode::InvalidPassword,
        };
        return HttpResponse::Unauthorized().json(response);
    }

    // check if new password is too short
    if info.new_password.len() < PASSWORD_MIN_LENGTH {
        let response = SetPasswordResponse {
            id: user_id.clone(),
            message: format!("New password too short. Min length is {}", PASSWORD_MIN_LENGTH),
            result_code: CallResultCode::PasswordToShort,
        };
        return HttpResponse::BadRequest().json(response);
    }

    // now set new password
    databaseconnection::set_user_password(&user_id, &info.new_password, &conn).unwrap();
    let response = SetPasswordResponse {
        id: user_id.clone(),
        message: "Password updated".to_string(),
        result_code: CallResultCode::Ok,
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
    pub result_code: CallResultCode,
}

pub async fn set_user_name(req: HttpRequest, info: web::Json<SetUserNameRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: "Invalid token.".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::BadRequest().json(response);
    }

    let user_exists = databaseconnection::user_id_exists(&user_id, &conn).unwrap();
    if !user_exists {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: format!("User does not exist {}", user_id),
            result_code: CallResultCode::UserNotFound,
        };
        return HttpResponse::BadRequest().json(response);
    }

    if info.name.len() < USER_NAME_MIN_LENGTH {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: format!("User name too short. Min length is {}", USER_NAME_MIN_LENGTH),
            result_code: CallResultCode::UserNameTooShort,
        };
        return HttpResponse::BadRequest().json(response);
    }

    if info.name.len() > USER_NAME_MAX_LENGTH {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: format!("User name too long. Max length is {}", USER_NAME_MAX_LENGTH),
            result_code: CallResultCode::UserNameTooLong,
        };
        return HttpResponse::BadRequest().json(response);
    }

    databaseconnection::set_user_name(&user_id, &info.name, &conn).unwrap();
    let response = SetUserNameResponse {
        id: user_id.clone(),
        name: Some(info.name.clone()),
        message: format!("Updated user name to '{}'", info.name),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}


#[derive(Debug, Serialize)]
pub struct LogoutResponse {
    pub logged_out: bool,
    pub message: String,
    pub result_code: CallResultCode,
}

pub async fn logout(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");

    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = LogoutResponse {
            logged_out: false,
            message: "Invalid token. Already logged out, it seems.".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::BadRequest().json(response);
    }
    databaseconnection::remove_token(&user_id, token, &conn).unwrap();
    let response = LogoutResponse {
        logged_out: true,
        message: "Logged out".to_string(),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}


// logout everywhere (remove all tokens for user)
pub async fn logout_everywhere(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = LogoutResponse {
            logged_out: false,
            message: "Invalid token.".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::BadRequest().json(response);
    }
    databaseconnection::remove_all_tokens_for_user(&user_id, &conn).unwrap();
    let response = LogoutResponse {
        logged_out: true,
        message: "Logged out everywhere".to_string(),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}

// to delete user
pub async fn delete_user(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        return HttpResponse::Unauthorized().finish();
    }
    let user_exists = databaseconnection::user_id_exists(&user_id, &conn).unwrap();
    if !user_exists {
        return HttpResponse::NotFound().finish();
    }
    databaseconnection::delete_user(&user_id, &conn).unwrap();
    HttpResponse::Ok().finish()
}


#[derive(Debug, Deserialize)]
pub struct FoundPokemonRequest {
    pub catch_code: String,
}

#[derive(Debug, Serialize)]
pub struct FoundPokemonResponse {
    pub user_id: String,
    pub pokemon_id: Option<u32>,
    pub message: String,
    pub result_code: CallResultCode,
    pub milestone_reached: Option<u32>, // Keep for backward compatibility
    pub milestones_achieved: Vec<MilestoneDefinition>,
}

pub async fn register_found_pokemon(req: HttpRequest, info: web::Json<FoundPokemonRequest>) -> HttpResponse {
    debug!("Pokemon catch attempt with catch code");
    
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    
    if !validate_token(&user_id, token, &conn) {
        warn!("Pokemon catch failed - invalid token for user: {}", user_id);
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: None,
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
            milestone_reached: None,
            milestones_achieved: Vec::new(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    
    let user_exists = databaseconnection::user_id_exists(&user_id, &conn).unwrap();
    if !user_exists {
        error!("Pokemon catch failed - user does not exist: {}", user_id);
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: None,
            message: format!("User does not exist {}", user_id),
            result_code: CallResultCode::UserNotFound,
            milestone_reached: None,
            milestones_achieved: Vec::new(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    
    let pokemon_exists = databaseconnection::check_if_pokemon_exists_by_catch_code(&info.catch_code, &conn).unwrap();
    if !pokemon_exists {
        warn!("Pokemon catch failed - invalid catch code for user: {}", user_id);
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: None,
            message: "Cannot find pokemon".to_string(),
            result_code: CallResultCode::PokemonNotFound,
            milestone_reached: None,
            milestones_achieved: Vec::new(),
        };
        return HttpResponse::BadRequest().json(response);
    }
    
    let pokemon = databaseconnection::get_pokemon_by_catch_code(&info.catch_code, &conn).unwrap();
    let found_before =
        databaseconnection::check_if_you_found_pokemon_before(&user_id, &info.catch_code, &conn).unwrap();
    if found_before {
        info!("Pokemon already caught - user: {}, pokemon: {} ({})", user_id, pokemon.name, pokemon.number);
        let response = FoundPokemonResponse {
            user_id: user_id.clone(),
            pokemon_id: Some(pokemon.number.clone()),
            message: format!("Already found pokemon"),
            result_code: CallResultCode::PokemonAlreadyFound,
            milestone_reached: None,
            milestones_achieved: Vec::new(),
        };
        return HttpResponse::Ok().json(response);
    }
    
    let milestones_achieved = databaseconnection::found_pokemon(&user_id, &info.catch_code, &conn).unwrap();
    info!("Pokemon caught successfully - user: {}, pokemon: {} ({})", user_id, pokemon.name, pokemon.number);
    
    // Keep backward compatibility with milestone_reached
    let milestone_reached = milestones_achieved.iter()
        .find(|m| m.milestone_type == crate::milestones::MilestoneType::CountBased)
        .and_then(|m| m.requirement.parse::<u32>().ok());
    
    let response = FoundPokemonResponse {
        user_id: user_id.clone(),
        pokemon_id: Some(pokemon.number.clone()),
        message: format!("Caught {} (#{})", pokemon.name, pokemon.number),
        result_code: CallResultCode::Ok,
        milestone_reached,
        milestones_achieved,
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
    pub result_code: CallResultCode,
}

pub async fn view_found_pokemon(req: HttpRequest, info: web::Json<ViewFoundPokemonRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = ViewFoundPokemonResponse {
            id: user_id.clone(),
            pokemon_found: vec![],
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::BadRequest().json(response);
    }
    let user_exists = databaseconnection::user_id_exists(&user_id, &conn).unwrap();
    if !user_exists {
        let response = ViewFoundPokemonResponse {
            id: user_id.clone(),
            pokemon_found: vec![],
            message: format!("User does not exist {}", user_id),
            result_code: CallResultCode::UserNotFound,
        };
        return HttpResponse::BadRequest().json(response);
    }
    let pokemon = databaseconnection::view_found_pokemon(&user_id, info.n, &conn).unwrap();
    let response = ViewFoundPokemonResponse {
        id: user_id.clone(),
        pokemon_found: pokemon,
        message: format!("Found pokemon {}", user_id),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}


#[derive(Debug, Serialize)]
pub struct GetHighScoreResponse {
    pub user_scores : Vec<UserScore>,
    pub result_code: CallResultCode,
}

pub async fn get_statistics_highscore() -> HttpResponse  {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let scores = databaseconnection::statistics_users_most_found(10, &conn).unwrap();
    let res = 
        GetHighScoreResponse {
            user_scores : scores,
            result_code: CallResultCode::Ok,
        };
    HttpResponse::Ok().json(res)
}

// Paginated highscores endpoints (public, no auth required)
#[derive(Debug, Deserialize)]
pub struct GetHighscoresRequest {
    pub page: u32,
    pub per_page: Option<u32>,
}

#[derive(Debug, Serialize)]
pub struct GetHighscoresResponse {
    pub scores: Vec<UserScore>,
    pub total_count: u32,
    pub page: u32,
    pub per_page: u32,
    pub total_pages: u32,
    pub result_code: CallResultCode,
}

pub async fn get_highscores(query: web::Query<GetHighscoresRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    
    let per_page = query.per_page.unwrap_or(20).min(50); // Max 50 per page
    let page = query.page.max(1); // Ensure page is at least 1
    let offset = (page - 1) * per_page;
    
    let scores = databaseconnection::get_highscores_paginated(per_page, offset, &conn).unwrap();
    let total_count = databaseconnection::get_highscores_total_count(&conn).unwrap();
    let total_pages = (total_count + per_page - 1) / per_page; // Ceiling division
    
    let res = GetHighscoresResponse {
        scores,
        total_count,
        page,
        per_page,
        total_pages,
        result_code: CallResultCode::Ok,
    };
    
    HttpResponse::Ok().json(res)
}

#[derive(Debug, Deserialize)]
pub struct SearchHighscoresRequest {
    pub search: String,
    pub page: u32,
    pub per_page: Option<u32>,
}

pub async fn search_highscores(query: web::Query<SearchHighscoresRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    
    let per_page = query.per_page.unwrap_or(20).min(50); // Max 50 per page
    let page = query.page.max(1); // Ensure page is at least 1
    let offset = (page - 1) * per_page;
    
    let scores = databaseconnection::get_highscores_filtered(&query.search, per_page, offset, &conn).unwrap();
    let total_count = databaseconnection::get_highscores_filtered_count(&query.search, &conn).unwrap();
    let total_pages = (total_count + per_page - 1) / per_page; // Ceiling division
    
    let res = GetHighscoresResponse {
        scores,
        total_count,
        page,
        per_page,
        total_pages,
        result_code: CallResultCode::Ok,
    };
    
    HttpResponse::Ok().json(res)
}


#[derive(Debug, Serialize)]
pub struct GetLatestFoundPokemonResponse {
    pub found_pokemon : Vec<FoundPkmn>,
    pub result_code: CallResultCode,
}

pub async fn get_statistics_latest_pokemon_found() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let found_pokemon = databaseconnection::statistics_latest_pokemon_found(10, &conn).unwrap();
    let res = GetLatestFoundPokemonResponse {
        found_pokemon : found_pokemon,
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(res)
}

#[derive(Debug, Serialize)]
pub struct GetUserResponse {
    pub user: Option<User>,
    pub message: String,
    pub result_code: CallResultCode,
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
                result_code: CallResultCode::Ok,
            };
            HttpResponse::Ok().json(res)
        },
        None => {
            let res = GetUserResponse {
                user: None,
                message: format!("User not found {}", user_id),
                result_code: CallResultCode::UserNotFound,
            };
            HttpResponse::NotFound().json(res)
        }
    }
}

// get num users
pub async fn num_users() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let num_users = databaseconnection::get_num_users(&conn).unwrap();
    HttpResponse::Ok().body(num_users.to_string())
}


// get many users

#[derive(Debug, Deserialize)]
pub struct GetUsersRequest {
    pub n: u32,
    pub skip: u32,
}

#[derive(Debug, Serialize)]
pub struct GetUsersResponse {
    pub users: Vec<User>,
    pub message: String,
    pub result_code: CallResultCode,
}

pub async fn get_users(req: HttpRequest, info: web::Json<GetUsersRequest>) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    let valid_token = validate_token(&user_id, token, &conn);
    if !valid_token {
        let response = GetUsersResponse {
            users: vec![],
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Unauthorized().json(response);
    }
    if !is_admin {
        let response = GetUsersResponse {
            users: vec![],
            message: "Only admin can read all users".to_string(),
            result_code: CallResultCode::UserNotAdmin,
        };
        return HttpResponse::Forbidden().json(response);
    }
    
    let users = databaseconnection::get_users(info.n, info.skip, &conn).unwrap();
    let num_users = users.len();
    let res = GetUsersResponse {
        users: users,
        message: format!("Got {} users", num_users),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(res)
}

// get many users filter by id
#[derive(Debug, Deserialize)]
pub struct GetUsersFilterRequest {
    pub filter: String,
    pub n: u32,
}

pub async fn get_users_filter_id(req : HttpRequest, info: web::Json<GetUsersFilterRequest>) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    let valid_token = validate_token(&user_id, token, &conn);
    if !valid_token {
        let response = GetUsersResponse {
            users: vec![],
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Forbidden().json(response);
    }
    if !is_admin {
        let response = GetUsersResponse {
            users: vec![],
            message: "Only admin can read all users".to_string(),
            result_code: CallResultCode::UserNotAdmin,
        };
        return HttpResponse::Forbidden().json(response);
    }
    let filter = format!("%{}%", info.filter);
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let users = databaseconnection::get_users_filter_id(&filter, info.n, &conn).unwrap();
    let num_users = users.len();
    let res = GetUsersResponse {
        users: users,
        message: format!("Got {} users", num_users),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(res)
}

pub async fn get_users_filter_id_name(req: HttpRequest, info: web::Json<GetUsersFilterRequest>) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    let valid_token = validate_token(&user_id, token, &conn);
    if !valid_token {
        let response = GetUsersResponse {
            users: vec![],
            message: "Invalid token".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Forbidden().json(response);
    }
    if !is_admin {
        let response = GetUsersResponse {
            users: vec![],
            message: "Only admin can read all users".to_string(),
            result_code: CallResultCode::UserNotAdmin,
        };
        return HttpResponse::Forbidden().json(response);
    }
    let filter = format!("%{}%", info.filter);
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let users = databaseconnection::get_users_filter_id_name(&filter, info.n, &conn).unwrap();
    let num_users = users.len();
    let res = GetUsersResponse {
        users: users,
        message: format!("Got {} users", num_users),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(res)
}


// user exists request
#[derive(Debug, Serialize)]
pub struct UserExistsResponse {
    pub exists: bool,
    pub result_code: CallResultCode,
}

pub async fn user_exists(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let exists = databaseconnection::user_id_exists(&user_id, &conn).unwrap();
    let res = UserExistsResponse {
        exists: exists,
        result_code: CallResultCode::Ok,
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
            HttpResponse::Ok().json(pokemon)
        },
        None => {
            HttpResponse::NotFound().finish()
        }
    }
}


// get user ranking
pub async fn get_user_ranking(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    // first check if user exists
    if !databaseconnection::user_id_exists(&user_id, &databaseconnection::get_conn(get_env_dbpath()).unwrap()).unwrap() {
        return HttpResponse::NotFound().finish();
    }
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let ranking = databaseconnection::user_ranking(&user_id, &conn).unwrap();
    HttpResponse::Ok().json(ranking)
}

// get my pokedex
#[derive(Debug, Serialize)]
struct MyPokedexResponse {
    pokedex: Vec<Pkmn>,
    result_code: CallResultCode,
}

pub async fn get_my_pokedex(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();

    let user_id = misc::get_user_id_from_token(token).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = SetUserNameResponse {
            id: user_id.clone(),
            name: None,
            message: "Invalid token.".to_string(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::BadRequest().json(response);
    }
    let pokedex = databaseconnection::user_pokedex(&user_id, &conn).unwrap();
    let res = MyPokedexResponse {
        pokedex: pokedex,
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(res)
}

pub async fn get_user_pokedex(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    // first check if user exists
    if !databaseconnection::user_id_exists(&user_id, &databaseconnection::get_conn(get_env_dbpath()).unwrap()).unwrap() {
        return HttpResponse::NotFound().finish();
    }
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let pokedex = databaseconnection::user_pokedex(&user_id, &conn).unwrap();
    HttpResponse::Ok().json(pokedex)
}

pub async fn get_user_milestones(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    // first check if user exists
    if !databaseconnection::user_id_exists(&user_id, &databaseconnection::get_conn(get_env_dbpath()).unwrap()).unwrap() {
        return HttpResponse::NotFound().finish();
    }
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let milestones = databaseconnection::get_user_milestones(&user_id, &conn).unwrap();
    HttpResponse::Ok().json(milestones)
}

pub async fn get_user_milestone_definitions(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    // first check if user exists
    if !databaseconnection::user_id_exists(&user_id, &databaseconnection::get_conn(get_env_dbpath()).unwrap()).unwrap() {
        return HttpResponse::NotFound().finish();
    }
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let milestone_definitions = databaseconnection::get_user_milestone_definitions(&user_id, &conn).unwrap();
    HttpResponse::Ok().json(milestone_definitions)
}

pub async fn validate_token_request(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        return HttpResponse::Unauthorized().finish();
    }
    HttpResponse::Ok().finish()
}

// Get Pokemon count by type for a specific user
pub async fn get_user_pokemon_by_type(path: web::Path<String>) -> HttpResponse {
    let user_id = path.into_inner();
    // first check if user exists
    if !databaseconnection::user_id_exists(&user_id, &databaseconnection::get_conn(get_env_dbpath()).unwrap()).unwrap() {
        return HttpResponse::NotFound().finish();
    }
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let type_stats = databaseconnection::user_pokemon_by_type(&user_id, &conn).unwrap();
    HttpResponse::Ok().json(type_stats)
}

// Get total Pokemon catches by type across all users
pub async fn get_total_pokemon_by_type() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let type_stats = databaseconnection::total_pokemon_by_type(&conn).unwrap();
    HttpResponse::Ok().json(type_stats)
}

// Get Pokemon found counts (public endpoint)
#[derive(Debug, Serialize)]
pub struct GetPokemonFoundCountsResponse {
    pub pokemon_counts: Vec<PokemonFoundCount>,
    pub result_code: CallResultCode,
}

pub async fn get_pokemon_found_counts() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let counts = databaseconnection::get_pokemon_found_counts(&conn).unwrap();
    let res = GetPokemonFoundCountsResponse {
        pokemon_counts: counts,
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(res)
}

// admin endpoints

#[derive(Debug, Serialize)]
pub struct AmIAdminResponse {
    pub is_admin: bool,
    pub user_id: String,
    pub result_code: CallResultCode,
}

pub async fn am_i_admin(req: HttpRequest) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = AmIAdminResponse {
            is_admin: false,
            user_id: user_id.clone(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Unauthorized().json(response);
    }
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    let response = AmIAdminResponse {
        is_admin,
        user_id: user_id.clone(),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Serialize)]
pub struct IsUserAdminResponse {
    pub is_admin: bool,
    pub user_id: String,
    pub result_code: CallResultCode,
}

pub async fn is_user_admin(req: HttpRequest, path: web::Path<String>) -> HttpResponse {
    let target_user_id = path.into_inner();
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        let response = IsUserAdminResponse {
            is_admin: false,
            user_id: target_user_id.clone(),
            result_code: CallResultCode::InvalidToken,
        };
        return HttpResponse::Unauthorized().json(response);
    }
    let requesting_user_is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    if !requesting_user_is_admin {
        let response = IsUserAdminResponse {
            is_admin: false,
            user_id: target_user_id.clone(),
            result_code: CallResultCode::UserNotAdmin,
        };
        return HttpResponse::Forbidden().json(response);
    }
    let target_is_admin = databaseconnection::user_is_admin(&target_user_id, &conn).unwrap();
    let response = IsUserAdminResponse {
        is_admin: target_is_admin,
        user_id: target_user_id.clone(),
        result_code: CallResultCode::Ok,
    };
    HttpResponse::Ok().json(response)
}

// make user admin
#[derive(Debug, Deserialize)]
pub struct MakeUserAdminRequest {
    pub id : String,
}

pub async fn make_user_admin(req: HttpRequest, info: web::Json<MakeUserAdminRequest>) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        return HttpResponse::Unauthorized().finish();
    }
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    if !is_admin {
        return HttpResponse::Forbidden().finish();
    }

    // now make user admin
    let worked = databaseconnection::make_user_admin(&info.id, &conn).is_ok();
    HttpResponse::Ok().body(worked.to_string())
}

pub async fn make_user_not_admin(req: HttpRequest, info: web::Json<MakeUserAdminRequest>) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        return HttpResponse::Unauthorized().finish();
    }
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    if !is_admin {
        return HttpResponse::Forbidden().finish();
    }
    if user_id == info.id {
        return HttpResponse::BadRequest().body("Cannot remove own admin status");
    }
    if user_id != "admin" {
        return HttpResponse::BadRequest().body("Only root admin account can demote other admins");
    }

    // now make user admin
    let worked = databaseconnection::make_user_not_admin(&info.id, &conn).is_ok();
    HttpResponse::Ok().body(worked.to_string())
}

// reset user password
#[derive(Debug, Deserialize)]
pub struct ResetUserPasswordRequest {
    pub id: String,
    pub new_password: String,
}

pub async fn admin_reset_user_password(req: HttpRequest, info: web::Json<ResetUserPasswordRequest>) -> HttpResponse {
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        return HttpResponse::Unauthorized().finish();
    }
    let user_exists = databaseconnection::user_id_exists(&info.id, &conn).unwrap();
    if !user_exists {
        return HttpResponse::NotFound().finish();
    }
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    if !is_admin {
        return HttpResponse::Forbidden().finish();
    }
    let worked = databaseconnection::set_user_password(&info.id, &info.new_password, &conn).is_ok();
    HttpResponse::Ok().body(worked.to_string())
}

// admin delete user request
#[derive(Debug, Deserialize)]
pub struct AdminDeleteUserRequest {
    pub id: String,
}

pub async fn admin_delete_user(req: HttpRequest, info: web::Json<AdminDeleteUserRequest>) -> HttpResponse {
    let target_user_id = &info.id;
    let token = req.headers().get(AUHTORIZATION_HEADER_LABEL)
        .and_then(|hv| hv.to_str().ok())
        .unwrap_or("");
    let user_id = misc::get_user_id_from_token(token).unwrap();
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    if !validate_token(&user_id, token, &conn) {
        return HttpResponse::Unauthorized().finish();
    }
    let user_exists = databaseconnection::user_id_exists(target_user_id, &conn).unwrap();
    if !user_exists {
        return HttpResponse::NotFound().finish();
    }
    let is_admin = databaseconnection::user_is_admin(&user_id, &conn).unwrap();
    if !is_admin {
        return HttpResponse::Forbidden().finish();
    }
    let worked = databaseconnection::delete_user(target_user_id, &conn).is_ok();
    HttpResponse::Ok().body(worked.to_string())
}

// Game status endpoints (no authentication required)
pub async fn is_game_over() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    
    let game_end_time_str = databaseconnection::get_setting("game_end_time", &conn).unwrap();
    let current_time = Utc::now();
    
    let (is_over, end_time_utc) = if let Some(end_time_str) = game_end_time_str {
        match DateTime::parse_from_str(&format!("{} +02:00", end_time_str), "%Y-%m-%d %H:%M:%S %z") {
            Ok(end_time) => {
                let end_time_utc = end_time.with_timezone(&Utc);
                (current_time > end_time_utc, Some(end_time_utc))
            },
            Err(_) => (false, None)
        }
    } else {
        (false, None)
    };
    
    let response = GameStatusResponse {
        is_game_over: is_over,
        current_time,
        game_end_time: end_time_utc,
    };
    
    HttpResponse::Ok().json(response)
}

pub async fn has_game_started() -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    
    let game_start_time_str = databaseconnection::get_setting("game_start_time", &conn).unwrap();
    let current_time = Utc::now();
    
    let (has_started, start_time_utc) = if let Some(start_time_str) = game_start_time_str {
        match DateTime::parse_from_str(&format!("{} +02:00", start_time_str), "%Y-%m-%d %H:%M:%S %z") {
            Ok(start_time) => {
                let start_time_utc = start_time.with_timezone(&Utc);
                (current_time > start_time_utc, Some(start_time_utc))
            },
            Err(_) => (true, None) // Default to started if parsing fails
        }
    } else {
        (true, None) // Default to started if no setting found
    };
    
    let response = GameStartStatusResponse {
        has_game_started: has_started,
        current_time,
        game_start_time: start_time_utc,
    };
    
    HttpResponse::Ok().json(response)
}

pub async fn get_server_time() -> HttpResponse {
    let current_time_utc = Utc::now();
    let current_time_cet = current_time_utc.with_timezone(&Berlin);
    
    let response = ServerTimeResponse {
        server_time_utc: current_time_utc,
        server_time_cet: current_time_cet.format("%Y-%m-%d %H:%M:%S %Z").to_string(),
    };
    
    HttpResponse::Ok().json(response)
}

#[derive(Debug, Deserialize)]
pub struct GameSummaryQuery {
    pub datetime0: Option<String>,
    pub datetime1: Option<String>,
}

pub async fn get_game_summary_statistics(query: web::Query<GameSummaryQuery>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    
    // Get all statistics
    let total_users = databaseconnection::get_num_users(&conn).unwrap() as u32;
    let users_10_plus = databaseconnection::count_users_with_pokemon_threshold(10, &conn).unwrap();
    let users_100_plus = databaseconnection::count_users_with_pokemon_threshold(100, &conn).unwrap();
    let total_pokemon_caught = databaseconnection::count_total_pokemon_caught(&conn).unwrap();
    
    let datetime0_ref = query.datetime0.as_deref();
    let datetime1_ref = query.datetime1.as_deref();
    
    let catches_per_hour = databaseconnection::get_catches_per_hour(datetime0_ref, datetime1_ref, &conn).unwrap();
    let catches_per_day = databaseconnection::get_catches_per_day(datetime0_ref, datetime1_ref, &conn).unwrap();
    let first_catch = databaseconnection::get_first_catch(datetime0_ref, datetime1_ref, &conn).unwrap();
    let last_catch = databaseconnection::get_last_catch(datetime0_ref, datetime1_ref, &conn).unwrap();
    let longest_survivor = databaseconnection::get_longest_survivor_pokemon(datetime0_ref, datetime1_ref, &conn).unwrap();
    
    let top_10_players = databaseconnection::statistics_users_most_found(10, &conn).unwrap();
    let most_caught = databaseconnection::get_most_caught_pokemon(10, &conn).unwrap();
    let least_caught = databaseconnection::get_least_caught_pokemon(10, &conn).unwrap();
    
    let response = GameSummaryStatistics {
        total_users_registered: total_users,
        users_with_10_plus_catches: users_10_plus,
        users_with_100_plus_catches: users_100_plus,
        total_pokemon_caught,
        catches_per_hour,
        catches_per_day,
        first_catch,
        last_catch,
        longest_survivor,
        top_10_players,
        most_caught_pokemon: most_caught,
        least_caught_pokemon: least_caught,
        time_window_start: datetime0_ref.and_then(|s| DateTime::parse_from_str(&format!("{} +02:00", s), "%Y-%m-%d %H:%M:%S %z").ok().map(|dt| dt.with_timezone(&Utc))),
        time_window_end: datetime1_ref.and_then(|s| DateTime::parse_from_str(&format!("{} +02:00", s), "%Y-%m-%d %H:%M:%S %z").ok().map(|dt| dt.with_timezone(&Utc))),
    };
    
    HttpResponse::Ok().json(response)
}

// registers all routes.
pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.route("/login", web::post().to(login))
        .route("/logout", web::post().to(logout))
        .route("/logout_everywhere", web::post().to(logout_everywhere))
        .route("/create_user", web::post().to(create_user))
        .route("/set_password", web::post().to(set_user_password))
        .route("/set_user_name", web::post().to(set_user_name))
        .route("/validate_password", web::post().to(validate_password))
        .route("/validate_token", web::post().to(validate_token_request))
        .route("/found_pokemon", web::post().to(register_found_pokemon))
        .route("/view_found_pokemon", web::post().to(view_found_pokemon))
        .route("/statistics_highscore", web::get().to(get_statistics_highscore))
        .route("/statistics_latest_pokemon_found", web::get().to(get_statistics_latest_pokemon_found))
        .route("/highscores", web::get().to(get_highscores))
        .route("/highscores/search", web::get().to(search_highscores))
        .route("/get_user/{user_id}", web::get().to(get_user))
        .route("/num_users", web::get().to(num_users))
        .route("/get_pokemon/{number}", web::get().to(get_pokemon))
        .route("/user_exists/{user_id}", web::get().to(user_exists))
        .route("/user_ranking/{user_id}", web::get().to(get_user_ranking))
        .route("/my_pokedex", web::get().to(get_my_pokedex))
        .route("/user_pokedex/{user_id}", web::get().to(get_user_pokedex))
        .route("/user_milestones/{user_id}", web::get().to(get_user_milestones))
        .route("/user_milestone_definitions/{user_id}", web::get().to(get_user_milestone_definitions))
        .route("/user_pokemon_by_type/{user_id}", web::get().to(get_user_pokemon_by_type))
        .route("/total_pokemon_by_type", web::get().to(get_total_pokemon_by_type))
        .route("/pokemon_found_counts", web::get().to(get_pokemon_found_counts))
        // admin endpoints
        .route("/am_i_admin", web::get().to(am_i_admin))
        .route("/is_user_admin/{user_id}", web::get().to(is_user_admin))
        .route("/make_user_admin", web::post().to(make_user_admin))
        .route("/make_user_not_admin", web::post().to(make_user_not_admin))
        .route("/admin_reset_user_password", web::post().to(admin_reset_user_password))
        .route("/admin_delete_user", web::post().to(admin_delete_user))
        .route("/get_users", web::post().to(get_users))
        .route("/get_users_filter_id", web::post().to(get_users_filter_id))
        .route("/get_users_filter", web::post().to(get_users_filter_id_name)) // this is probably the one to use
        // game status endpoints (no auth required)
        .route("/is_game_over", web::get().to(is_game_over))
        .route("/has_game_started", web::get().to(has_game_started))
        .route("/server_time", web::get().to(get_server_time))
        .route("/statistics/game_summary", web::get().to(get_game_summary_statistics))
        ;
}

