
use core::panic;

use chrono::{Utc, Duration};
use rusqlite::{params, Connection, Result};
use crate::model::{FoundPkmn, Pkmn, Token, User, UserScore};
use crate::misc::{self, create_token};


pub fn get_conn (path : String) -> Result<Connection> {
    Connection::open(path)
}

pub fn user_exists(user_id : &str, conn : &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE User_Id = ?1")?;
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count > 0)
}


pub fn login_and_get_user_by_id_pwd(user_id: &str, pwd: &str, conn: &Connection) -> Result<Option<(User, Token)>> {

    // need to fetch user's password salt from database and then hash the password
    let mut stmt = conn.prepare (
        "SELECT password_salt FROM Users WHERE user_id = ?1"
    )?;
    let salt : String = stmt.query_row(params![user_id], |row| row.get(0))?;
    let hashed = misc::hash_password_with_salt(pwd, &salt);

    let mut stmt = conn.prepare(
        "SELECT user_id, name, email, phone FROM Users WHERE user_id = ?1 AND password_hash = ?2"
    )?;

    let user_iter = stmt.query_map(params![user_id, hashed],  |row| {
        Ok(User{
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
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
        "SELECT user_id, name, email, phone FROM Users WHERE user_id = ?1",
    )?;

    let user_iter = stmt.query_map(params![user_id], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
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
    };
    Ok((user, token))
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

pub fn check_if_you_found_pokemon_before(user_id: &str, pokemon_id: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM FoundPokemon WHERE User_Id = ?1 AND Pokemon_Id = ?2")?;
    let count : i32 = stmt.query_row(params![user_id, pokemon_id], |row| row.get(0))?;
    Ok(count > 0)
}

pub fn found_pokemon(user_id: &str, pokemon_id: &str, conn: &Connection) -> Result<()> {
    conn.execute(
        "INSERT INTO FoundPokemon (User_Id, Pokemon_Id) VALUES (?1, ?2)",
        params![user_id, pokemon_id],
    )?;
    Ok(())
}

pub fn num_pokemon_found(user_id: &str, conn: &Connection) -> Result<i32> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM FoundPokemon WHERE User_Id = ?1")?;
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count)
}

pub fn view_found_pokemon(user_id: &str, n: i32, conn: &Connection) -> Result<Vec<FoundPkmn>> {
    // use view ViewFoundPokemon
    let mut stmt = conn.prepare("SELECT Pokemon, Number, TimeStamp, PhotoPath, Comment, Rating FROM ViewFoundPokemon WHERE UserId = ?1 ORDER BY TimeStamp DESC LIMIT ?2")?;
    let rows = stmt.query_map(params![user_id, n], |row| {
        Ok(FoundPkmn {
            found_by_user: User {
                user_id: user_id.to_string(),
                name: get_user_by_id_str(user_id, conn)?.unwrap().name,
                email : None,
                phone: None,
            },
            name: row.get(0)?,
            number: row.get(1)?,
            time_found: row.get(2)?,
            photo_path: row.get(3)?,
            comment: row.get(4)?,
            rating: row.get(5)?,
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
    let mut stmt = conn.prepare("SELECT user_id, name, email, phone FROM Users WHERE user_id = ?1")?;
    let user_iter = stmt.query_map(params![user_id], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
            email: row.get(2)?,
            phone: row.get(3)?,
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

// check if user has uploaded a picture of pokemon
pub fn check_if_user_has_uploaded_photo_of_pokemon(user_id: &str, pokemon_id: &str, conn: &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM FoundPokemon WHERE user_id = ?1 AND pokemon_id = ?2 AND photo_path IS NOT NULL")?;
    let count : i32 = stmt.query_row(params![user_id, pokemon_id], |row| row.get(0))?;
    Ok(count > 0)
}

// upload photo of pokemon user has caught and add comment and rating
pub fn upload_photo_of_pokemon(user_id: &str, pokemon_id: &str, photo_path: &str, comment: &str, rating: i32, conn: &Connection) -> Result<()> {
    panic!("Not implemented yet.");
    Ok(())
}


// highscore
pub fn statistics_users_most_found(n : i32, conn : &Connection) -> Result<Vec<UserScore>> {
    let mut stmt = conn.prepare("SELECT UserID, User, PokemonFound FROM ViewTopFinders LIMIT ?1")?;
    let rows = stmt.query_map(params![n], |row| {
        Ok(UserScore{id : row.get(0)?, name: row.get(1)?, score: row.get(2)?})
    })?;
    let mut result = Vec::new();
    for row in rows {
        result.push(row?)
    }
    Ok(result)
}


pub fn statistics_latest_pokemon_found(n: i32, conn: &Connection) -> Result<Vec<FoundPkmn>> {
    let mut stmt = conn.prepare("Select UserID, User, Pokemon, PokemonNumber, TimeStamp, PhotoPath, Comment, Rating FROM ViewLatestFoundPokemon LIMIT ?1")?;
    let rows = stmt.query_map(params![n], |row| {
        Ok(FoundPkmn { 
            found_by_user : User {
                user_id: row.get(0)?,
                name: row.get(1)?,
                email : None,
                phone : None,
            },
            name: row.get(2)?,
            number: row.get(3)?,
            time_found: row.get(4)?,
            photo_path: row.get(5)?,
            comment: row.get(6)?,
            rating: row.get(7)?,
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
    let mut stmt = conn.prepare("SELECT name, pokemon_id, description, height FROM Pokemon WHERE pokemon_id = ?1")?;
    let rows = stmt.query_map(params![number], |row| {
        Ok(Pkmn {
            name: row.get(0)?,
            number: row.get(1)?,
            photo_path: None,
            description: row.get(2)?,
            height: row.get(3)?,
        })
    })?;

    for row in rows {
        return Ok(Some(row?));
    }
    Ok(None)
}
