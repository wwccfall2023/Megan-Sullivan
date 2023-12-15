
-- Create your tables, views, functions and procedures here!
DROP SCHEMA IF EXISTS social;
CREATE SCHEMA social;
USE social;
-- Create your tables, views, functions and procedures here!
DROP SCHEMA IF EXISTS social;
CREATE SCHEMA social;
USE social;

-- Create 'users' table
CREATE TABLE users (
  user_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(30) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(50) NOT NULL,
  created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create 'sessions' table
CREATE TABLE sessions (
    session_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT  sessions_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Create 'friends' table
CREATE TABLE friends (
    user_friend_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    friend_id INT UNSIGNED NOT NULL,
    CONSTRAINT  friends_user_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    CONSTRAINT  friends_friend_fk_users
    FOREIGN KEY (friend_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Create 'posts' table
CREATE TABLE posts (
    post_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    content VARCHAR(255) NOT NULL,
    CONSTRAINT  posts_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Create 'notifications' table
CREATE TABLE notifications (
    notification_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT UNSIGNED NOT NULL,
    post_id INT UNSIGNED NOT NULL,
    CONSTRAINT  notifications_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    CONSTRAINT  notifications_fk_posts
    FOREIGN KEY (post_id)
    REFERENCES posts (post_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);



-- Create notification_posts VIEW
CREATE VIEW notification_posts AS
SELECT n.user_id, u.first_name, u.last_name, p.post_id, p.content
FROM notifications n
LEFT OUTER JOIN users u ON n.user_id = u.user_id
LEFT OUTER JOIN posts p ON n.post_id = p.post_id;



DELIMITER ;;
CREATE TRIGGER after_user_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    DECLARE new_user_id INT UNSIGNED;
    DECLARE new_post_id INT UNSIGNED;
    DECLARE new_friend_id INT UNSIGNED;
    DECLARE row_not_found TINYINT DEFAULT FALSE;
	
    DECLARE users_cursor CURSOR FOR 
		SELECT user_id 
		FROM users 
		WHERE user_id != NEW.user_id;
            
    DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET row_not_found = TRUE;
        
    INSERT INTO posts (user_id, content) VALUES (NEW.user_id, 'just joined!');
    SET new_post_id = LAST_INSERT_ID();
        
    DELETE FROM notifications;
    
    OPEN users_cursor;
    user_loop: LOOP
    FETCH users_cursor INTO new_user_id;
    IF row_not_found THEN
	LEAVE user_loop;
    END IF;
    INSERT INTO notifications (user_id, post_id) 
    VALUES 
    (new_user_id, new_post_id);
  END LOOP;
  CLOSE users_cursor; -- LOOK I CLOSED MY CURSOR THIS TIME!!! :D
END;;
DELIMITER ;


CREATE EVENT IF NOT EXISTS remove_old_sessions
ON SCHEDULE EVERY 10 SECOND
DO
DELETE FROM sessions 
WHERE updated_on < NOW() - INTERVAL 2 HOUR;


DELIMITER ;;
CREATE PROCEDURE add_post(IN user_id INT, IN content TEXT)
BEGIN
  DECLARE new_post_id INT;
  DECLARE new_friend_id INT;
  DECLARE row_not_found TINYINT DEFAULT FALSE;
  
  DECLARE friend_cursor CURSOR FOR 
  SELECT f.friend_id 
  FROM friends f
  WHERE f.user_id = user_id;
  
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET row_not_found = TRUE;

  -- Create a new post with the desired message
  INSERT INTO posts (posts.user_id, posts.content) VALUES (user_id, content);
    SET new_post_id = LAST_INSERT_ID();

  -- Add a notification for each of the user's friends
  OPEN friend_cursor;
  friend_loop: LOOP
    FETCH friend_cursor INTO new_friend_id;
    IF row_not_found THEN
	LEAVE friend_loop;
    END IF;
    INSERT INTO notifications (user_id, post_id) VALUES (new_friend_id, new_post_id);
  END LOOP;
  CLOSE friend_cursor;
END;;
DELIMITER ;

