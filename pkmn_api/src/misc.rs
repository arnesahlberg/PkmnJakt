use base64::{engine::general_purpose, Engine};
use chrono::{DateTime, Utc};
use rand::Rng;
use rusqlite::{params, Connection};
use sha2::Digest;


pub fn encode_string_base64(input : String) -> String {
    general_purpose::STANDARD.encode(input.as_bytes())
}

pub fn decode_string_base64(input : String) -> String {
    let bytes = general_purpose::STANDARD.decode(input)
        .expect("Failed to decode Base64 string!");

    let decoded_string = String::from_utf8(bytes)
        .expect("Decoded bytes are not a UTF-8 string.");

    decoded_string
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
pub fn create_token(user_id : &str, valid_until : DateTime<Utc>, conn : &Connection) -> Result<String, String> {
    let token = format!("[TOKEN--{}--{}--{}--{}]", random_string(11), user_id, valid_until, random_string(3));
    let encoded_token = encode_string_base64(token);

    // and put in database
    conn.execute(
        "INSERT INTO Token(token, user_id, expiry) VALUES(?1, ?2, ?3)",
        params![encoded_token, user_id, valid_until.to_rfc3339()]
    ).expect("Failed to insert token into database.");

    Ok(encoded_token)
}

pub fn validate_token(user_id : &str, token : &str, conn : &Connection) -> bool {
    let decoded_token = decode_string_base64(token.to_string());
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

    let expiry = DateTime::parse_from_rfc3339(token_expiry.replace(" UTC", "Z").replace(" " , "T").as_str())
        .expect("Failed to parse token expiry date.");

    if expiry < Utc::now() {
        return false;
    }



    let mut stmt = conn.prepare(
        "SELECT token FROM Token WHERE token = ?1 AND user_id = ?2"
    ).expect("Failed to prepare statement for token validation.");


    let mut rows = stmt.query(params![token, user_id])
        .expect("Failed to query token for validation.");

    let mut count = 0;
    while let Some(a_) = rows.next().unwrap() {
        count += 1;
    }

    count > 0
}