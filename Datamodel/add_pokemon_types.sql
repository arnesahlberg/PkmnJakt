-- Migration to add Pokemon types support
-- This migration adds tables for tracking Pokemon types and links Pokemon to their types
---------------------------------------------------

PRAGMA foreign_keys = ON;

-- Create PokemonTypes table to store all available types
CREATE TABLE IF NOT EXISTS PokemonTypes (
    type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name TEXT NOT NULL UNIQUE
);

-- Create PokemonTypeLinks table to link Pokemon to their types (many-to-many relationship)
CREATE TABLE IF NOT EXISTS PokemonTypeLinks (
    pokemon_id INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    type_order INTEGER NOT NULL, -- 1 for primary type, 2 for secondary type
    PRIMARY KEY (pokemon_id, type_id),
    FOREIGN KEY (pokemon_id) REFERENCES Pokemon(pokemon_id),
    FOREIGN KEY (type_id) REFERENCES PokemonTypes(type_id)
);

-- Insert all Pokemon types
INSERT INTO PokemonTypes (type_name) VALUES
    ('Normal'),
    ('Fire'),
    ('Water'),
    ('Electric'),
    ('Grass'),
    ('Ice'),
    ('Fighting'),
    ('Poison'),
    ('Ground'),
    ('Flying'),
    ('Psychic'),
    ('Bug'),
    ('Rock'),
    ('Ghost'),
    ('Dragon'),
    ('Dark'),
    ('Steel'),
    ('Fairy'),
    ('Bird'); -- Special type for MissingNo

-- Create view to get Pokemon with their types concatenated
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

-- Update ViewPokemonWithCatchCode to include types
DROP VIEW IF EXISTS ViewPokemonWithCatchCode;
CREATE VIEW ViewPokemonWithCatchCode AS
SELECT 
    p.pokemon_id AS pokemon_id,
    p.name AS name,
    p.description AS description,
    p.height AS height,
    p.active AS active,
    cc.catch_code AS catch_code,
    GROUP_CONCAT(pt.type_name, '/' ORDER BY ptl.type_order) AS types
FROM Pokemon p
JOIN CatchCodes cc ON p.pokemon_id = cc.pokemon_id
LEFT JOIN PokemonTypeLinks ptl ON p.pokemon_id = ptl.pokemon_id
LEFT JOIN PokemonTypes pt ON ptl.type_id = pt.type_id
GROUP BY p.pokemon_id, p.name, p.description, p.height, p.active, cc.catch_code;

-- Update ViewFoundPokemon to include types
DROP VIEW IF EXISTS ViewFoundPokemon;
CREATE VIEW ViewFoundPokemon AS
SELECT 
    u.user_id AS UserId,
    u.name AS User, 
    p.name AS Pokemon, 
    p.pokemon_id AS PokemonNumber,
    GROUP_CONCAT(pt.type_name, '/' ORDER BY ptl.type_order) AS Types,
    fp.found_timestamp AS TimeStamp, 
    fp.photo_path AS PhotoPath, 
    fp.comment AS Comment, 
    fp.rating AS Rating
FROM FoundPokemon fp
JOIN Users u ON fp.user_id = u.user_id
JOIN Pokemon p ON fp.pokemon_id = p.pokemon_id
LEFT JOIN PokemonTypeLinks ptl ON p.pokemon_id = ptl.pokemon_id
LEFT JOIN PokemonTypes pt ON ptl.type_id = pt.type_id
WHERE u.user_id != 'admin'
GROUP BY fp.found_id, u.user_id, u.name, p.name, p.pokemon_id, fp.found_timestamp, fp.photo_path, fp.comment, fp.rating;

-- Recreate ViewLatestFoundPokemon with the updated ViewFoundPokemon
DROP VIEW IF EXISTS ViewLatestFoundPokemon;
CREATE VIEW ViewLatestFoundPokemon AS
SELECT * FROM ViewFoundPokemon
ORDER BY TimeStamp DESC;

-- Create view for Pokemon count by type for each user
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

-- Create view for total Pokemon count by type across all users
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