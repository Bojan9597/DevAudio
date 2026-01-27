-- Clean AudioBooks Database Setup
-- Generated: 2026-01-27 16:39:24.625670
-- This script creates the database structure and populates ONLY: categories, badges, server_config

SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- --------------------------------------------------------
-- Table structure for `badges`
--
DROP TABLE IF EXISTS `badges`;
CREATE TABLE `badges` (
  `id` int NOT NULL AUTO_INCREMENT,
  `category` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci,
  `code` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `threshold` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=62 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `badges`
INSERT INTO `badges` VALUES
(54, 'read', 'Read 1 Book', 'Finished your first book', 'read_1', 1, '2026-01-23 00:46:06'),
(55, 'read', 'Read 2 Books', 'Finished 2 books', 'read_2', 2, '2026-01-23 00:46:06'),
(56, 'read', 'Read 5 Books', 'Finished 5 books', 'read_5', 5, '2026-01-23 00:46:06'),
(57, 'read', 'Read 10 Books', 'Finished 10 books', 'read_10', 10, '2026-01-23 00:46:06');

-- --------------------------------------------------------
-- Table structure for `book_categories`
--
DROP TABLE IF EXISTS `book_categories`;
CREATE TABLE `book_categories` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `book_id` int unsigned NOT NULL,
  `category_id` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_book_category` (`book_id`,`category_id`),
  KEY `category_id` (`category_id`),
  CONSTRAINT `book_categories_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `book_categories_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `book_categories` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `book_ratings`
--
DROP TABLE IF EXISTS `book_ratings`;
CREATE TABLE `book_ratings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `book_id` int NOT NULL,
  `user_id` int NOT NULL,
  `stars` int NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_book` (`user_id`,`book_id`),
  KEY `idx_book_id` (`book_id`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `book_ratings` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `bookmarks`
--
DROP TABLE IF EXISTS `bookmarks`;
CREATE TABLE `bookmarks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  `chapter` varchar(100) DEFAULT NULL,
  `note` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_bookmark` (`user_id`,`book_id`,`chapter`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `bookmarks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `bookmarks_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `bookmarks` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `books`
--
DROP TABLE IF EXISTS `books`;
CREATE TABLE `books` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `author` varchar(150) NOT NULL,
  `duration_seconds` int unsigned NOT NULL DEFAULT '0',
  `audio_path` varchar(255) NOT NULL,
  `cover_image_path` varchar(255) DEFAULT NULL,
  `price` decimal(8,2) NOT NULL DEFAULT '0.00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `primary_category_id` int unsigned DEFAULT NULL,
  `posted_by_user_id` int DEFAULT NULL,
  `description` text,
  `is_encrypted` tinyint(1) DEFAULT '0',
  `pdf_path` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_books_primary_category` (`primary_category_id`),
  CONSTRAINT `fk_books_primary_category` FOREIGN KEY (`primary_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `books` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `categories`
--
DROP TABLE IF EXISTS `categories`;
CREATE TABLE `categories` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) DEFAULT NULL,
  `parent_id` int unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `parent_id` (`parent_id`),
  CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=133 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `categories`
INSERT INTO `categories` VALUES
(92, 'Operating Systems', 'operating_systems', NULL, '2026-01-21 21:26:25'),
(93, 'Programming Languages', 'programming_languages', NULL, '2026-01-21 21:26:25'),
(94, 'Linux', 'linux', 92, '2026-01-21 21:26:25'),
(95, 'Linux Networking', 'linux_networking', 94, '2026-01-21 21:26:25'),
(96, 'Linux Filesystems', 'linux_filesystems', 94, '2026-01-21 21:26:25'),
(97, 'Linux Security', 'linux_security', 94, '2026-01-21 21:26:25'),
(98, 'Linux Shell Scripting', 'linux_shell_scripting', 94, '2026-01-21 21:26:25'),
(99, 'Linux System Administration', 'linux_system_admin', 94, '2026-01-21 21:26:25'),
(100, 'Windows', 'windows', 92, '2026-01-21 21:26:25'),
(101, 'Windows Internals', 'windows_internals', 100, '2026-01-21 21:26:25'),
(102, 'Windows PowerShell', 'windows_powershell', 100, '2026-01-21 21:26:25'),
(103, 'Windows Networking', 'windows_networking', 100, '2026-01-21 21:26:25'),
(104, 'Windows Security', 'windows_security', 100, '2026-01-21 21:26:25'),
(105, 'Windows Administration', 'windows_administration', 100, '2026-01-21 21:26:25'),
(106, 'macOS', 'macos', 92, '2026-01-21 21:26:25'),
(107, 'macOS Networking', 'macos_networking', 106, '2026-01-21 21:26:25'),
(108, 'macOS Filesystems', 'macos_filesystems', 106, '2026-01-21 21:26:25'),
(109, 'macOS Security', 'macos_security', 106, '2026-01-21 21:26:25'),
(110, 'macOS Shell', 'macos_shell', 106, '2026-01-21 21:26:25'),
(111, 'Python', 'python', 93, '2026-01-21 21:26:25'),
(112, 'Python Basics', 'python_basics', 111, '2026-01-21 21:26:25'),
(113, 'Python Advanced', 'python_advanced', 111, '2026-01-21 21:26:25'),
(114, 'Python Web', 'python_web', 111, '2026-01-21 21:26:25'),
(115, 'Python Data Science', 'python_data_science', 111, '2026-01-21 21:26:25'),
(116, 'Python Scripting', 'python_scripting', 111, '2026-01-21 21:26:25'),
(117, 'C/C++', 'c_cpp', 93, '2026-01-21 21:26:25'),
(118, 'C Basics', 'c_basics', 117, '2026-01-21 21:26:25'),
(119, 'C++ Basics', 'cpp_basics', 117, '2026-01-21 21:26:25'),
(120, 'C++ Advanced', 'cpp_advanced', 117, '2026-01-21 21:26:25'),
(121, 'C++ STL', 'cpp_stl', 117, '2026-01-21 21:26:25'),
(122, 'C++ System Programming', 'cpp_system_programming', 117, '2026-01-21 21:26:25'),
(123, 'Java', 'java', 93, '2026-01-21 21:26:25'),
(124, 'Java Basics', 'java_basics', 123, '2026-01-21 21:26:25'),
(125, 'Java OOP', 'java_oop', 123, '2026-01-21 21:26:25'),
(126, 'Java Web', 'java_web', 123, '2026-01-21 21:26:25'),
(127, 'Java Concurrency', 'java_concurrency', 123, '2026-01-21 21:26:25'),
(128, 'JavaScript', 'javascript', 93, '2026-01-21 21:26:25'),
(129, 'JavaScript Basics', 'js_basics', 128, '2026-01-21 21:26:25'),
(130, 'JavaScript Browser', 'js_browser', 128, '2026-01-21 21:26:25'),
(131, 'JavaScript Node.js', 'js_node', 128, '2026-01-21 21:26:25'),
(132, 'JavaScript Frameworks', 'js_frameworks', 128, '2026-01-21 21:26:25');

-- --------------------------------------------------------
-- Table structure for `encrypted_files`
--
DROP TABLE IF EXISTS `encrypted_files`;
CREATE TABLE `encrypted_files` (
  `id` int NOT NULL AUTO_INCREMENT,
  `original_path` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `encrypted_path` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `content_key_encrypted` blob NOT NULL,
  `content_iv` binary(16) NOT NULL,
  `auth_tag` binary(16) NOT NULL,
  `file_size` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `encrypted_path` (`encrypted_path`),
  KEY `idx_original_path` (`original_path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `encrypted_files` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `favorites`
--
DROP TABLE IF EXISTS `favorites`;
CREATE TABLE `favorites` (
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  PRIMARY KEY (`user_id`,`book_id`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `favorites` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `pending_users`
--
DROP TABLE IF EXISTS `pending_users`;
CREATE TABLE `pending_users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `verification_code` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `pending_users` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `playback_history`
--
DROP TABLE IF EXISTS `playback_history`;
CREATE TABLE `playback_history` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  `playlist_item_id` int DEFAULT NULL,
  `start_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `end_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `played_seconds` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_book_track` (`user_id`,`book_id`,`playlist_item_id`),
  KEY `book_id` (`book_id`),
  KEY `idx_playlist_item_id` (`playlist_item_id`),
  CONSTRAINT `fk_playback_playlist_item` FOREIGN KEY (`playlist_item_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `playback_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `playback_history_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=525 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `playback_history` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `playlist_items`
--
DROP TABLE IF EXISTS `playlist_items`;
CREATE TABLE `playlist_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `book_id` int NOT NULL,
  `file_path` varchar(512) COLLATE utf8mb4_general_ci NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `duration_seconds` int DEFAULT '0',
  `track_order` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `content_key_encrypted` blob COMMENT 'Encrypted content key (AES-256-GCM)',
  `content_iv` binary(12) DEFAULT NULL COMMENT 'IV used for content encryption (GCM uses 12 bytes)',
  `auth_tag` binary(16) DEFAULT NULL COMMENT 'GCM authentication tag',
  `encryption_version` int DEFAULT NULL COMMENT 'Encryption scheme version',
  PRIMARY KEY (`id`),
  KEY `idx_book_id` (`book_id`)
) ENGINE=InnoDB AUTO_INCREMENT=92 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `playlist_items` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `quiz_questions`
--
DROP TABLE IF EXISTS `quiz_questions`;
CREATE TABLE `quiz_questions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `quiz_id` int NOT NULL,
  `question_text` text COLLATE utf8mb4_general_ci NOT NULL,
  `option_a` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `option_b` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `option_c` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `option_d` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `correct_answer` char(1) COLLATE utf8mb4_general_ci NOT NULL,
  `order_index` int DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `quiz_id` (`quiz_id`),
  CONSTRAINT `quiz_questions_ibfk_1` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `quiz_questions` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `quizzes`
--
DROP TABLE IF EXISTS `quizzes`;
CREATE TABLE `quizzes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `book_id` int unsigned NOT NULL,
  `playlist_item_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_book_track_quiz` (`book_id`,`playlist_item_id`),
  KEY `fk_quizzes_playlist_item` (`playlist_item_id`),
  CONSTRAINT `fk_quizzes_playlist_item` FOREIGN KEY (`playlist_item_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `quizzes_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `quizzes` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `server_config`
--
DROP TABLE IF EXISTS `server_config`;
CREATE TABLE `server_config` (
  `id` int NOT NULL AUTO_INCREMENT,
  `config_key` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `config_value` text COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `config_key` (`config_key`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for `server_config`
INSERT INTO `server_config` VALUES
(1, 'master_secret', 'y6yj2Pp2PyFElOR3/s5Aq7MvGPKnIZJ58g2xPfaF3zM=', '2026-01-23 10:24:43', '2026-01-23 10:24:43');

-- --------------------------------------------------------
-- Table structure for `subscription_history`
--
DROP TABLE IF EXISTS `subscription_history`;
CREATE TABLE `subscription_history` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `action` enum('subscribed','renewed','cancelled','expired','upgraded','downgraded') COLLATE utf8mb4_general_ci NOT NULL,
  `plan_type` enum('test_minute','monthly','yearly','lifetime') COLLATE utf8mb4_general_ci DEFAULT NULL,
  `action_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text COLLATE utf8mb4_general_ci,
  PRIMARY KEY (`id`),
  KEY `idx_user_action` (`user_id`,`action_date`),
  CONSTRAINT `subscription_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=456 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `subscription_history` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `subscriptions`
--
DROP TABLE IF EXISTS `subscriptions`;
CREATE TABLE `subscriptions` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `plan_type` enum('test_minute','monthly','yearly','lifetime') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'monthly',
  `status` enum('active','expired','cancelled') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'active',
  `start_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `end_date` timestamp NULL DEFAULT NULL,
  `auto_renew` tinyint(1) DEFAULT '1',
  `payment_provider` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `external_subscription_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `idx_user_status` (`user_id`,`status`),
  KEY `idx_end_date` (`end_date`),
  CONSTRAINT `subscriptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `subscriptions` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `token_blacklist`
--
DROP TABLE IF EXISTS `token_blacklist`;
CREATE TABLE `token_blacklist` (
  `id` int NOT NULL AUTO_INCREMENT,
  `token` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `blacklisted_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_token` (`token`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=484 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `token_blacklist` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_badges`
--
DROP TABLE IF EXISTS `user_badges`;
CREATE TABLE `user_badges` (
  `user_id` int unsigned NOT NULL,
  `badge_id` int NOT NULL,
  `earned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`,`badge_id`),
  KEY `badge_id` (`badge_id`),
  CONSTRAINT `user_badges_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_badges_ibfk_2` FOREIGN KEY (`badge_id`) REFERENCES `badges` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_badges` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_books`
--
DROP TABLE IF EXISTS `user_books`;
CREATE TABLE `user_books` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  `last_played_position_seconds` int unsigned DEFAULT '0',
  `playback_speed` decimal(3,1) DEFAULT '1.0',
  `is_downloaded` tinyint(1) DEFAULT '0',
  `download_path` varchar(255) DEFAULT NULL,
  `purchased_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_accessed_at` timestamp NULL DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT '0',
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `current_playlist_item_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_book` (`user_id`,`book_id`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `user_books_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_books_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_books` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_completed_tracks`
--
DROP TABLE IF EXISTS `user_completed_tracks`;
CREATE TABLE `user_completed_tracks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `track_id` int NOT NULL,
  `completed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_completion` (`user_id`,`track_id`),
  KEY `track_id` (`track_id`),
  CONSTRAINT `user_completed_tracks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_completed_tracks_ibfk_2` FOREIGN KEY (`track_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=351 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_completed_tracks` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_content_keys`
--
DROP TABLE IF EXISTS `user_content_keys`;
CREATE TABLE `user_content_keys` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `device_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `media_id` int unsigned NOT NULL,
  `wrapped_key` blob NOT NULL COMMENT 'ContentKey wrapped with UserKey',
  `wrap_iv` binary(12) NOT NULL COMMENT 'IV used for key wrapping',
  `wrap_auth_tag` binary(16) NOT NULL COMMENT 'GCM auth tag for wrapping',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_device_media` (`user_id`,`device_id`,`media_id`),
  KEY `idx_user_device` (`user_id`,`device_id`),
  KEY `idx_media` (`media_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_content_keys` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_downloads`
--
DROP TABLE IF EXISTS `user_downloads`;
CREATE TABLE `user_downloads` (
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  `downloaded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`,`book_id`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `user_downloads_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_downloads_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_downloads` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_quiz_results`
--
DROP TABLE IF EXISTS `user_quiz_results`;
CREATE TABLE `user_quiz_results` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `quiz_id` int NOT NULL,
  `score_percentage` decimal(5,2) DEFAULT '0.00',
  `is_passed` tinyint(1) DEFAULT '0',
  `completed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `quiz_id` (`quiz_id`),
  CONSTRAINT `user_quiz_results_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_quiz_results_ibfk_2` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_quiz_results` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_sessions`
--
DROP TABLE IF EXISTS `user_sessions`;
CREATE TABLE `user_sessions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `session_id` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `refresh_token` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `access_token` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `device_info` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `refresh_token` (`refresh_token`),
  UNIQUE KEY `unique_user` (`user_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_refresh_token` (`refresh_token`),
  KEY `idx_expires` (`expires_at`),
  KEY `idx_access_token` (`access_token`),
  CONSTRAINT `user_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=279 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_sessions` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `user_track_progress`
--
DROP TABLE IF EXISTS `user_track_progress`;
CREATE TABLE `user_track_progress` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  `playlist_item_id` int NOT NULL,
  `position_seconds` int DEFAULT '0',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_track` (`user_id`,`playlist_item_id`),
  KEY `book_id` (`book_id`),
  KEY `playlist_item_id` (`playlist_item_id`),
  CONSTRAINT `user_track_progress_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_track_progress_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_track_progress_ibfk_3` FOREIGN KEY (`playlist_item_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `user_track_progress` ignored (Clean setup)

-- --------------------------------------------------------
-- Table structure for `users`
--
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `aes_key` varchar(64) DEFAULT NULL,
  `status` enum('active','banned','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` timestamp NULL DEFAULT NULL,
  `profile_picture_url` varchar(255) DEFAULT NULL,
  `verification_code` varchar(6) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT '0',
  `encryption_key` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Data for `users` ignored (Clean setup)

SET FOREIGN_KEY_CHECKS=1;
COMMIT;
