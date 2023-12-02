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

CREATE TABLE equipped (
  equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  character_id INT UNSIGNED,
  item_id INT UNSIGNED,
  CONSTRAINT equipped_fk_characters
    FOREIGN KEY (character_id) 
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT equipped_fk_items
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

-- Create a function named armor_total
DELIMITER ;;
CREATE FUNCTION armor_total(character_id INT UNSIGNED)
RETURNS INT
DETERMINISTIC
BEGIN
  -- Declare a variable to store the total armor
  DECLARE total_armor INT DEFAULT 0;
  -- Add the armor from the character's stats
  SELECT armor INTO total_armor
  FROM character_stats
  WHERE character_id = character_id;
  -- Add the armor from the items the character has equipped
  SELECT SUM(i.armor) INTO total_armor
  FROM equipped e
  JOIN items i ON e.item_id = i.item_id
  WHERE e.character_id = character_id;
  -- Return the total armor
  RETURN total_armor;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named attack
CREATE PROCEDURE attack(id_of_character_being_attacked INT UNSIGNED, id_of_equipped_item_used_for_attack INT UNSIGNED)
BEGIN
  -- Declare variables to store the armor, damage, and health of the character being attacked
  DECLARE armor INT DEFAULT 0;
  DECLARE damage INT DEFAULT 0;
  DECLARE health INT DEFAULT 0;
  -- Call the armor_total function to get the armor of the character being attacked
  SET armor = armor_total(id_of_character_being_attacked);
  -- Get the damage of the item being used to attack from the items table
  SELECT damage INTO damage
  FROM items
  WHERE item_id = id_of_equipped_item_used_for_attack;
  -- Subtract the armor from the damage to get the net damage
  SET damage = damage - armor;
  -- If the net damage is positive, proceed to update the character's health
  IF damage > 0 THEN
    -- Get the current health of the character being attacked from the character_stats table
    SELECT health INTO health
    FROM character_stats
    WHERE character_id = id_of_character_being_attacked;
    -- Subtract the net damage from the current health to get the new health
    SET health = health - damage;
    -- If the new health is positive, update the character_stats table with the new health
    IF health > 0 THEN
      UPDATE character_stats
      SET health = health
      WHERE character_id = id_of_character_being_attacked;
    -- Else, if the new health is zero or negative, delete the character from the database
    ELSE
      -- Delete the character from the characters table
      -- This will also delete the character from the winners, character_stats, team_members, inventory, and equipped tables due to the cascade option on the foreign keys
      DELETE FROM characters
      WHERE character_id = id_of_character_being_attacked;
    END IF;
--   -- Else, if the net damage is zero or negative, do nothing
--   ELSE
--     -- No action needed
END IF;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named equip
CREATE PROCEDURE equip(inventory_id INT UNSIGNED)
BEGIN
  -- Declare variables to store the character_id and item_id of the inventory item
  DECLARE cid INT UNSIGNED DEFAULT 0;
  DECLARE iid INT UNSIGNED DEFAULT 0;
  -- Get the character_id and item_id from the inventory table
  SELECT character_id, item_id INTO cid, iid
  FROM inventory
  WHERE inventory_id = iid;
  -- Insert the item into the equipped table with the same character_id and item_id
  INSERT INTO equipped (character_id, item_id)
  VALUES (cid, iid);
  -- Delete the item from the inventory table
  DELETE FROM inventory
  WHERE inventory_id = iid;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named unequip
CREATE PROCEDURE unequip(equipped_id INT UNSIGNED)
BEGIN
  -- Declare variables to store the character_id and item_id of the equipped item
  DECLARE character_id INT UNSIGNED DEFAULT 0;
  DECLARE item_id INT UNSIGNED DEFAULT 0;
  -- Get the character_id and item_id from the equipped table
  SELECT character_id, item_id INTO character_id, item_id
  FROM equipped
  WHERE equipped_id = equipped_id;
  -- Insert the item into the inventory table with the same character_id and item_id
  INSERT INTO inventory (character_id, item_id)
  VALUES (character_id, item_id);
  -- Delete the item from the equipped table
  DELETE FROM equipped
  WHERE equipped_id = equipped_id;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named set_winners
CREATE PROCEDURE set_winners(team_id INT UNSIGNED)
BEGIN
  -- Delete all the existing records from the winners table
  DELETE FROM winners;
  -- Insert the characters from the passed team into the winners table
  INSERT INTO winners (character_id, name)
  SELECT c.character_id, c.name
  FROM characters c
  JOIN team_members tm ON c.character_id = tm.character_id
  WHERE tm.team_id = team_id;
END;;
DELIMITER ;
