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
















