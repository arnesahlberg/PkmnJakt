
use rusqlite::{params, Connection, Result};
use crate::model::{FoundPkmn, User};
pub fn get_conn (path : String) -> Result<Connection> {
    Connection::open(path)
}

pub fn user_exists(user_id : &str, conn : &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE User_Id = ?1")?;
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    Ok(count > 0)
}


pub fn get_user_by_id_str(user_id: &str, conn: &Connection) -> Result<Option<User>> {
    let mut stmt = conn.prepare(
        "SELECT user_id, name FROM Users WHERE user_id = ?1",
    )?;

    let user_iter = stmt.query_map(params![user_id], |row| {
        Ok(User {
            user_id: row.get(0)?,
            name: row.get(1)?,
        })
    })?;

    // return if one exists
    for user in user_iter {
        return Ok(Some(user?));
    }
    Ok(None)
}

pub fn create_user(user_id: &str, name: &str, conn: &Connection) -> Result<()> {
    conn.execute(
        "INSERT INTO Users (user_id, name) VALUES (?1, ?2)",
        params![user_id, name],
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
        println!("row: {:?}", row);
        Ok(FoundPkmn {
            found_by_user: User {
                user_id: user_id.to_string(),
                name: get_user_by_id_str(user_id, conn)?.unwrap().name,
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


pub fn statistics_top_n_caught(n: i32, conn: &Connection) -> Result<Vec<(String, i32)>> {
    let mut stmt = conn.prepare("SELECT Pokemon_Id, COUNT(*) FROM FoundPokemon GROUP BY Pokemon_Id ORDER BY COUNT(*) DESC LIMIT ?1")?;
    let rows = stmt.query_map(params![n], |row| {
        Ok((row.get(0)?, row.get(1)?))
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}


pub fn statistics_latest_pokemon_found(n: i32, conn: &Connection) -> Result<Vec<(String, String)>> {
    let mut stmt = conn.prepare("SELECT User_Id, Pokemon_Id FROM FoundPokemon ORDER BY ROWID DESC LIMIT ?1")?;
    let rows = stmt.query_map(params![n], |row| {
        Ok((row.get(0)?, row.get(1)?))
    })?;

    let mut result = Vec::new();
    for row in rows {
        result.push(row?);
    }
    Ok(result)
}

