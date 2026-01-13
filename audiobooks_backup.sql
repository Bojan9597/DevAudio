-- AudioBooks Database Backup
-- Generated: 2026-01-13 00:57:53.643380

SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


-- --------------------------------------------------------
-- Table structure for table `badges`
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
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `badges`
INSERT INTO `badges` VALUES
(26, 'read', 'Read 1 Book', 'Finished your first book', 'read_1', 1, '2026-01-11 16:27:58'),
(27, 'read', 'Read 2 Books', 'Finished 2 books', 'read_2', 2, '2026-01-11 16:27:58'),
(28, 'read', 'Read 5 Books', 'Finished 5 books', 'read_5', 5, '2026-01-11 16:27:58'),
(29, 'read', 'Read 10 Books', 'Finished 10 books', 'read_10', 10, '2026-01-11 16:27:58'),
(30, 'buy', 'Collector I', 'Bought your first book', 'buy_1', 1, '2026-01-11 16:27:58'),
(31, 'buy', 'Collector II', 'Bought 2 books', 'buy_2', 2, '2026-01-11 16:27:58'),
(32, 'buy', 'Collector III', 'Bought 5 books', 'buy_5', 5, '2026-01-11 16:27:58'),
(33, 'buy', 'Collector IV', 'Bought 10 books', 'buy_10', 10, '2026-01-11 16:27:58');

-- --------------------------------------------------------
-- Table structure for table `book_categories`
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
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `book_categories`
INSERT INTO `book_categories` VALUES
(1, 1, 2),
(2, 1, 3),
(3, 1, 8),
(4, 2, 2),
(5, 2, 9),
(6, 2, 10),
(7, 3, 20),
(8, 3, 21),
(9, 3, 26),
(10, 4, 20),
(11, 4, 33),
(12, 4, 34),
(13, 5, 20),
(14, 5, 38),
(15, 5, 39),
(16, 6, 20),
(17, 6, 27),
(18, 6, 29),
(19, 7, 2),
(20, 7, 3),
(21, 7, 8),
(22, 7, 27),
(23, 7, 32),
(24, 8, 2),
(25, 8, 3),
(26, 8, 4),
(27, 9, 20),
(28, 9, 33),
(29, 9, 35),
(30, 10, 20),
(31, 10, 38);

-- --------------------------------------------------------
-- Table structure for table `bookmarks`
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

-- Dumping data for table `bookmarks`
-- No data for table `bookmarks`

-- --------------------------------------------------------
-- Table structure for table `books`
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
  PRIMARY KEY (`id`),
  KEY `fk_books_primary_category` (`primary_category_id`),
  CONSTRAINT `fk_books_primary_category` FOREIGN KEY (`primary_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `books`
INSERT INTO `books` VALUES
(1, 'my book', 'hi', 327, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258613_my_book/01_file_example_WAV_1MG.wav', 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/BookCovers/1768258613_20260110_191011.jpg', '0.00', '2026-01-12 23:56:53', 5, 1, ''),
(2, 'jd', 'jd', 213, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258842_jd/01_file_example_WAV_1MG.wav', 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/BookCovers/1768258842_20260108_152251.jpg', '0.00', '2026-01-13 00:00:42', 6, 1, ''),
(3, 'nee', 'jd', 138, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768259428_nee/01_file_example_WAV_1MG.wav', 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/BookCovers/1768259428_20260108_152251.jpg', '0.00', '2026-01-13 00:10:29', 7, 1, '');

-- --------------------------------------------------------
-- Table structure for table `categories`
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
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `categories`
INSERT INTO `categories` VALUES
(1, 'Programming', 'programming', NULL, '2026-01-10 17:17:41'),
(2, 'Operating Systems', 'operating_systems', 1, '2026-01-10 17:17:41'),
(3, 'Linux', 'linux', 2, '2026-01-10 17:17:41'),
(4, 'Networking', 'linux_networking', 3, '2026-01-10 17:17:41'),
(5, 'File Systems', 'linux_filesystems', 3, '2026-01-10 17:17:41'),
(6, 'Security', 'linux_security', 3, '2026-01-10 17:17:41'),
(7, 'Shell Scripting', 'linux_shell_scripting', 3, '2026-01-10 17:17:41'),
(8, 'System Administration', 'linux_system_admin', 3, '2026-01-10 17:17:41'),
(9, 'Windows', 'windows', 2, '2026-01-10 17:17:41'),
(10, 'Internals', 'windows_internals', 9, '2026-01-10 17:17:41'),
(11, 'PowerShell', 'windows_powershell', 9, '2026-01-10 17:17:41'),
(12, 'Networking', 'windows_networking', 9, '2026-01-10 17:17:41'),
(13, 'Security', 'windows_security', 9, '2026-01-10 17:17:41'),
(14, 'System Administration', 'windows_administration', 9, '2026-01-10 17:17:41'),
(15, 'macOS', 'macos', 2, '2026-01-10 17:17:41'),
(16, 'Networking', 'macos_networking', 15, '2026-01-10 17:17:41'),
(17, 'File Systems', 'macos_filesystems', 15, '2026-01-10 17:17:41'),
(18, 'Security', 'macos_security', 15, '2026-01-10 17:17:41'),
(19, 'Shell & Scripting', 'macos_shell', 15, '2026-01-10 17:17:41'),
(20, 'Programming Languages', 'programming_languages', 1, '2026-01-10 17:17:41'),
(21, 'Python', 'python', 20, '2026-01-10 17:17:41'),
(22, 'Basics', 'python_basics', 21, '2026-01-10 17:17:41'),
(23, 'Advanced Topics', 'python_advanced', 21, '2026-01-10 17:17:41'),
(24, 'Web Development', 'python_web', 21, '2026-01-10 17:17:41'),
(25, 'Data Science', 'python_data_science', 21, '2026-01-10 17:17:41'),
(26, 'Scripting & Automation', 'python_scripting', 21, '2026-01-10 17:17:41'),
(27, 'C / C++', 'c_cpp', 20, '2026-01-10 17:17:41'),
(28, 'C Basics', 'c_basics', 27, '2026-01-10 17:17:41'),
(29, 'C++ Basics', 'cpp_basics', 27, '2026-01-10 17:17:41'),
(30, 'C++ Advanced', 'cpp_advanced', 27, '2026-01-10 17:17:41'),
(31, 'STL', 'cpp_stl', 27, '2026-01-10 17:17:41'),
(32, 'System Programming', 'cpp_system_programming', 27, '2026-01-10 17:17:41'),
(33, 'Java', 'java', 20, '2026-01-10 17:17:41'),
(34, 'Basics', 'java_basics', 33, '2026-01-10 17:17:41'),
(35, 'Object-Oriented Programming', 'java_oop', 33, '2026-01-10 17:17:41'),
(36, 'Web Development', 'java_web', 33, '2026-01-10 17:17:41'),
(37, 'Concurrency & Threads', 'java_concurrency', 33, '2026-01-10 17:17:41'),
(38, 'JavaScript', 'javascript', 20, '2026-01-10 17:17:41'),
(39, 'Basics', 'js_basics', 38, '2026-01-10 17:17:41'),
(40, 'Browser & DOM', 'js_browser', 38, '2026-01-10 17:17:41'),
(41, 'Node.js', 'js_node', 38, '2026-01-10 17:17:41'),
(42, 'Frameworks (React, Vue, Angular)', 'js_frameworks', 38, '2026-01-10 17:17:41');

-- --------------------------------------------------------
-- Table structure for table `favorites`
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

-- Dumping data for table `favorites`
INSERT INTO `favorites` VALUES
(1, 1);

-- --------------------------------------------------------
-- Table structure for table `pending_users`
--

DROP TABLE IF EXISTS `pending_users`;
CREATE TABLE `pending_users` (
  `email` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `verification_code` varchar(6) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `pending_users`
-- No data for table `pending_users`

-- --------------------------------------------------------
-- Table structure for table `playback_history`
--

DROP TABLE IF EXISTS `playback_history`;
CREATE TABLE `playback_history` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int unsigned NOT NULL,
  `book_id` int unsigned NOT NULL,
  `start_time` timestamp NOT NULL,
  `end_time` timestamp NOT NULL,
  `played_seconds` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `playback_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `playback_history_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `playback_history`
INSERT INTO `playback_history` VALUES
(1, 1, 1, '2026-01-12 23:57:16', '2026-01-12 23:57:16', 320),
(2, 1, 1, '2026-01-12 23:57:31', '2026-01-12 23:57:31', 326),
(3, 1, 1, '2026-01-12 23:57:46', '2026-01-12 23:57:46', 341),
(4, 1, 1, '2026-01-12 23:58:01', '2026-01-12 23:58:01', 356),
(5, 1, 1, '2026-01-12 23:58:16', '2026-01-12 23:58:16', 371),
(6, 1, 1, '2026-01-12 23:58:31', '2026-01-12 23:58:31', 386),
(7, 1, 1, '2026-01-12 23:58:47', '2026-01-12 23:58:47', 401),
(8, 1, 1, '2026-01-12 23:59:02', '2026-01-12 23:59:02', 416),
(9, 1, 1, '2026-01-12 23:59:16', '2026-01-12 23:59:16', 431),
(10, 1, 2, '2026-01-13 00:01:08', '2026-01-13 00:01:08', 208),
(11, 1, 2, '2026-01-13 00:01:20', '2026-01-13 00:01:20', 213),
(12, 1, 2, '2026-01-13 00:01:31', '2026-01-13 00:01:31', 213),
(13, 1, 1, '2026-01-13 00:01:57', '2026-01-13 00:01:57', 100),
(14, 1, 1, '2026-01-13 00:04:18', '2026-01-13 00:04:18', 1022),
(15, 1, 1, '2026-01-13 00:04:29', '2026-01-13 00:04:29', 1057),
(16, 1, 1, '2026-01-13 00:04:34', '2026-01-13 00:04:34', 1057),
(17, 1, 3, '2026-01-13 00:10:50', '2026-01-13 00:10:50', 137),
(18, 1, 3, '2026-01-13 00:10:54', '2026-01-13 00:10:54', 138),
(19, 2, 3, '2026-01-13 00:18:55', '2026-01-13 00:18:55', 247),
(20, 2, 3, '2026-01-13 00:19:00', '2026-01-13 00:19:00', 131),
(21, 2, 3, '2026-01-13 00:19:06', '2026-01-13 00:19:06', 132);

-- --------------------------------------------------------
-- Table structure for table `playlist_items`
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
  PRIMARY KEY (`id`),
  KEY `idx_book_id` (`book_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `playlist_items`
INSERT INTO `playlist_items` VALUES
(1, 1, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258613_my_book/01_file_example_WAV_1MG.wav', 'file_example_WAV_1MG.wav', 0, 0, '2026-01-12 23:56:53'),
(2, 1, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258613_my_book/02_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 0, 1, '2026-01-12 23:56:53'),
(3, 1, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258613_my_book/03_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 0, 2, '2026-01-12 23:56:53'),
(4, 2, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258842_jd/01_file_example_WAV_1MG.wav', 'file_example_WAV_1MG.wav', 0, 0, '2026-01-13 00:00:42'),
(5, 2, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768258842_jd/02_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 0, 1, '2026-01-13 00:00:42'),
(6, 3, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768259428_nee/01_file_example_WAV_1MG.wav', 'file_example_WAV_1MG.wav', 0, 0, '2026-01-13 00:10:29'),
(7, 3, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768259428_nee/02_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 0, 1, '2026-01-13 00:10:29'),
(8, 3, 'https://pseudostigmatic-skeletonlike-coy.ngrok-free.dev/static/AudioBooks/1768259428_nee/03_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 0, 2, '2026-01-13 00:10:29');

-- --------------------------------------------------------
-- Table structure for table `user_badges`
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

-- Dumping data for table `user_badges`
INSERT INTO `user_badges` VALUES
(1, 26, '2026-01-13 00:01:23'),
(1, 27, '2026-01-13 00:04:32'),
(1, 30, '2026-01-12 23:57:16'),
(2, 26, '2026-01-13 00:19:17'),
(2, 30, '2026-01-13 00:18:39');

-- --------------------------------------------------------
-- Table structure for table `user_books`
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
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_book` (`user_id`,`book_id`),
  KEY `book_id` (`book_id`),
  CONSTRAINT `user_books_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `user_books_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `user_books`
INSERT INTO `user_books` VALUES
(1, 1, 1, 1057, '1.0', 0, NULL, '2026-01-12 23:56:53', '2026-01-13 00:04:34', 1, NULL, NULL),
(2, 1, 2, 213, '1.0', 0, NULL, '2026-01-13 00:00:42', '2026-01-13 00:01:31', 1, NULL, NULL),
(3, 1, 3, 138, '1.0', 0, NULL, '2026-01-13 00:10:29', '2026-01-13 00:10:54', 1, NULL, NULL),
(4, 2, 3, 132, '1.0', 0, NULL, '2026-01-13 00:18:39', '2026-01-13 00:19:17', 1, NULL, NULL);

-- --------------------------------------------------------
-- Table structure for table `user_completed_tracks`
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
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `user_completed_tracks`
INSERT INTO `user_completed_tracks` VALUES
(1, 1, 1, '2026-01-12 23:57:08'),
(3, 1, 4, '2026-01-13 00:00:59'),
(5, 1, 5, '2026-01-13 00:01:23'),
(7, 1, 2, '2026-01-13 00:04:14'),
(9, 1, 3, '2026-01-13 00:04:32'),
(10, 1, 6, '2026-01-13 00:10:38'),
(11, 1, 7, '2026-01-13 00:10:44'),
(12, 1, 8, '2026-01-13 00:10:51'),
(13, 2, 6, '2026-01-13 00:19:04'),
(14, 2, 7, '2026-01-13 00:19:05'),
(16, 2, 8, '2026-01-13 00:19:17');

-- --------------------------------------------------------
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `status` enum('active','banned','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` timestamp NULL DEFAULT NULL,
  `profile_picture_url` varchar(255) DEFAULT NULL,
  `verification_code` varchar(6) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table `users`
INSERT INTO `users` VALUES
(1, 'Bojan', 'bojanpejic97@gmail.com', 'scrypt:32768:8:1$nodErW0xkjbGPrD7$50c247b3e61f06dda27c82f4fed2b20c8b5db0a42f1a270c65e63c2befe8532752a1fd160b2c1373fe699739347a6351140db322b86d2010b9bfb26a9f768118', 'active', '2026-01-12 23:55:50', NULL, NULL, NULL, 0),
(2, 'Bojan Pejic', 'bojanpejic997@gmail.com', 'scrypt:32768:8:1$aacbC4vFrHcG1CnX$b6bbad242a2ce2f34933106836a184c956afcb1621f57082eb8d31343903721d4bd6901b0e53b6b8be151fad2c73aa4d9385bf67f039e0885fc350acdf219a0d', 'active', '2026-01-13 00:18:31', NULL, NULL, NULL, 0);

SET FOREIGN_KEY_CHECKS=1;
COMMIT;
