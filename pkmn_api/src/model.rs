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


#[derive(Debug, Deserialize, Serialize)]
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

#[derive(Debug, Deserialize, Serialize)]
pub struct PokemonFoundCount {
    pub pokemon_name: String,
    pub pokemon_number: u32,
    pub count: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct PokemonAdminEntry {
    pub id: u32,
    pub name: String,
    pub active: bool,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GameStatusResponse {
    pub is_game_over: bool,
    pub current_time: DateTime<Utc>,
    pub game_end_time: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GameStartStatusResponse {
    pub has_game_started: bool,
    pub current_time: DateTime<Utc>,
    pub game_start_time: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct ServerTimeResponse {
    pub server_time_utc: DateTime<Utc>,
    pub server_time_cet: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct HourlyCatchStats {
    pub hour: u32,
    pub catches: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct FirstLastCatch {
    pub user_name: String,
    pub pokemon_name: String,
    pub pokemon_number: u32,
    pub caught_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct PokemonCatchStats {
    pub pokemon_name: String,
    pub pokemon_number: u32,
    pub times_caught: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DailyCatchStats {
    pub date: String,  // YYYY-MM-DD format
    pub weekday: String,  // Swedish weekday name
    pub day_number: u32,  // Day of month
    pub catches: u32,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct GameSummaryStatistics {
    pub total_users_registered: u32,
    pub users_with_10_plus_catches: u32,
    pub users_with_100_plus_catches: u32,
    pub total_pokemon_caught: u32,
    pub catches_per_hour: Vec<HourlyCatchStats>,
    pub catches_per_day: Vec<DailyCatchStats>,
    pub first_catch: Option<FirstLastCatch>,
    pub last_catch: Option<FirstLastCatch>,
    pub longest_survivor: Option<FirstLastCatch>,
    pub top_10_players: Vec<UserScore>,
    pub most_caught_pokemon: Vec<PokemonCatchStats>,
    pub least_caught_pokemon: Vec<PokemonCatchStats>,
    pub time_window_start: Option<DateTime<Utc>>,
    pub time_window_end: Option<DateTime<Utc>>,
}
