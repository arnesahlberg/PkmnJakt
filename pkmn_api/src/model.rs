use std::string;

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use chrono_tz::{Europe::Berlin, Tz}; // CET is represented by Berlin timezone



#[derive(Debug, Deserialize, Serialize)]
pub struct User {
    pub user_id: String,
    pub name: String,
    pub email: Option<String>,
    pub phone : Option<String>,
    pub admin : bool,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Token {
    pub encoded_token : String,
    pub valid_until : DateTime<Utc>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct FoundPkmn {
    pub found_by_user: User,
    pub name: String,
    pub number: u32,
    pub time_found: DateTime<Utc>,
    pub photo_path: Option<String>,
    pub comment: Option<String>,
    pub rating: Option<i32>
}


impl FoundPkmn {
    pub fn cet_time_found(&self) -> DateTime<Tz> {
        let cet_timezone: Tz = Berlin;
        self.time_found.with_timezone(&cet_timezone)
    }
}


#[derive(Debug, Deserialize, Serialize)]
pub struct Pkmn {
    pub name: String,
    pub number: u32,
    pub photo_path: Option<String>,
    pub description: Option<String>,
    pub height: f32,
}


#[derive(Debug, Serialize)]
pub struct UserScore {
    pub id : String,
    pub name : String,
    pub score : u32
}

