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
)

/*
-- Create 'users' table by Bing AI
CREATE TABLE users (
  user_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create 'sessions' table
CREATE TABLE sessions (
  session_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT sessions_fk_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create 'friends' table
CREATE TABLE friends (
  user_friend_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  friend_id INT NOT NULL,
  CONSTRAINT friends_fk_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT friends_fk_friend_id FOREIGN KEY (friend_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create 'posts' table
CREATE TABLE posts (
  post_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  created_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  content TEXT NOT NULL,
  CONSTRAINT posts_fk_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Create 'notifications' table
CREATE TABLE notifications (
  notification_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  post_id INT NOT NULL,
  CONSTRAINT notifications_fk_users FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT notifications_fk_posts FOREIGN KEY (post_id) REFERENCES posts(post_id) ON UPDATE CASCADE ON DELETE CASCADE
);
*/

-- Create 'notification_posts' VIEW
CREATE VIEW notification_posts AS
SELECT 
	n.user_id,
	u.first_name,
	u.last_name,
	p.post_id,
	p.content
FROM notifications n
LEFT JOIN users u ON n.user_id = u.user_id
LEFT JOIN posts p ON n.post_id = p.post_id;
