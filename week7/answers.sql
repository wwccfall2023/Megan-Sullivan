-- Create your tables, views, functions and procedures here!
DROP SCHEMA IF EXISTS destruction;
CREATE SCHEMA destruction;
USE destruction;

CREATE TABLE players (
  player_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(30) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(50) NOT NULL
);

CREATE TABLE characters (
  character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  player_id INT UNSIGNED NOT NULL,
  `name` VARCHAR(30) NOT NULL,
  `level` INT UNSIGNED NOT NULL,
  CONSTRAINT  characters_fk_players
    FOREIGN KEY (player_id)
    REFERENCES players (player_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE winners ( 
  character_id INT UNSIGNED,
  `name` VARCHAR(30) NOT NULL,
  CONSTRAINT winners_fk_characters
    FOREIGN KEY (character_id) 
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE character_stats (
  character_id INT UNSIGNED,
  health INT UNSIGNED NOT NULL,
  armor INT UNSIGNED NOT NULL,
  CONSTRAINT character_stats_fk_characters
    FOREIGN KEY (character_id) 
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE teams (
  team_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL
);

CREATE TABLE team_members (
  team_member_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  team_id INT UNSIGNED,
  character_id INT UNSIGNED,
  CONSTRAINT team_members_fk_teams
    FOREIGN KEY (team_id)
    REFERENCES teams (team_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT team_members_fk_characters
    FOREIGN KEY (character_id) 
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE items (
  item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL,
  armor INT UNSIGNED NOT NULL,
  damage INT UNSIGNED NOT NULL
);

CREATE TABLE inventory (
  inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  character_id INT UNSIGNED,
  item_id INT UNSIGNED,
  CONSTRAINT inventory_fk_characters
    FOREIGN KEY (character_id) 
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT inventory_fk_items
    FOREIGN KEY (item_id)
    REFERENCES items (item_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE VIEW character_items AS
SELECT c.character_id, c.name AS character_name, i.name AS item_name, i.armor, i.damage
FROM characters c
JOIN (
  -- Union the inventory and equipped tables to get all items carried by a character
  SELECT character_id, item_id FROM inventory
  UNION
  SELECT character_id, item_id FROM equipped
) AS carried ON c.character_id = carried.character_id
JOIN items i ON carried.item_id = i.item_id
GROUP BY c.character_id, i.item_id -- Deduplicate the items by character and item
ORDER BY c.character_id, i.name;

CREATE VIEW team_items AS
SELECT t.team_id, t.name AS team_name, i.name AS item_name, i.armor, i.damage
FROM teams t
JOIN team_members tm ON t.team_id = tm.team_id
JOIN (
  -- Union the inventory and equipped tables to get all items carried by a character
  SELECT character_id, item_id FROM inventory
  UNION
  SELECT character_id, item_id FROM equipped
) AS carried ON tm.character_id = carried.character_id
JOIN items i ON carried.item_id = i.item_id
GROUP BY t.team_id, i.item_id -- Deduplicate the items by team and item
ORDER BY t.team_id, i.name;








