
use rusqlite::{params, Connection, Result};


pub fn get_conn (path : String) -> Result<Connection> {
    Connection::open(path)
}

pub fn user_exists(user_id : &str, conn : &Connection) -> Result<bool> {
    let mut stmt = conn.prepare("SELECT COUNT(*) FROM Users WHERE User_Id = ?1")?;
    println!("user_id: {}", user_id);
    let count : i32 = stmt.query_row(params![user_id], |row| row.get(0))?;
    println!("count: {}", count);
    Ok(count > 0)
}

#[derive(Debug)]
pub struct User {
    pub user_id: String,
    pub name: String,
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