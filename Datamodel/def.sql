-- Data model for Pokemon finding game riksläger
---------------------------------------------------

PRAGMA foreign_keys = ON;
PRAGMA encoding = "UTF-8";

CREATE TABLE IF NOT EXISTS Users (
    user_id       TEXT PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE,
    phone         TEXT,
    email         TEXT,
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    admin         BOOLEAN DEFAULT 0,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Tokens (
    token       TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL,
    expiry      DATETIME NOT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE IF NOT EXISTS Settings (
    setting_id TEXT PRIMARY KEY,
    setting_value TEXT NOT NULL
);

-- Default settings
INSERT OR IGNORE INTO Settings (setting_id, setting_value) VALUES ('datamatrix_login_enabled', 'true');


CREATE TABLE IF NOT EXISTS Pokemon (
    pokemon_id   INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    description  TEXT,
    height       REAL,
    active       BOOLEAN DEFAULT 1
);

CREATE TABLE IF NOT EXISTS CatchCodes (
    pokemon_id INTEGER NOT NULL,
    catch_code TEXT PRIMARY KEY,
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id)
);

-- Pokemon type system tables
CREATE TABLE IF NOT EXISTS PokemonTypes (
    type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS PokemonTypeLinks (
    pokemon_id INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    type_order INTEGER NOT NULL, -- 1 for primary type, 2 for secondary type
    PRIMARY KEY (pokemon_id, type_id),
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id),
    FOREIGN KEY (type_id) REFERENCES PokemonTypes(type_id)
);

-- Insert Swedish Gen 1 Pokemon types
INSERT INTO PokemonTypes (type_name) VALUES
    ('Normal'),
    ('Eld'),        -- Fire
    ('Vatten'),     -- Water
    ('Elektro'),    -- Electric
    ('Gräs'),       -- Grass
    ('Is'),         -- Ice
    ('Kamp'),       -- Fighting
    ('Gift'),       -- Poison
    ('Mark'),       -- Ground
    ('Flyg'),       -- Flying
    ('Psykisk'),      -- Psychic
    ('Insekt'),     -- Bug
    ('Sten'),       -- Rock
    ('Spöke'),      -- Ghost
    ('Drake');      -- Dragon

-- VIEW pokemon with types
CREATE VIEW IF NOT EXISTS ViewPokemonWithTypes AS
SELECT 
    p.pokemon_id,
    p.name,
    p.description,
    p.height,
    p.active,
    GROUP_CONCAT(pt.type_name, '/') AS types
FROM Pokemon p
LEFT JOIN PokemonTypeLinks ptl ON p.pokemon_id = ptl.pokemon_id
LEFT JOIN PokemonTypes pt ON ptl.type_id = pt.type_id
GROUP BY p.pokemon_id
ORDER BY p.pokemon_id;

-- VIEW pokemon with catch code and types
CREATE VIEW IF NOT EXISTS ViewPokemonWithCatchCode AS
SELECT 
    p.pokemon_id AS pokemon_id,
    p.name AS name,
    p.description AS description,
    p.height AS height,
    p.active AS active,
    cc.catch_code AS catch_code,
    GROUP_CONCAT(pt.type_name, '/') AS types
FROM Pokemon p
JOIN CatchCodes cc ON p.pokemon_id = cc.pokemon_id
LEFT JOIN PokemonTypeLinks ptl ON p.pokemon_id = ptl.pokemon_id
LEFT JOIN PokemonTypes pt ON ptl.type_id = pt.type_id
GROUP BY p.pokemon_id, p.name, p.description, p.height, p.active, cc.catch_code;

CREATE TABLE IF NOT EXISTS FoundPokemon (
    found_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id        TEXT NOT NULL,
    pokemon_id     INTEGER NOT NULL,
    found_timestamp DATETIME NOT NULL,
    photo_path     TEXT, 
    comment        TEXT,
    rating         INTEGER CHECK (rating >= 0 AND rating <= 4),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id)
);

-- UserMilestones table removed - milestones are now calculated dynamically from FoundPokemon

-- VIEW to get the FoundPokemon together whith CatchCode 
-- same as FoundPokemon table but iwth a catch_code column
CREATE VIEW IF NOT EXISTS ViewFoundPokemonWithCatchCode AS
SELECT 
    FoundPokemon.found_id AS found_id,
    FoundPokemon.user_id AS user_id,
    FoundPokemon.pokemon_id AS pokemon_id,
    FoundPokemon.found_timestamp AS found_timestamp,
    FoundPokemon.photo_path AS photo_path,
    FoundPokemon.comment AS comment,
    FoundPokemon.rating AS rating,
    CatchCodes.catch_code AS catch_code
FROM FoundPokemon
JOIN CatchCodes ON FoundPokemon.pokemon_id = CatchCodes.pokemon_id
WHERE FoundPokemon.user_id != 'admin'; -- exclude admin user

-- view to show found pokemon with user name and types
CREATE VIEW IF NOT EXISTS ViewFoundPokemon AS
SELECT 
    u.user_id AS UserId,
    u.name AS User, 
    p.name AS Pokemon, 
    p.pokemon_id AS PokemonNumber,
    GROUP_CONCAT(pt.type_name, '/') AS Types,
    fp.found_timestamp AS TimeStamp, 
    fp.photo_path AS PhotoPath, 
    fp.comment AS Comment, 
    fp.rating AS Rating
FROM FoundPokemon fp
JOIN Users u ON fp.user_id = u.user_id
JOIN Pokemon p ON fp.pokemon_id = p.pokemon_id
LEFT JOIN PokemonTypeLinks ptl ON p.pokemon_id = ptl.pokemon_id
LEFT JOIN PokemonTypes pt ON ptl.type_id = pt.type_id
WHERE u.user_id != 'admin' -- exclude admin user
GROUP BY fp.found_id, u.user_id, u.name, p.name, p.pokemon_id, fp.found_timestamp, fp.photo_path, fp.comment, fp.rating;

-- latest found pokemon
CREATE VIEW IF NOT EXISTS ViewLatestFoundPokemon AS
SELECT * FROM ViewFoundPokemon
ORDER BY TimeStamp DESC ;

-- view to show how many of each pokemon are found (including zero counts)
CREATE VIEW IF NOT EXISTS ViewPokemonFoundCounts AS
SELECT 
    p.name AS Pokemon,
    p.pokemon_id AS PokemonNumber,
    COUNT(fp.pokemon_id) AS Count
FROM Pokemon p
LEFT JOIN FoundPokemon fp ON p.pokemon_id = fp.pokemon_id AND fp.user_id != 'admin'
WHERE p.active = 1
GROUP BY p.pokemon_id, p.name
ORDER BY Count DESC, p.name;

-- view number of pokemon found by user
CREATE VIEW IF NOT EXISTS ViewNumPokemonFound AS
SELECT 
    Users.user_id AS UserID,
    Users.name AS User, 
    COUNT(FoundPokemon.pokemon_id) AS PokemonFound,
    -- time of last found pokemon
    MAX(FoundPokemon.found_timestamp) AS LastFound
FROM FoundPokemon
JOIN Users ON FoundPokemon.user_id = Users.user_id
WHERE UserID != 'admin' -- exclude admin user
  AND FoundPokemon.pokemon_id <= 151 -- exclude Pokemon with ID > 151 (like Missingno)
GROUP BY Users.name;

-- view number of pokemon found by user (excluding MissingNo for milestones)
CREATE VIEW IF NOT EXISTS ViewNumPokemonFoundForMilestones AS
SELECT 
    Users.user_id AS UserID,
    Users.name AS User, 
    COUNT(FoundPokemon.pokemon_id) AS PokemonFound,
    -- time of last found pokemon
    MAX(FoundPokemon.found_timestamp) AS LastFound
FROM FoundPokemon
JOIN Users ON FoundPokemon.user_id = Users.user_id
WHERE UserID != 'admin' -- exclude admin user
  AND FoundPokemon.pokemon_id <= 151 -- only count original 151 Pokemon (excludes MissingNo with ID 312798312)
GROUP BY Users.name;

-- Top finders
CREATE VIEW IF NOT EXISTS ViewTopFinders AS
SELECT UserID, User, PokemonFound, LastFound FROM ViewNumPokemonFound
ORDER BY PokemonFound DESC, LastFound ASC;

-- view where we get user's ranking in ViewTopFinders
CREATE VIEW IF NOT EXISTS ViewUserRanking AS
SELECT 
    UserID, 
    User, 
    PokemonFound,
    LastFound,
    (SELECT COUNT(*) FROM ViewTopFinders WHERE PokemonFound > t.PokemonFound OR (PokemonFound = t.PokemonFound AND LastFound < t.LastFound)) + 1 AS Ranking
FROM ViewTopFinders AS t;

-- view users without the admin user included
CREATE VIEW IF NOT EXISTS ViewUsers AS
SELECT 
    Users.user_id AS UserID,
    Users.name AS User,
    Users.email AS Email,
    Users.phone AS Phone,
    Users.admin AS Admin
FROM Users 
WHERE UserId != 'admin'; -- exclude admin user

-- view users along with num pokemon found without the admin user included
CREATE VIEW IF NOT EXISTS ViewUsersWithPokemonFound AS
SELECT 
    Users.user_id AS UserID,
    Users.name AS User, 
    Users.email AS Email,
    Users.phone AS Phone,
    Users.admin AS Admin,
    COUNT(FoundPokemon.pokemon_id) AS PokemonFound
FROM FoundPokemon
JOIN Users ON FoundPokemon.user_id = Users.user_id
WHERE Users.admin = 0
GROUP BY Users.name;


-- Pokemon type statistics views
CREATE VIEW IF NOT EXISTS ViewUserPokemonByType AS
SELECT 
    u.user_id AS UserID,
    u.name AS User,
    pt.type_name AS Type,
    COUNT(DISTINCT fp.pokemon_id) AS PokemonCount
FROM Users u
CROSS JOIN PokemonTypes pt
LEFT JOIN FoundPokemon fp ON u.user_id = fp.user_id
LEFT JOIN PokemonTypeLinks ptl ON fp.pokemon_id = ptl.pokemon_id AND pt.type_id = ptl.type_id
WHERE u.user_id != 'admin'
GROUP BY u.user_id, u.name, pt.type_name
HAVING PokemonCount > 0
ORDER BY u.name, pt.type_name;

CREATE VIEW IF NOT EXISTS ViewTotalPokemonByType AS
SELECT 
    pt.type_name AS Type,
    COUNT(DISTINCT fp.user_id || '-' || fp.pokemon_id) AS TotalCatches
FROM PokemonTypes pt
LEFT JOIN PokemonTypeLinks ptl ON pt.type_id = ptl.type_id
LEFT JOIN FoundPokemon fp ON ptl.pokemon_id = fp.pokemon_id
WHERE fp.user_id IS NULL OR fp.user_id != 'admin'
GROUP BY pt.type_name
ORDER BY pt.type_name;
