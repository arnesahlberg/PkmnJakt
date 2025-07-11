
use chrono::{Utc, Duration};
use chrono_tz::Europe::Stockholm;
use rusqlite::{params, Connection, Result};
use crate::model::{FoundPkmn, Pkmn, Token, User, UserScore, UserTypeStats, TypeStats, PokemonFoundCount};
use crate::misc::{self, create_token};
use crate::milestones::{MilestoneDefinition, get_count_milestone_for_count, get_type_milestone_for_type, get_pokemon_milestone};

// Helper function to parse types string into vector
fn parse_types(types_str: Option<String>) -> Vec<String> {
    match types_str {
        Some(types) => types.split('/').map(|s| s.trim().to_string()).collect(),
        None => vec![],
    }
}


pub fn get_conn (path : String) -> Result<Connection> {
    Connection::open(path)
}

pub fn user_id_exists(user_id : &str, conn : &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE User_Id = ?1")?;
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn user_name_exists(name : &str, conn : &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE name = ?1")?;
    let count : i32 = stmt.query_row(params![name], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn user_is_admin(user_id : &str, conn : &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE user_id = ?1 AND admin")?;
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn make_user_admin(user_id : &str, conn : &Connection) -> Result<()> {
    conn.execute("UPDATE Users SET admin = 1 WHERE user_id = ?1", params![user_id])?;
    Ok(())
}

pub fn make_user_not_admin(user_id : &str, conn : &Connection) -> Result<()> {
    if user_id == "admin" {
        return Err(rusqlite::Error::InvalidParameterName("Can't remove admin status from admin user".to_string()));
    }
    conn.execute("UPDATE Users SET admin = 0 WHERE user_id = ?1", params![user_id])?;
    Ok(())
}

pub fn get_num_users(conn : &Connection) -> Result<i32> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM ViewUsers")?;
    let count : i32 = stmt.query_row([], |row| row.get(0))?;
    Ok(count)
}

pub fn remove_token(user_id : &str, token : &str, conn : &Connection) -> Result<()> {
    conn.execute("DELETE FROM Tokens WHERE Token = ?1 AND User_Id = ?2", params![token, user_id])?;
    Ok(())
}

pub fn remove_all_tokens_for_user(user_id : &str, conn : &Connection) -> Result<()> {
    conn.execute("DELETE FROM Tokens WHERE User_Id = ?1", params![user_id])?;
    Ok(())
}

fn get_user_salt(user_id : &str, conn : &Connection) -> Result<String> {
    let mut stmt = conn.prepare("SELECT password_salt FROM Users WHERE user_id = ?1")?;
    let salt : String = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(salt)
}

pub fn get_users(num : u32, skip: u32, conn : &Connection) -> Result<Vec<User>> {
    let mut stmt = conn.prepare("SELECT UserId, User, Email, Phone, Admin FROM ViewUsers LIMIT ?1 OFFSET ?2")?;
    let rows = stmt.query_map(params![num, skip], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
            admin: row.get(4)?,
        })
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}

pub fn get_users_filter_id(id_filter : &str, num : u32, conn : &Connection) -> Result<Vec<User>> {
    let mut stmt = conn.prepare("SELECT UserId, User, Email, Phone, Admin FROM ViewUsers WHERE UserId LIKE ?1 LIMIT ?2")?;
    let rows = stmt.query_map(params![id_filter, num], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
            admin: row.get(4)?,
        })
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}

pub fn get_users_filter_id_name(filter: &str, num : u32, conn : &Connection) -> Result<Vec<User>> {
    let mut stmt = conn.prepare("SELECT UserId, User, Email, Phone, Admin FROM ViewUsers WHERE UserId LIKE ?1 OR User LIKE ?1 LIMIT ?2")?;
    let rows = stmt.query_map(params![filter, num], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
            admin: row.get(4)?,
        })
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}


pub fn delete_user(user_id : &str, conn : &Connection) -> Result<()> {
    if user_id == "admin" {
        return Err(rusqlite::Error::InvalidParameterName("Can't delete admin user".to_string()));
    }
    // first delete tokens and pokemon for user
    conn.execute("DELETE FROM Tokens WHERE user_id = ?1", params![user_id])?;
    conn.execute("DELETE FROM FoundPokemon WHERE user_id = ?1", params![user_id])?;
    conn.execute("DELETE FROM Users WHERE user_id = ?1", params![user_id])?;
    Ok(())
}

pub fn login_and_get_user_by_id_pwd(user_id: &str, pwd: &str, conn: &Connection) -> Result<Option<(User, Token)>> {
    // need to fetch user's password salt from database and then hash the password
    let salt = get_user_salt(user_id, conn)?;
    let hashed = misc::hash_password_with_salt(pwd, &salt);

    let mut stmt = conn.prepare(
        "SELECT user_id, name, email, phone, admin FROM Users WHERE user_id = ?1 AND password_hash = ?2"
    )?;

    let user_iter = stmt.query_map(params![user_id, hashed],  |row| {
        Ok(User{
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
            admin: row.get(4)?,
        })
    })?;

    for user in user_iter {
        // create token and return
        let valid_until = Utc::now() + Duration::days(7);
        let encoded_token = create_token(user_id, valid_until, conn).unwrap();
        let token = Token {
            encoded_token : encoded_token,
            valid_until : valid_until,
        };

        return Ok(Some((user?, token)));
    }
    Ok(None)
}

pub fn get_user_by_id_str(user_id: &str, conn: &Connection) -> Result<Option<User>> {
    let mut stmt = conn.prepare(
        "SELECT user_id, name, email, phone, admin FROM Users WHERE user_id = ?1",
    )?;

    let user_iter = stmt.query_map(params![user_id], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
            admin: row.get(4)?,
        })
    })?;

    // return if one exists
    for user in user_iter {
        return Ok(Some(user?));
    }
    Ok(None)
}

pub fn create_user(user_id: &str, name: &str, password : &str, conn: &Connection) -> Result<(User,Token)> {
    let (password_hash, password_salt) = misc::hash_password(password);
    conn.execute(
        "INSERT INTO Users (user_id, name, password_hash, password_salt) VALUES (?1, ?2, ?3, ?4)",
        params![user_id, name, password_hash, password_salt],
    )?;

    let valid_until = Utc::now() + Duration::days(7);
    let encoded_token = create_token(user_id, valid_until, conn).unwrap();
    let token = Token {
        encoded_token: encoded_token,
        valid_until: valid_until,
    };
    let user = User {
        user_id: user_id.to_string(),
        name: name.to_string(),
        email: None,
        phone: None,
        admin: false,
    };
    Ok((user, token))
}

pub fn validate_password(user_id : &str, password : &str, conn : &Connection) -> Result<bool> {
    let password_salt = get_user_salt(user_id, conn)?;
    let password_hash = misc::hash_password_with_salt(password, &password_salt);
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE user_id = ?1 AND password_hash = ?2")?;
    let count : i32 = stmt.query_row(params![user_id, password_hash], |row| row.get(0))?;
    Ok(count > 0)
}


pub fn set_user_password(user_id: &str, new_password: &str, conn : &Connection) -> Result<()> {
    let (password_hash, password_salt) = misc::hash_password(new_password);
    conn.execute(
        "UPDATE Users SET password_hash = ?1, password_salt = ?2 WHERE user_id = ?3",
        params![password_hash, password_salt, user_id],
    )?;
    Ok(())
}

pub fn set_user_name(user_id: &str, name: &str, conn: &Connection) -> Result<()> {
    conn.execute(
        "UPDATE Users SET name = ?1 WHERE user_id = ?2",
        params![name, user_id],
    )?;
    Ok(())
}

pub fn check_if_pokemon_exists(pokemon_id: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Pokemon WHERE Pokemon_Id = ?1")?;
    let count : i32 = stmt.query_row(params![pokemon_id], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn check_if_pokemon_exists_by_catch_code(catch_code: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM CatchCodes WHERE catch_code = ?1")?;
    let count : i32 = stmt.query_row(params![catch_code], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn check_if_you_found_pokemon_before(user_id: &str, catch_code: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM ViewFoundPokemonWithCatchCode WHERE User_Id = ?1 AND catch_code = ?2")?;
    let count : i32 = stmt.query_row(params![user_id, catch_code], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn get_pokemon_id_by_catch_code(catch_code: &str, conn: &Connection) -> Result<u32> {
    let mut stmt = conn.prepare("SELECT pokemon_id FROM CatchCodes WHERE catch_code = ?1")?;
    let pokemon_id : u32 = stmt.query_row(params![catch_code], |row| row.get(0))?;
    Ok(pokemon_id)
}


// to call if oyu've found a pokemon
pub fn found_pokemon(user_id: &str, catch_code: &str, conn: &Connection) -> Result<Vec<MilestoneDefinition>> {
    let pokemon_id = get_pokemon_id_by_catch_code(catch_code, conn)?;
    
    // Generate timestamp in Stockholm timezone (CET/CEST)
    let now_utc = Utc::now();
    let now_stockholm = now_utc.with_timezone(&Stockholm);
    let timestamp_str = now_stockholm.format("%Y-%m-%d %H:%M:%S").to_string();
    
    // Get the pokemon's types before inserting
    let pokemon = get_pokemon(pokemon_id, conn)?.unwrap();
    
    // Check milestones BEFORE inserting (for type-based milestones)
    let mut achieved_milestones = Vec::new();
    
    // Check type-based milestones (only if this is their first pokemon of this type)
    for type_name in &pokemon.types {
        if !user_has_first_pokemon_of_type(user_id, type_name, conn)? {
            if let Some(milestone) = get_type_milestone_for_type(type_name) {
                achieved_milestones.push(milestone);
            }
        }
    }
    
    // Check if they're about to catch a legendary bird and don't have all three yet
    let has_birds_before = user_has_legendary_birds(user_id, conn)?;
    
    // Insert the pokemon
    conn.execute(
        "INSERT INTO FoundPokemon (user_id, pokemon_id, found_timestamp) VALUES (?1, ?2, ?3)",
        params![user_id, pokemon_id, timestamp_str],
    )?;
    
    // Check count-based milestones AFTER inserting
    let pokemon_count = user_pokemon_count_for_milestones(user_id, conn)?;
    // Get all possible count milestones
    let count_milestones = vec![10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 151];
    
    // Check if current count matches any milestone exactly
    if count_milestones.contains(&pokemon_count) {
        if let Some(milestone) = get_count_milestone_for_count(pokemon_count) {
            achieved_milestones.push(milestone);
        }
    }
    
    // Check specific pokemon milestones
    if let Some(milestone) = get_pokemon_milestone(pokemon_id) {
        achieved_milestones.push(milestone);
    }
    
    // Check legendary birds milestone (if they now have all three)
    if !has_birds_before && user_has_legendary_birds(user_id, conn)? {
        if let Some(milestone) = crate::milestones::get_milestone_definition("legendary_birds") {
            achieved_milestones.push(milestone);
        }
    }
    
    // Sort milestones by order
    achieved_milestones.sort_by_key(|m| m.order);
    
    Ok(achieved_milestones)
}

pub fn num_pokemon_found(user_id: &str, conn: &Connection) -> Result<i32> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM FoundPokemon WHERE User_Id = ?1")?;
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count)
}

pub fn view_found_pokemon(user_id: &str, n: i32, conn: &Connection) -> Result<Vec<FoundPkmn>> {
    // use view ViewFoundPokemon
    let mut stmt = conn.prepare("SELECT Pokemon, PokemonNumber, Types, TimeStamp, PhotoPath, Comment, Rating FROM ViewFoundPokemon WHERE UserId = ?1 ORDER BY TimeStamp DESC LIMIT ?2")?;
    let rows = stmt.query_map(params![user_id, n], |row| {
        let user = get_user_by_id_str(user_id, conn)?.unwrap();
        let types_str: Option<String> = row.get(2)?;
        Ok(FoundPkmn {
            found_by_user: User {
                user_id: user_id.to_string(),
                name: user.name,
                email : user.email,
                phone: user.phone,
                admin: user.admin,
            },
            name: row.get(0)?,
            number: row.get(1)?,
            types: parse_types(types_str),
            time_found: row.get(3)?,
            photo_path: row.get(4)?,
            comment: row.get(5)?,
            rating: row.get(6)?,
        })
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}


// get user by id
pub fn get_user_by_id(user_id: &str, conn: &Connection) -> Result<Option<User>> {
    let mut stmt = conn.prepare("SELECT user_id, name, email, phone, admin FROM Users WHERE user_id = ?1")?;
    let user_iter = stmt.query_map(params![user_id], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
            admin: row.get(4)?,
        })
    })?;

    for user in user_iter {
        return Ok(Some(user?));
    }
    Ok(None)
}

// check if user has caught pokemon
pub fn check_if_user_has_caught_pokemon(user_id: &str, pokemon_id: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM FoundPokemon WHERE user_id = ?1 AND pokemon_id = ?2")?;
    let count : i32 = stmt.query_row(params![user_id, pokemon_id], |row| row.get(0))?;
    Ok(count > 0)
}

// check if user has caught their first pokemon of a specific type
pub fn user_has_first_pokemon_of_type(user_id: &str, type_name: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare(
        "SELECT COUNT(DISTINCT fp.pokemon_id) FROM FoundPokemon fp 
         JOIN PokemonTypeLinks ptl ON fp.pokemon_id = ptl.pokemon_id
         JOIN PokemonTypes pt ON ptl.type_id = pt.type_id
         WHERE fp.user_id = ?1 AND pt.type_name = ?2"
    )?;
    let count: i32 = stmt.query_row(params![user_id, type_name], |row| row.get(0))?;
    Ok(count > 0)
}

// check if user has caught all three legendary birds
pub fn user_has_legendary_birds(user_id: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare(
        "SELECT COUNT(DISTINCT pokemon_id) FROM FoundPokemon 
         WHERE user_id = ?1 AND pokemon_id IN (144, 145, 146)"
    )?;
    let count: i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count == 3)
}

// get user ranking
pub fn user_ranking(user_id : &str, conn : &Connection) -> Result<u32> {
    let mut stmt = conn.prepare("SELECT Ranking, LastFound FROM ViewUserRanking WHERE UserId = ?1")?;
    let ranking : u32 = stmt.query_row(params![user_id], |row| row.get(0)).unwrap_or(get_num_users(conn)? as u32);
    Ok(ranking)
}


// highscore
pub fn statistics_users_most_found(n : i32, conn : &Connection) -> Result<Vec<UserScore>> {
    let mut stmt = conn.prepare("SELECT UserID, User, PokemonFound, LastFound FROM ViewTopFinders LIMIT ?1")?;
    let rows = stmt.query_map(params![n], |row| {
        Ok(UserScore{id : row.get(0)?, name: row.get(1)?, score: row.get(2)?, latest_found: row.get(3)?})
    })?;
    let mut result = Vec::new();
    for row in rows {
        result.push(row?)
    }
    Ok(result)
}

// get paginated highscores
pub fn get_highscores_paginated(limit: u32, offset: u32, conn: &Connection) -> Result<Vec<UserScore>> {
    let mut stmt = conn.prepare("SELECT UserID, User, PokemonFound, LastFound FROM ViewTopFinders LIMIT ?1 OFFSET ?2")?;
    let rows = stmt.query_map(params![limit, offset], |row| {
        Ok(UserScore{id : row.get(0)?, name: row.get(1)?, score: row.get(2)?, latest_found: row.get(3)?})
    })?;
    let mut result = Vec::new();
    for row in rows {
        result.push(row?)
    }
    Ok(result)
}

// get highscores filtered by name or id with pagination
pub fn get_highscores_filtered(filter: &str, limit: u32, offset: u32, conn: &Connection) -> Result<Vec<UserScore>> {
    let mut stmt = conn.prepare(
        "SELECT vt.UserID, vt.User, vt.PokemonFound, vt.LastFound 
         FROM ViewTopFinders vt
         WHERE vt.UserID LIKE ?1 OR vt.User LIKE ?1
         ORDER BY vt.PokemonFound DESC, vt.LastFound ASC
         LIMIT ?2 OFFSET ?3"
    )?;
    let filter_pattern = format!("%{}%", filter);
    let rows = stmt.query_map(params![filter_pattern, limit, offset], |row| {
        Ok(UserScore{id : row.get(0)?, name: row.get(1)?, score: row.get(2)?, latest_found: row.get(3)?})
    })?;
    let mut result = Vec::new();
    for row in rows {
        result.push(row?)
    }
    Ok(result)
}

// get total count of users in highscores (for pagination)
pub fn get_highscores_total_count(conn: &Connection) -> Result<u32> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM ViewTopFinders")?;
    let count: u32 = stmt.query_row([], |row| row.get(0))?;
    Ok(count)
}

// get total count of filtered users in highscores
pub fn get_highscores_filtered_count(filter: &str, conn: &Connection) -> Result<u32> {
    let mut stmt = conn.prepare(
        "SELECT COUNT(*) FROM ViewTopFinders 
         WHERE UserID LIKE ?1 OR User LIKE ?1"
    )?;
    let filter_pattern = format!("%{}%", filter);
    let count: u32 = stmt.query_row(params![filter_pattern], |row| row.get(0))?;
    Ok(count)
}


pub fn statistics_latest_pokemon_found(n: i32, conn: &Connection) -> Result<Vec<FoundPkmn>> {
    let mut stmt = conn.prepare("Select UserID, User, Pokemon, PokemonNumber, Types, TimeStamp, PhotoPath, Comment, Rating FROM ViewLatestFoundPokemon LIMIT ?1")?;
    let rows = stmt.query_map(params![n], |row| {
        let types_str: Option<String> = row.get(4)?;
        Ok(FoundPkmn { 
            found_by_user : User {
                user_id: row.get(0)?,
                name: row.get(1)?,
                email : None,
                phone : None,
                admin : false,
            },
            name: row.get(2)?,
            number: row.get(3)?,
            types: parse_types(types_str),
            time_found: row.get(5)?,
            photo_path: row.get(6)?,
            comment: row.get(7)?,
            rating: row.get(8)?,
        })
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}



// just get stuff
pub fn get_pokemon(number: u32, conn: &Connection) -> Result<Option<Pkmn>> {
    let mut stmt = conn.prepare("SELECT name, pokemon_id, description, height, types FROM ViewPokemonWithTypes WHERE pokemon_id = ?1")?;
    let rows = stmt.query_map(params![number], |row| {
        let types_str: Option<String> = row.get(4)?;
        Ok(Pkmn {
            name: row.get(0)?,
            number: row.get(1)?,
            photo_path: None,
            description: row.get(2)?,
            height: row.get(3)?,
            types: parse_types(types_str),
        })
    })?;

    for row in rows {
        return Ok(Some(row?));
    }
    Ok(None)
}

pub fn get_pokemon_by_catch_code(catch_code: &str, conn: &Connection) -> Result<Pkmn> {
    let mut stmt = conn.prepare("SELECT pokemon_id, name, description, height, active, types FROM ViewPokemonWithCatchCode WHERE catch_code = ?1")?;
    let row = stmt.query_row(params![catch_code], |row| {
        let types_str: Option<String> = row.get(5)?;
        Ok(Pkmn {
            name: row.get(1)?,
            number: row.get(0)?,
            photo_path: None,
            description: row.get(2)?,
            height: row.get(3)?,
            types: parse_types(types_str),
        })
    })?;
    Ok(row)
}

// get all info from pokemon caught by the user
pub fn user_pokedex(user_id: &str, conn: &Connection) -> Result<Vec<Pkmn>> {
    let mut stmt = conn.prepare(
        "SELECT name, description, height, pokemon_id, types FROM ViewPokemonWithTypes WHERE pokemon_id IN (SELECT pokemon_id FROM FoundPokemon WHERE User_Id = ?1)"
    )?;
    let rows = stmt.query_map(params![user_id], |row| {
        let types_str: Option<String> = row.get(4)?;
        Ok(Pkmn {
            name: row.get(0)?,
            number: row.get(3)?,
            photo_path: None,
            description: row.get(1)?,
            height: row.get(2)?,
            types: parse_types(types_str),
        })
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }

    Ok(result)
}

// get count of pokemon caught by user (excluding MissingNo for milestones)
pub fn user_pokemon_count_for_milestones(user_id: &str, conn: &Connection) -> Result<u32> {
    let mut stmt = conn.prepare(
        "SELECT COUNT(DISTINCT pokemon_id) FROM FoundPokemon WHERE user_id = ?1 AND pokemon_id <= 151"
    )?;
    let count: u32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count)
}

// check if user has achieved a milestone by counting their pokemon
pub fn user_has_milestone(user_id: &str, milestone_count: u32, conn: &Connection) -> Result<bool> {
    let pokemon_count = user_pokemon_count_for_milestones(user_id, conn)?;
    Ok(pokemon_count >= milestone_count)
}

// record_milestone function removed - milestones are now calculated dynamically

// get all milestones for a user based on their pokemon count
pub fn get_user_milestones(user_id: &str, conn: &Connection) -> Result<Vec<u32>> {
    let pokemon_count = user_pokemon_count_for_milestones(user_id, conn)?;
    let milestones = vec![10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 151];
    
    let mut result = Vec::new();
    for milestone in milestones {
        if pokemon_count >= milestone {
            result.push(milestone);
        } else {
            break;
        }
    }
    Ok(result)
}

// Get Pokemon count by type for a specific user
pub fn user_pokemon_by_type(user_id: &str, conn: &Connection) -> Result<Vec<UserTypeStats>> {
    let mut stmt = conn.prepare(
        "SELECT UserID, User, Type, PokemonCount FROM ViewUserPokemonByType WHERE UserID = ?1 ORDER BY Type"
    )?;
    let rows = stmt.query_map(params![user_id], |row| {
        Ok(UserTypeStats {
            user_id: row.get(0)?,
            user_name: row.get(1)?,
            type_name: row.get(2)?,
            pokemon_count: row.get(3)?,
        })
    })?;
    
    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}

// Get total Pokemon catches by type across all users
pub fn total_pokemon_by_type(conn: &Connection) -> Result<Vec<TypeStats>> {
    let mut stmt = conn.prepare(
        "SELECT Type, TotalCatches FROM ViewTotalPokemonByType ORDER BY Type"
    )?;
    let rows = stmt.query_map([], |row| {
        Ok(TypeStats {
            type_name: row.get(0)?,
            total_catches: row.get(1)?,
        })
    })?;
    
    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}

// Get all achieved milestone definitions for a user
pub fn get_user_milestone_definitions(user_id: &str, conn: &Connection) -> Result<Vec<MilestoneDefinition>> {
    let mut achieved_milestones = Vec::new();
    
    // Get count-based milestones
    let pokemon_count = user_pokemon_count_for_milestones(user_id, conn)?;
    let milestones = vec![10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 151];
    
    for milestone in milestones {
        if pokemon_count >= milestone {
            if let Some(definition) = get_count_milestone_for_count(milestone) {
                achieved_milestones.push(definition);
            }
        }
    }
    
    // Get type-based milestones
    let types = vec!["Normal", "Eld", "Vatten", "Gräs", "Elektro", "Is", "Kamp", "Gift", "Mark", "Flyg", "Psykisk", "Insekt", "Sten", "Spöke", "Drake", "Mörk", "Stål", "Fé"];
    
    for type_name in types {
        if user_has_first_pokemon_of_type(user_id, type_name, conn)? {
            if let Some(definition) = get_type_milestone_for_type(type_name) {
                achieved_milestones.push(definition);
            }
        }
    }
    
    // Get special Pokemon milestones
    let special_pokemon = vec![144, 145, 146, 150, 151, 312798312]; // Articuno, Zapdos, Moltres, Mewtwo, Mew, MissingNo
    
    for pokemon_id in special_pokemon {
        let mut stmt = conn.prepare("SELECT COUNT(*) FROM FoundPokemon WHERE user_id = ?1 AND pokemon_id = ?2")?;
        let count: i32 = stmt.query_row(params![user_id, pokemon_id], |row| row.get(0))?;
        
        if count > 0 {
            if let Some(definition) = get_pokemon_milestone(pokemon_id) {
                achieved_milestones.push(definition);
            }
        }
    }
    
    // Check legendary birds milestone
    if user_has_legendary_birds(user_id, conn)? {
        if let Some(definition) = crate::milestones::get_milestone_definition("legendary_birds") {
            achieved_milestones.push(definition);
        }
    }
    
    // Sort by order
    achieved_milestones.sort_by_key(|m| m.order);
    
    Ok(achieved_milestones)
}

pub fn get_pokemon_found_counts(conn: &Connection) -> Result<Vec<PokemonFoundCount>> {
    let mut stmt = conn.prepare(
        "SELECT Pokemon, PokemonNumber, Count FROM ViewPokemonFoundCounts ORDER BY Count DESC, Pokemon"
    )?;
    
    let pokemon_counts = stmt.query_map([], |row| {
        Ok(PokemonFoundCount {
            pokemon_name: row.get(0)?,
            pokemon_number: row.get(1)?,
            count: row.get(2)?,
        })
    })?
    .collect::<Result<Vec<_>, _>>()?;
    
    Ok(pokemon_counts)
}

pub fn get_setting(setting_id: &str, conn: &Connection) -> Result<Option<String>> {
    let mut stmt = conn.prepare("SELECT setting_value FROM Settings WHERE setting_id = ?1")?;
    match stmt.query_row(params![setting_id], |row| row.get::<_, String>(0)) {
        Ok(value) => Ok(Some(value)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e),
    }
}

pub fn count_users_with_pokemon_threshold(threshold: u32, conn: &Connection) -> Result<u32> {
    let mut stmt = conn.prepare(
        "SELECT COUNT(DISTINCT user_id) FROM FoundPokemon 
         WHERE user_id != 'admin' 
         GROUP BY user_id 
         HAVING COUNT(DISTINCT pokemon_id) >= ?1"
    )?;
    
    let count: u32 = stmt.query_map(params![threshold], |_| Ok(1))?
        .count() as u32;
    
    Ok(count)
}

pub fn count_total_pokemon_caught(conn: &Connection) -> Result<u32> {
    let mut stmt = conn.prepare(
        "SELECT COUNT(*) FROM FoundPokemon WHERE user_id != 'admin'"
    )?;
    let count: u32 = stmt.query_row([], |row| row.get(0))?;
    Ok(count)
}

pub fn get_catches_per_hour(datetime0: Option<&str>, datetime1: Option<&str>, conn: &Connection) -> Result<Vec<crate::model::HourlyCatchStats>> {
    let mut query = String::from(
        "SELECT 
            CAST(strftime('%H', found_timestamp) AS INTEGER) as hour,
            COUNT(*) as count
         FROM FoundPokemon
         WHERE user_id != 'admin'"
    );
    
    let mut params_vec: Vec<String> = vec![];
    
    if let Some(start) = datetime0 {
        query.push_str(" AND found_timestamp >= ?");
        params_vec.push(start.to_string());
    }
    
    if let Some(end) = datetime1 {
        query.push_str(" AND found_timestamp <= ?");
        params_vec.push(end.to_string());
    }
    
    query.push_str(" GROUP BY hour ORDER BY hour");
    
    let mut stmt = conn.prepare(&query)?;
    let params: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|p| p as &dyn rusqlite::ToSql).collect();
    
    let hourly_stats = stmt.query_map(&params[..], |row| {
        Ok(crate::model::HourlyCatchStats {
            hour: row.get(0)?,
            catches: row.get(1)?,
        })
    })?
    .filter_map(|r| r.ok())
    .filter(|stat| {
        // Exclude hours between 22:30-06:30
        // We include hour 6 (06:00-06:59) and exclude hour 22 after 30 minutes
        // For simplicity, we'll exclude entire hours 23, 0, 1, 2, 3, 4, 5
        stat.hour >= 7 && stat.hour <= 22
    })
    .collect();
    
    Ok(hourly_stats)
}

pub fn get_first_catch(datetime0: Option<&str>, datetime1: Option<&str>, conn: &Connection) -> Result<Option<crate::model::FirstLastCatch>> {
    let mut query = String::from(
        "SELECT u.name, p.name, p.pokemon_id, fp.found_timestamp
         FROM FoundPokemon fp
         JOIN Users u ON fp.user_id = u.user_id
         JOIN Pokemon p ON fp.pokemon_id = p.pokemon_id
         WHERE fp.user_id != 'admin'"
    );
    
    let mut params_vec: Vec<String> = vec![];
    
    if let Some(start) = datetime0 {
        query.push_str(" AND fp.found_timestamp >= ?");
        params_vec.push(start.to_string());
    }
    
    if let Some(end) = datetime1 {
        query.push_str(" AND fp.found_timestamp <= ?");
        params_vec.push(end.to_string());
    }
    
    query.push_str(" ORDER BY fp.found_timestamp ASC LIMIT 1");
    
    let mut stmt = conn.prepare(&query)?;
    let params: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|p| p as &dyn rusqlite::ToSql).collect();
    
    match stmt.query_row(&params[..], |row| {
        Ok(crate::model::FirstLastCatch {
            user_name: row.get(0)?,
            pokemon_name: row.get(1)?,
            pokemon_number: row.get(2)?,
            caught_at: row.get(3)?,
        })
    }) {
        Ok(catch) => Ok(Some(catch)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e),
    }
}

pub fn get_last_catch(datetime0: Option<&str>, datetime1: Option<&str>, conn: &Connection) -> Result<Option<crate::model::FirstLastCatch>> {
    let mut query = String::from(
        "SELECT u.name, p.name, p.pokemon_id, fp.found_timestamp
         FROM FoundPokemon fp
         JOIN Users u ON fp.user_id = u.user_id
         JOIN Pokemon p ON fp.pokemon_id = p.pokemon_id
         WHERE fp.user_id != 'admin'"
    );
    
    let mut params_vec: Vec<String> = vec![];
    
    if let Some(start) = datetime0 {
        query.push_str(" AND fp.found_timestamp >= ?");
        params_vec.push(start.to_string());
    }
    
    if let Some(end) = datetime1 {
        query.push_str(" AND fp.found_timestamp <= ?");
        params_vec.push(end.to_string());
    }
    
    query.push_str(" ORDER BY fp.found_timestamp DESC LIMIT 1");
    
    let mut stmt = conn.prepare(&query)?;
    let params: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|p| p as &dyn rusqlite::ToSql).collect();
    
    match stmt.query_row(&params[..], |row| {
        Ok(crate::model::FirstLastCatch {
            user_name: row.get(0)?,
            pokemon_name: row.get(1)?,
            pokemon_number: row.get(2)?,
            caught_at: row.get(3)?,
        })
    }) {
        Ok(catch) => Ok(Some(catch)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e),
    }
}

pub fn get_most_caught_pokemon(limit: u32, conn: &Connection) -> Result<Vec<crate::model::PokemonCatchStats>> {
    let mut stmt = conn.prepare(
        "SELECT p.name, p.pokemon_id, COUNT(fp.pokemon_id) as count
         FROM Pokemon p
         LEFT JOIN FoundPokemon fp ON p.pokemon_id = fp.pokemon_id AND fp.user_id != 'admin'
         WHERE p.active = 1
         GROUP BY p.pokemon_id, p.name
         HAVING count > 0
         ORDER BY count DESC, p.name
         LIMIT ?1"
    )?;
    
    let pokemon_stats = stmt.query_map(params![limit], |row| {
        Ok(crate::model::PokemonCatchStats {
            pokemon_name: row.get(0)?,
            pokemon_number: row.get(1)?,
            times_caught: row.get(2)?,
        })
    })?
    .collect::<Result<Vec<_>, _>>()?;
    
    Ok(pokemon_stats)
}

pub fn get_least_caught_pokemon(limit: u32, conn: &Connection) -> Result<Vec<crate::model::PokemonCatchStats>> {
    let mut stmt = conn.prepare(
        "SELECT p.name, p.pokemon_id, COUNT(fp.pokemon_id) as count
         FROM Pokemon p
         LEFT JOIN FoundPokemon fp ON p.pokemon_id = fp.pokemon_id AND fp.user_id != 'admin'
         WHERE p.active = 1
         GROUP BY p.pokemon_id, p.name
         ORDER BY count ASC, p.name
         LIMIT ?1"
    )?;
    
    let pokemon_stats = stmt.query_map(params![limit], |row| {
        Ok(crate::model::PokemonCatchStats {
            pokemon_name: row.get(0)?,
            pokemon_number: row.get(1)?,
            times_caught: row.get(2)?,
        })
    })?
    .collect::<Result<Vec<_>, _>>()?;
    
    Ok(pokemon_stats)
}
pub fn get_longest_survivor_pokemon(datetime0: Option<&str>, datetime1: Option<&str>, conn: &Connection) -> Result<Option<crate::model::FirstLastCatch>> {
    let mut query = String::from(
        "WITH FirstCatches AS (
            SELECT 
                p.pokemon_id,
                p.name as pokemon_name,
                MIN(fp.found_timestamp) as first_caught
            FROM Pokemon p
            INNER JOIN FoundPokemon fp ON p.pokemon_id = fp.pokemon_id AND fp.user_id != 'admin'
            WHERE p.active = 1"
    );
    
    let mut params_vec: Vec<String> = vec![];
    
    if let Some(start) = datetime0 {
        query.push_str(" AND fp.found_timestamp >= ?");
        params_vec.push(start.to_string());
    }
    
    if let Some(end) = datetime1 {
        query.push_str(" AND fp.found_timestamp <= ?");
        params_vec.push(end.to_string());
    }
    
    query.push_str(
        " GROUP BY p.pokemon_id, p.name
        )
        SELECT 
            u.name as user_name,
            fc.pokemon_name,
            fc.pokemon_id as pokemon_number,
            fc.first_caught as caught_at
        FROM FirstCatches fc
        INNER JOIN FoundPokemon fp ON fc.pokemon_id = fp.pokemon_id 
            AND fp.found_timestamp = fc.first_caught 
            AND fp.user_id != 'admin'
        INNER JOIN Users u ON fp.user_id = u.user_id
        WHERE fc.first_caught IS NOT NULL
        ORDER BY fc.first_caught DESC
        LIMIT 1"
    );
    
    let mut stmt = conn.prepare(&query)?;
    let params: Vec<&dyn rusqlite::ToSql> = params_vec.iter().map(|p| p as &dyn rusqlite::ToSql).collect();
    
    match stmt.query_row(&params[..], |row| {
        Ok(crate::model::FirstLastCatch {
            user_name: row.get(0)?,
            pokemon_name: row.get(1)?,
            pokemon_number: row.get(2)?,
            caught_at: row.get(3)?,
        })
    }) {
        Ok(catch) => Ok(Some(catch)),
        Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
        Err(e) => Err(e),
    }
}
