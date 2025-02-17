
use serde::{de, Deserialize, Serialize};
use actix_web::{web, App, HttpResponse, HttpServer};


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



async fn login (info : web::Json<LoginRequest>) -> HttpResponse {
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if user_exists {
        let user = databaseconnection::get_user_by_id_str(&info.id, &conn).unwrap().unwrap();
        let response = LoginResponse {
            id : user.user_id,
            name : Some(user.name.clone()),
            message : format!("Logged in as {}", user.name),
        };
        HttpResponse::Ok().json(response)
    } else {
        let response = LoginResponse {
            id : info.id.clone(),
            name : None,
            message : format!("Create new user first {}", info.id),
        };
        HttpResponse::Ok().json(response)
    }
}

#[derive(Debug, Deserialize)]
struct CreateUserRequest {
    id : String,
    name : String
}

async fn create_user (info : web::Json<CreateUserRequest>) -> HttpResponse {
    // implement database logic here
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if user_exists {
        let response = LoginResponse {
            id : info.id.clone(),
            name : None,
            message : format!("User already exists {}", info.id),
        };
        HttpResponse::Ok().json(response)
    } else {
        databaseconnection::create_user(&info.id, &info.name, &conn).unwrap();
        let response = LoginResponse {
            id : info.id.clone(),
            name : Some(info.name.clone()),
            message : format!("Created new user {}", info.name),
        };
        HttpResponse::Ok().json(response)
    }
}

#[derive(Debug, Deserialize)]
struct SetUserNameRequest {
    id : String,
    name : String
}

async fn set_user_name (info : web::Json<SetUserNameRequest>) -> HttpResponse {
    // implement database logic here
    let conn = databaseconnection::get_conn(get_env_dbpath()).unwrap();
    let user_exists = databaseconnection::user_exists(&info.id, &conn).unwrap();
    if user_exists {
        databaseconnection::set_user_name(&info.id, &info.name, &conn).unwrap();
        let response = LoginResponse {
            id : info.id.clone(),
            name : Some(info.name.clone()),
            message : format!("Updated user name {}", info.name),
        };
        HttpResponse::Ok().json(response)
    } else {
        let response = LoginResponse {
            id : info.id.clone(),
            name : None,
            message : format!("User does not exist {}", info.id),
        };
        HttpResponse::Ok().json(response)
    }
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



#[actix_web::main]
async fn main() -> std::io::Result<()> {
    HttpServer::new(|| {
        App::new()
            .route("/login", web::post().to(login)) 
            .route("/logout", web::post().to(logout))
            .route("/create_user", web::post().to(create_user))
            .route("/set_user_name", web::post().to(set_user_name))
    })
    .bind(("127.0.0.1", 8080))?
    .run()
    .await
}