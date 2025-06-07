use base64::{engine::general_purpose, Engine};
use chrono::{DateTime, Utc};
use rand::Rng;
use rusqlite::{params, Connection};
use sha2::Digest;


pub fn encode_string_base64(input : String) -> String {
    general_purpose::STANDARD.encode(input.as_bytes())
}

pub fn decode_string_base64(input : String) -> Result<String,String> {
    let bytes = match general_purpose::STANDARD.decode(input) {
        Ok(b) => b,
        Err(_) => return Err("Failed to decode Base64 string.".to_string()),
    };

    let decoded_string = match String::from_utf8(bytes) {
        Ok(s) => s,
        Err(_) => return Err("Decoded bytes are not a UTF-8 string.".to_string()),
    };

    Ok(decoded_string)
}


fn random_string(n : usize) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    let mut rng = rand::rng();

    (0..n)
        .map(|_| {
            let idx = rng.random_range(0..letters.len());
            letters.chars().nth(idx).unwrap()
        })
        .collect()
}

pub fn hash_password_with_salt(password : &str, salt : &str) -> String {
    let mut hasher = sha2::Sha256::new();
    hasher.update(password.as_bytes());
    hasher.update(salt.as_bytes());
    let hash = hasher.finalize();
    format!("{:x}", hash)
}

pub fn hash_password(password : &str) -> (String,String) {
    let salt = random_string(8);
    let hash = hash_password_with_salt(password, &salt);
    (hash, salt)
}

pub fn verify_hash_password(password : &str, hash : &str, salt : &str) -> bool {
    let new_hash = hash_password_with_salt(password, salt);
    new_hash.as_str() == hash
}



// database connected functions too
pub fn create_token(user_id : &str, valid_until : DateTime<Utc>, conn : &Connection) -> Result<String, rusqlite::Error> {
    let token = format!("[TOKEN--{}--{}--{}--{}]", random_string(11), user_id, valid_until, random_string(3));
    let encoded_token = encode_string_base64(token);

    // and put in database
    conn.execute(
        "INSERT INTO Tokens(token, user_id, expiry) VALUES(?1, ?2, ?3)",
        params![encoded_token, user_id, valid_until.to_rfc3339()]
    )?;

    Ok(encoded_token)
}

pub fn get_user_id_from_token(token : &str) -> Result<String,String> {
    let decoded_token = decode_string_base64(token.to_string())?;
    let token_parts : Vec<&str> = decoded_token.split("--").collect();
    if token_parts.len() != 5 {
        return Err("Invalid token format.".to_string());
    }
    let token_user_id = token_parts[2];
    Ok(token_user_id.to_string())
}

pub fn validate_token(user_id : &str, token : &str, conn : &Connection) -> bool {
    let decoded_token = match decode_string_base64(token.to_string()) {
        Ok(t) => t,
        Err(_) => return false,
    };
    let token_parts : Vec<&str> = decoded_token.split("--").collect();
    if token_parts.len() != 5 {
        return false;
    }
    let token_id = token_parts[0];
    let token_user_id = token_parts[2];
    let token_expiry = token_parts[3];

    if token_id != "[TOKEN" {
        return false;
    }

    if token_user_id != user_id {
        return false;
    }

    let expiry = match DateTime::parse_from_rfc3339(token_expiry.replace(" UTC", "Z").replace(" " , "T").as_str()) {
        Ok(e) => e,
        Err(_) => return false,
    };

    if expiry < Utc::now() {
        return false;
    }
    // check if token exists in database with user_id. don't check the validuntil field here
    // it seems to not work for some reason. 
    let mut stmt = match conn.prepare(
        "SELECT token FROM Tokens WHERE token = ?1 AND user_id = ?2"
    ) {
        Ok(s) => s,
        Err(_) => return false,
    };

    let mut rows = match stmt.query(params![token, user_id]) {
        Ok(r) => r,
        Err(_) => return false,
    };

    let mut count = 0;
    while let Ok(Some(_)) = rows.next() {
        count += 1;
    }

    count > 0
}