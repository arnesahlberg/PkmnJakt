use std::string;

use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use chrono_tz::{Europe::Berlin, Tz}; // CET is represented by Berlin timezone
use crate::milestones::MilestoneDefinition;



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
    pub rating: Option<i32>,
    pub types: Vec<String>,  // Array of types like ["Fire", "Flying"]
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
    pub types: Vec<String>,  // Array of types like ["Fire", "Flying"]
}


#[derive(Debug, Serialize)]
pub struct UserScore {
    pub id : String,
    pub name : String,
    pub score : u32,
    pub latest_found : DateTime<Utc>,
}

impl UserScore {
    pub fn cet_latest_found(&self) -> DateTime<Tz> {
        let cet_timezone: Tz = Berlin;
        self.latest_found.with_timezone(&cet_timezone)
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Milestone {
    pub milestone_count: u32,
    pub achieved_at: DateTime<Utc>,
}

impl Milestone {
    pub fn cet_achieved_at(&self) -> DateTime<Tz> {
        let cet_timezone: Tz = Berlin;
        self.achieved_at.with_timezone(&cet_timezone)
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct UserTypeStats {
    pub user_id: String,
    pub user_name: String,
    pub type_name: String,
    pub pokemon_count: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct TypeStats {
    pub type_name: String,
    pub total_catches: u32,
}