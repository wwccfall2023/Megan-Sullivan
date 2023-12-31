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
  armor INT UNSIGNED,
  damage INT UNSIGNED
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
INNER JOIN (
  -- Union the inventory and equipped tables to get all items carried by a character
  SELECT i.character_id, i.item_id FROM inventory i
  UNION
  SELECT e.character_id, e.item_id FROM equipped e
) AS carried ON c.character_id = carried.character_id
INNER JOIN items i ON carried.item_id = i.item_id
GROUP BY c.character_id, i.item_id -- Deduplicate the items by character and item
ORDER BY c.character_id, i.name;

CREATE VIEW team_items AS
SELECT t.team_id, t.name AS team_name, i.name AS item_name, i.armor, i.damage
FROM teams t
INNER JOIN team_members tm ON t.team_id = tm.team_id
INNER JOIN (
  -- Union the inventory and equipped tables to get all items carried by a character
  SELECT i.character_id, i.item_id FROM inventory i
  UNION
  SELECT e.character_id, e.item_id FROM equipped e
) AS carried ON tm.character_id = carried.character_id
INNER JOIN items i ON carried.item_id = i.item_id
GROUP BY t.team_id, i.item_id -- Deduplicate the items by team and item
ORDER BY t.team_id, i.name;

-- Create a function named armor_total
DELIMITER ;;
CREATE FUNCTION armor_total(a_t_character_id INT UNSIGNED)
RETURNS INT
DETERMINISTIC
BEGIN
  -- Declare a variable to store the total armor
  -- DECLARE total_armor INT DEFAULT 0;
  DECLARE cs_armor INT DEFAULT 0;
  DECLARE i_armor INT DEFAULT 0;
  -- Add the armor from the character's stats
  -- SET cs_armor = SUM(cs.armor);
  -- SET i_armor = SUM(e.armor);
  -- SET total_armor = cs_armor + i_armor;
  SELECT SUM(cs.armor) INTO cs_armor
  FROM character_stats cs
  WHERE a_t_character_id = cs.character_id;
  -- Add the armor from the items the character has equipped
  SELECT SUM(i.armor) INTO i_armor
  FROM equipped e
  INNER JOIN items i ON e.item_id = i.item_id
  WHERE e.character_id = a_t_character_id;
  -- Return the total armor
  RETURN cs_armor + i_armor;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named attack
CREATE PROCEDURE attack(attacked_char_id INT UNSIGNED, equipped_id INT UNSIGNED)
BEGIN
  -- Declare variables to store the armor, damage, and health of the character being attacked
  DECLARE new_armor INT DEFAULT 0;
  DECLARE new_damage INT DEFAULT 0;
  DECLARE new_health INT DEFAULT 0;
  -- Call the armor_total function to get the armor of the character being attacked
  SET new_armor = armor_total(attacked_char_id);
  -- Get the damage of the item being used to attack from the items table
  SELECT i.damage INTO new_damage
  FROM items i
  INNER JOIN equipped e
    ON i.item_id = e.item_id
  WHERE e.equipped_id = equipped_id;
  -- Subtract the armor from the damage to get the net damage
  SET new_damage = new_damage - new_armor;
  -- If the net damage is positive, proceed to update the character's health
  IF new_damage > 0 THEN
    -- Get the current health of the character being attacked from the character_stats table
    SELECT cs.health INTO new_health
    FROM character_stats cs
    WHERE cs.character_id = attacked_char_id;
    -- Subtract the net damage from the current health to get the new health
    SET new_health = new_health - new_damage;
    -- If the new health is positive, update the character_stats table with the new health
    IF new_health > 0 THEN
      UPDATE character_stats cs
      SET cs.health = new_health
      WHERE cs.character_id = attacked_char_id;
    -- Else, if the new health is zero or negative, delete the character from the database
    ELSE
      -- Delete the character from the characters table
      -- This will also delete the character from the winners, character_stats, team_members, inventory, and equipped tables due to the cascade option on the foreign keys
      DELETE FROM characters c
      WHERE c.character_id = attacked_char_id;
    END IF;
--   -- Else, if the net damage is zero or negative, do nothing
--   ELSE
--     -- No action needed
END IF;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named equip
CREATE PROCEDURE equip(equip_inventory_id INT UNSIGNED)
BEGIN
  -- Declare variables to store the character_id and item_id of the inventory item
  DECLARE cid INT UNSIGNED DEFAULT 0;
  DECLARE iid INT UNSIGNED DEFAULT 0;
  -- Get the character_id and item_id from the inventory table
  SELECT i.character_id, i.item_id INTO cid, iid
  FROM inventory i
  WHERE i.inventory_id = equip_inventory_id;
  -- Insert the item into the equipped table with the same character_id and item_id
  INSERT INTO equipped (character_id, item_id)
  VALUES (cid, iid);
  -- Delete the item from the inventory table
  DELETE FROM inventory i
  WHERE i.inventory_id = equip_inventory_id;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named unequip
CREATE PROCEDURE unequip(unequip_equipped_id INT UNSIGNED)
BEGIN
  -- Declare variables to store the character_id and item_id of the equipped item
  DECLARE cid INT UNSIGNED DEFAULT 0;
  DECLARE iid INT UNSIGNED DEFAULT 0;
  -- Get the character_id and item_id from the equipped table
  SELECT character_id, item_id INTO cid, iid
  FROM equipped e
  WHERE e.equipped_id = unequip_equipped_id;
  -- Insert the item into the inventory table with the same character_id and item_id
  INSERT INTO inventory (character_id, item_id)
  VALUES (cid, iid);
  -- Delete the item from the equipped table
  DELETE FROM equipped e
  WHERE e.equipped_id = unequip_equipped_id;
END;;
DELIMITER ;

DELIMITER ;;
-- Create a procedure named set_winners
-- set_winners(team_id): Update the winners table so that only the characters in the passed team on in the winners table.
CREATE PROCEDURE set_winners(team_id INT UNSIGNED)
BEGIN
  -- Delete all the existing records from the winners table
    DECLARE id INT UNSIGNED;
    DECLARE winner_name VARCHAR(30);
    DECLARE row_not_found TINYINT DEFAULT FALSE;
    
	DECLARE characters_cursor CURSOR FOR
		SELECT c.character_id, c.name
			FROM characters c
				INNER JOIN team_members tm 
                ON c.character_id = tm.character_id
			WHERE tm.team_id = team_id;
            
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET row_not_found = TRUE;
        
	DELETE FROM winners;
    
    OPEN characters_cursor;
    character_loop : LOOP
		FETCH characters_cursor INTO id, winner_name;
        IF row_not_found THEN
			LEAVE character_loop;
		END IF;
        
        INSERT INTO winners
			(character_id, name)
		VALUES
			(id, winner_name);
			
	END LOOP character_loop;
END;;
DELIMITER ;

/*
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
  INNER JOIN team_members tm ON c.character_id = tm.character_id
  WHERE tm.team_id = team_id;
END;;
DELIMITER ;
*/
