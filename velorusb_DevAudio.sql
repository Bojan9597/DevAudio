-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Feb 01, 2026 at 05:17 PM
-- Server version: 11.4.9-MariaDB-log
-- PHP Version: 8.4.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `velorusb_DevAudio`
--

-- --------------------------------------------------------

--
-- Table structure for table `badges`
--

CREATE TABLE `badges` (
  `id` int(11) NOT NULL,
  `category` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `code` varchar(50) NOT NULL,
  `threshold` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `badges`
--

INSERT INTO `badges` (`id`, `category`, `name`, `description`, `code`, `threshold`, `created_at`) VALUES
(54, 'read', 'Read 1 Book', 'Finished your first book', 'read_1', 1, '2026-01-23 00:46:06'),
(55, 'read', 'Read 2 Books', 'Finished 2 books', 'read_2', 2, '2026-01-23 00:46:06'),
(56, 'read', 'Read 5 Books', 'Finished 5 books', 'read_5', 5, '2026-01-23 00:46:06'),
(57, 'read', 'Read 10 Books', 'Finished 10 books', 'read_10', 10, '2026-01-23 00:46:06');

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

CREATE TABLE `bookmarks` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `chapter` varchar(100) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `books`
--

CREATE TABLE `books` (
  `id` int(10) UNSIGNED NOT NULL,
  `title` varchar(200) NOT NULL,
  `author` varchar(150) NOT NULL,
  `duration_seconds` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `audio_path` varchar(255) NOT NULL,
  `cover_image_path` varchar(255) DEFAULT NULL,
  `price` decimal(8,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `primary_category_id` int(10) UNSIGNED DEFAULT NULL,
  `posted_by_user_id` int(11) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `is_encrypted` tinyint(1) DEFAULT 0,
  `pdf_path` varchar(255) DEFAULT NULL,
  `premium` int(11) DEFAULT 0,
  `content_key` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `books`
--

INSERT INTO `books` (`id`, `title`, `author`, `duration_seconds`, `audio_path`, `cover_image_path`, `price`, `created_at`, `primary_category_id`, `posted_by_user_id`, `description`, `is_encrypted`, `pdf_path`, `premium`, `content_key`) VALUES
(17, 'harry potter', 'jk rowing', 2789, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769530800_1215907.jpg', 0.00, '2026-01-27 16:20:02', 97, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/book.pdf', 1, NULL),
(18, 'jsn', 'js', 2587, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769531731_1215907.jpg', 0.00, '2026-01-27 16:35:33', 96, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/book.pdf', 1, NULL),
(19, 'n', 'bn', 2789, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769531854_3579218.jpg', 0.00, '2026-01-27 16:37:36', 97, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/book.pdf', 1, NULL),
(20, 'bb', 'nnnn', 2789, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/01_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769533296_5360049f46d6df684f6459a50a9924ea.jpg', 0.00, '2026-01-27 17:01:38', 97, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/book.pdf', 1, NULL),
(21, 'jsj', 'nj', 2789, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769546507_19851_32.jpg', 0.00, '2026-01-27 20:41:49', 96, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/book.pdf', 0, NULL),
(22, 'jsjsjsjkskskskskskjskskskkskskskskksjsjsj. bsjsjsj', 'nnnsn', 2505, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769605685_jsjsjsjkskskskskskjskskskkskskskskksjsjsj._bsjsjsj/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769605685_25243_29.jpg', 0.00, '2026-01-28 13:08:07', 97, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769605685_jsjsjsjkskskskskskjskskskkskskskskksjsjsj._bsjsjsj/book.pdf', 0, NULL),
(23, 'nn', 'j', 2789, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769606203_4036002.jpg', 0.00, '2026-01-28 13:16:45', 96, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/book.pdf', 0, NULL),
(24, 'jj', 'jnn', 1405, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606261_jj/01_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769606261_2612185.jpg', 0.00, '2026-01-28 13:17:43', 101, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606261_jj/book.pdf', 0, NULL),
(25, 'hjj', 'jjjj', 2789, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/01_Eminem_-_Lose_Yourself.mp3', 'https://velorus.ba/devaudioserver2/static/BookCovers/1769606321_11623_28.jpg', 0.00, '2026-01-28 13:18:44', 102, 39, '', 0, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/book.pdf', 0, NULL),
(26, 'jj', 'j', 2789, 'r2://AudioBooks/1769689808_jj/01_Eminem_-_Lose_Yourself.mp3', 'r2://BookCovers/1769689808_f3de22eb8d6fbe484641959e9a620717.jpg', 0.00, '2026-01-29 12:30:12', 96, 39, '', 0, 'r2://AudioBooks/1769689808_jj/book.pdf', 0, NULL),
(27, 'jjjjkkkkll', 'jn', 2505, 'r2://AudioBooks/1769690477_jjjjkkkkll/01_Eminem_-_Lose_Yourself.mp3', 'r2://BookCovers/1769690477_2612185.jpg', 0.00, '2026-01-29 12:41:21', 99, 39, '', 0, 'r2://AudioBooks/1769690477_jjjjkkkkll/book.pdf', 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `book_categories`
--

CREATE TABLE `book_categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `book_ratings`
--

CREATE TABLE `book_ratings` (
  `id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `stars` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `book_ratings`
--

INSERT INTO `book_ratings` (`id`, `book_id`, `user_id`, `stars`, `created_at`, `updated_at`) VALUES
(44, 20, 40, 4, '2026-01-27 17:46:51', '2026-01-27 17:46:51'),
(45, 25, 40, 4, '2026-01-28 13:20:26', '2026-01-28 13:20:26'),
(46, 23, 40, 4, '2026-01-28 13:20:31', '2026-01-28 13:20:31');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `slug` varchar(100) DEFAULT NULL,
  `parent_id` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `slug`, `parent_id`, `created_at`) VALUES
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

--
-- Table structure for table `encrypted_files`
--

CREATE TABLE `encrypted_files` (
  `id` int(11) NOT NULL,
  `original_path` varchar(500) NOT NULL,
  `encrypted_path` varchar(500) NOT NULL,
  `content_key_encrypted` blob NOT NULL,
  `content_iv` binary(16) NOT NULL,
  `auth_tag` binary(16) NOT NULL,
  `file_size` bigint(20) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `favorites`
--

CREATE TABLE `favorites` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `favorites`
--

INSERT INTO `favorites` (`user_id`, `book_id`) VALUES
(41, 24),
(40, 25),
(41, 25);

-- --------------------------------------------------------

--
-- Table structure for table `pending_users`
--

CREATE TABLE `pending_users` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `verification_code` varchar(10) NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `playback_history`
--

CREATE TABLE `playback_history` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `playlist_item_id` int(11) DEFAULT NULL,
  `start_time` timestamp NULL DEFAULT current_timestamp(),
  `end_time` timestamp NULL DEFAULT current_timestamp(),
  `played_seconds` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `playback_history`
--

INSERT INTO `playback_history` (`id`, `user_id`, `book_id`, `playlist_item_id`, `start_time`, `end_time`, `played_seconds`) VALUES
(525, 40, 19, 103, '2026-01-27 16:38:09', '2026-01-27 16:38:09', 1),
(526, 40, 19, 104, '2026-01-27 16:38:23', '2026-01-27 16:55:39', 1046),
(596, 40, 19, 105, '2026-01-27 16:55:54', '2026-01-27 16:57:39', 108),
(604, 40, 20, 109, '2026-01-27 17:02:35', '2026-01-27 17:11:08', 526),
(606, 40, 20, 111, '2026-01-27 17:02:54', '2026-01-27 17:02:55', 196),
(608, 40, 20, 112, '2026-01-27 17:03:09', '2026-01-27 17:03:40', 77),
(614, 40, 20, 113, '2026-01-27 17:03:54', '2026-01-27 17:05:40', 115),
(633, 41, 19, 103, '2026-01-27 18:06:01', '2026-01-27 18:06:01', 327),
(634, 40, 25, 135, '2026-01-28 13:24:45', '2026-01-28 14:45:38', 322),
(646, 40, 25, 136, '2026-01-28 13:27:15', '2026-01-28 14:47:06', 76),
(652, 40, 25, 137, '2026-01-28 13:28:45', '2026-01-28 17:39:33', 9),
(665, 40, 25, 138, '2026-01-28 13:32:00', '2026-01-28 13:35:30', 216),
(680, 40, 25, 139, '2026-01-28 13:35:45', '2026-01-28 13:43:44', 415),
(724, 40, 18, 98, '2026-01-28 17:40:31', '2026-01-28 17:40:33', 7),
(726, 40, 23, 125, '2026-01-28 18:32:06', '2026-01-28 18:32:08', 12),
(728, 40, 23, 126, '2026-01-28 18:32:23', '2026-01-28 18:34:23', 130),
(737, 40, 21, 115, '2026-01-28 18:34:38', '2026-01-28 18:34:38', 1),
(738, 41, 25, 135, '2026-01-28 19:01:42', '2026-01-28 19:01:49', 311),
(741, 41, 25, 136, '2026-01-28 19:01:58', '2026-01-29 15:01:36', 10),
(743, 41, 25, 137, '2026-01-28 19:03:20', '2026-01-29 08:06:07', 41),
(746, 41, 25, 138, '2026-01-28 19:03:57', '2026-01-28 19:03:57', 222),
(747, 41, 25, 139, '2026-01-28 19:04:07', '2026-01-28 19:04:27', 21),
(763, 41, 24, 131, '2026-01-29 08:06:22', '2026-01-29 08:06:22', 2),
(764, 41, 27, 147, '2026-01-29 12:55:28', '2026-01-29 13:00:44', 327),
(807, 41, 27, 148, '2026-01-29 13:00:59', '2026-01-29 13:14:25', 131),
(813, 41, 27, 150, '2026-01-29 13:02:59', '2026-01-29 13:03:59', 431),
(823, 41, 27, 149, '2026-01-29 13:04:59', '2026-01-29 13:06:29', 94),
(841, 42, 27, 147, '2026-01-29 19:09:26', '2026-01-29 19:11:57', 326),
(858, 42, 27, 148, '2026-01-29 19:12:06', '2026-01-29 19:24:06', 1054),
(954, 42, 27, 149, '2026-01-29 19:24:11', '2026-01-29 19:27:51', 221),
(984, 42, 27, 150, '2026-01-29 19:28:06', '2026-01-29 19:39:11', 675);

-- --------------------------------------------------------

--
-- Table structure for table `playlist_items`
--

CREATE TABLE `playlist_items` (
  `id` int(11) NOT NULL,
  `book_id` int(11) NOT NULL,
  `file_path` varchar(512) NOT NULL,
  `title` varchar(255) NOT NULL,
  `duration_seconds` int(11) DEFAULT 0,
  `track_order` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `content_key_encrypted` blob DEFAULT NULL COMMENT 'Encrypted content key (AES-256-GCM)',
  `content_iv` binary(12) DEFAULT NULL COMMENT 'IV used for content encryption (GCM uses 12 bytes)',
  `auth_tag` binary(16) DEFAULT NULL COMMENT 'GCM authentication tag',
  `encryption_version` int(11) DEFAULT NULL COMMENT 'Encryption scheme version'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `playlist_items`
--

INSERT INTO `playlist_items` (`id`, `book_id`, `file_path`, `title`, `duration_seconds`, `track_order`, `created_at`, `content_key_encrypted`, `content_iv`, `auth_tag`, `encryption_version`) VALUES
(92, 17, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-27 16:20:02', NULL, NULL, NULL, NULL),
(93, 17, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-27 16:20:02', NULL, NULL, NULL, NULL),
(94, 17, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-27 16:20:02', NULL, NULL, NULL, NULL),
(95, 17, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-27 16:20:02', NULL, NULL, NULL, NULL),
(96, 17, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/05_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 4, '2026-01-27 16:20:02', NULL, NULL, NULL, NULL),
(97, 17, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769530800_harry_potter/06_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 5, '2026-01-27 16:20:02', NULL, NULL, NULL, NULL),
(98, 18, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-27 16:35:33', NULL, NULL, NULL, NULL),
(99, 18, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-27 16:35:33', NULL, NULL, NULL, NULL),
(100, 18, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-27 16:35:33', NULL, NULL, NULL, NULL),
(101, 18, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-27 16:35:33', NULL, NULL, NULL, NULL),
(102, 18, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531731_jsn/05_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 4, '2026-01-27 16:35:33', NULL, NULL, NULL, NULL),
(103, 19, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-27 16:37:36', NULL, NULL, NULL, NULL),
(104, 19, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-27 16:37:36', NULL, NULL, NULL, NULL),
(105, 19, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-27 16:37:36', NULL, NULL, NULL, NULL),
(106, 19, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-27 16:37:36', NULL, NULL, NULL, NULL),
(107, 19, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/05_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 4, '2026-01-27 16:37:36', NULL, NULL, NULL, NULL),
(108, 19, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769531854_n/06_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 5, '2026-01-27 16:37:36', NULL, NULL, NULL, NULL),
(109, 20, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/01_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 0, '2026-01-27 17:01:38', NULL, NULL, NULL, NULL),
(110, 20, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/02_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 1, '2026-01-27 17:01:38', NULL, NULL, NULL, NULL),
(111, 20, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/03_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 2, '2026-01-27 17:01:38', NULL, NULL, NULL, NULL),
(112, 20, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/04_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 3, '2026-01-27 17:01:38', NULL, NULL, NULL, NULL),
(113, 20, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/05_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 4, '2026-01-27 17:01:38', NULL, NULL, NULL, NULL),
(114, 20, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769533296_bb/06_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 5, '2026-01-27 17:01:38', NULL, NULL, NULL, NULL),
(115, 21, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-27 20:41:49', NULL, NULL, NULL, NULL),
(116, 21, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-27 20:41:49', NULL, NULL, NULL, NULL),
(117, 21, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-27 20:41:49', NULL, NULL, NULL, NULL),
(118, 21, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-27 20:41:49', NULL, NULL, NULL, NULL),
(119, 21, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/05_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 4, '2026-01-27 20:41:49', NULL, NULL, NULL, NULL),
(120, 21, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769546507_jsj/06_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 5, '2026-01-27 20:41:49', NULL, NULL, NULL, NULL),
(121, 22, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769605685_jsjsjsjkskskskskskjskskskkskskskskksjsjsj._bsjsjsj/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-28 13:08:07', NULL, NULL, NULL, NULL),
(122, 22, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769605685_jsjsjsjkskskskskskjskskskkskskskskksjsjsj._bsjsjsj/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-28 13:08:07', NULL, NULL, NULL, NULL),
(123, 22, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769605685_jsjsjsjkskskskskskjskskskkskskskskksjsjsj._bsjsjsj/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-28 13:08:07', NULL, NULL, NULL, NULL),
(124, 22, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769605685_jsjsjsjkskskskskskjskskskkskskskskksjsjsj._bsjsjsj/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-28 13:08:07', NULL, NULL, NULL, NULL),
(125, 23, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-28 13:16:45', NULL, NULL, NULL, NULL),
(126, 23, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-28 13:16:45', NULL, NULL, NULL, NULL),
(127, 23, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-28 13:16:45', NULL, NULL, NULL, NULL),
(128, 23, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-28 13:16:45', NULL, NULL, NULL, NULL),
(129, 23, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/05_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 4, '2026-01-28 13:16:45', NULL, NULL, NULL, NULL),
(130, 23, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606203_nn/06_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 5, '2026-01-28 13:16:45', NULL, NULL, NULL, NULL),
(131, 24, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606261_jj/01_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 0, '2026-01-28 13:17:43', NULL, NULL, NULL, NULL),
(132, 24, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606261_jj/02_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 1, '2026-01-28 13:17:43', NULL, NULL, NULL, NULL),
(133, 24, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606261_jj/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-28 13:17:43', NULL, NULL, NULL, NULL),
(134, 24, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606261_jj/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-28 13:17:43', NULL, NULL, NULL, NULL),
(135, 25, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-28 13:18:44', NULL, NULL, NULL, NULL),
(136, 25, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/02_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 1, '2026-01-28 13:18:44', NULL, NULL, NULL, NULL),
(137, 25, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/03_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 2, '2026-01-28 13:18:44', NULL, NULL, NULL, NULL),
(138, 25, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/04_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 3, '2026-01-28 13:18:44', NULL, NULL, NULL, NULL),
(139, 25, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/05_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 4, '2026-01-28 13:18:44', NULL, NULL, NULL, NULL),
(140, 25, 'https://velorus.ba/devaudioserver2/static/AudioBooks/1769606321_hjj/06_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 5, '2026-01-28 13:18:44', NULL, NULL, NULL, NULL),
(141, 26, 'r2://AudioBooks/1769689808_jj/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-29 12:30:12', NULL, NULL, NULL, NULL),
(142, 26, 'r2://AudioBooks/1769689808_jj/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-29 12:30:12', NULL, NULL, NULL, NULL),
(143, 26, 'r2://AudioBooks/1769689808_jj/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-29 12:30:12', NULL, NULL, NULL, NULL),
(144, 26, 'r2://AudioBooks/1769689808_jj/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-29 12:30:12', NULL, NULL, NULL, NULL),
(145, 26, 'r2://AudioBooks/1769689808_jj/05_1.1-Cloud_Mental_Model_and_Philosophy1.mp3', '1.1-Cloud Mental Model and Philosophy(1).mp3', 82, 4, '2026-01-29 12:30:12', NULL, NULL, NULL, NULL),
(146, 26, 'r2://AudioBooks/1769689808_jj/06_1.1.1-What_the_cloud_actually_is1.mp3', '1.1.1-What the cloud actually is(1).mp3', 202, 5, '2026-01-29 12:30:12', NULL, NULL, NULL, NULL),
(147, 27, 'r2://AudioBooks/1769690477_jjjjkkkkll/01_Eminem_-_Lose_Yourself.mp3', 'Eminem - Lose Yourself.mp3', 327, 0, '2026-01-29 12:41:21', NULL, NULL, NULL, NULL),
(148, 27, 'r2://AudioBooks/1769690477_jjjjkkkkll/02_anneoftheisland_01_montgomery_64kb.mp3', 'anneoftheisland_01_montgomery_64kb.mp3', 1057, 1, '2026-01-29 12:41:21', NULL, NULL, NULL, NULL),
(149, 27, 'r2://AudioBooks/1769690477_jjjjkkkkll/03_Oj_Planino_Visoka.mp3', 'Oj Planino Visoka.mp3', 225, 2, '2026-01-29 12:41:21', NULL, NULL, NULL, NULL),
(150, 27, 'r2://AudioBooks/1769690477_jjjjkkkkll/04_ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer_1.mp3', 'ElevenLabs_1_2_6-Caching_The_Invisible_Performance_Layer (1).mp3', 896, 3, '2026-01-29 12:41:21', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `quizzes`
--

CREATE TABLE `quizzes` (
  `id` int(11) NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `playlist_item_id` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `quizzes`
--

INSERT INTO `quizzes` (`id`, `book_id`, `playlist_item_id`, `created_at`) VALUES
(37, 21, 115, '2026-01-27 20:42:04'),
(38, 21, 120, '2026-01-27 20:42:14'),
(39, 21, NULL, '2026-01-27 20:42:22'),
(40, 25, 135, '2026-01-28 13:24:00'),
(41, 25, 140, '2026-01-28 13:24:12'),
(42, 25, NULL, '2026-01-28 13:24:20');

-- --------------------------------------------------------

--
-- Table structure for table `quiz_questions`
--

CREATE TABLE `quiz_questions` (
  `id` int(11) NOT NULL,
  `quiz_id` int(11) NOT NULL,
  `question_text` text NOT NULL,
  `option_a` varchar(255) NOT NULL,
  `option_b` varchar(255) NOT NULL,
  `option_c` varchar(255) NOT NULL,
  `option_d` varchar(255) NOT NULL,
  `correct_answer` char(1) NOT NULL,
  `order_index` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `quiz_questions`
--

INSERT INTO `quiz_questions` (`id`, `quiz_id`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_answer`, `order_index`) VALUES
(39, 37, 'nn', 'n', 'n', 'n', 'n', 'A', 0),
(40, 38, 'bb', 'n', 'n', 'n', 'j', 'A', 0),
(41, 39, 'hj', 'j', 'n', 'n', 'n', 'A', 0),
(42, 40, 'bb', 'jnn', 'nn', 'nj', 'nn', 'A', 0),
(43, 41, 'nj', 'nn', 'n', 'n', 'j', 'A', 0),
(44, 42, 'hh', 'n', 'n', 'nn', 'n', 'A', 0);

-- --------------------------------------------------------

--
-- Table structure for table `server_config`
--

CREATE TABLE `server_config` (
  `id` int(11) NOT NULL,
  `config_key` varchar(255) NOT NULL,
  `config_value` text NOT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `server_config`
--

INSERT INTO `server_config` (`id`, `config_key`, `config_value`, `created_at`, `updated_at`) VALUES
(1, 'master_secret', 'y6yj2Pp2PyFElOR3/s5Aq7MvGPKnIZJ58g2xPfaF3zM=', '2026-01-23 10:24:43', '2026-01-23 10:24:43');

-- --------------------------------------------------------

--
-- Table structure for table `subscriptions`
--

CREATE TABLE `subscriptions` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `plan_type` enum('test_minute','monthly','yearly','lifetime') NOT NULL DEFAULT 'monthly',
  `status` enum('active','expired','cancelled') NOT NULL DEFAULT 'active',
  `start_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `end_date` timestamp NULL DEFAULT NULL,
  `auto_renew` tinyint(1) DEFAULT 1,
  `payment_provider` varchar(50) DEFAULT NULL,
  `external_subscription_id` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subscriptions`
--

INSERT INTO `subscriptions` (`id`, `user_id`, `plan_type`, `status`, `start_date`, `end_date`, `auto_renew`, `payment_provider`, `external_subscription_id`, `created_at`, `updated_at`) VALUES
(30, 40, 'test_minute', 'active', '2026-01-28 17:35:52', '2026-01-28 17:36:52', 0, NULL, NULL, '2026-01-27 16:38:04', '2026-01-28 18:35:59'),
(31, 41, 'monthly', 'active', '2026-01-28 18:01:29', '2026-02-27 18:01:29', 0, NULL, NULL, '2026-01-27 17:47:20', '2026-01-29 08:03:54'),
(32, 42, 'test_minute', 'active', '2026-01-29 18:10:21', '2026-01-29 18:11:21', 1, NULL, NULL, '2026-01-29 19:09:14', '2026-01-29 19:10:21');

-- --------------------------------------------------------

--
-- Table structure for table `subscription_history`
--

CREATE TABLE `subscription_history` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `action` enum('subscribed','renewed','cancelled','expired','upgraded','downgraded') NOT NULL,
  `plan_type` enum('test_minute','monthly','yearly','lifetime') DEFAULT NULL,
  `action_date` timestamp NULL DEFAULT current_timestamp(),
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `subscription_history`
--

INSERT INTO `subscription_history` (`id`, `user_id`, `action`, `plan_type`, `action_date`, `notes`) VALUES
(456, 40, 'subscribed', 'test_minute', '2026-01-27 16:38:04', 'Test mode subscription - test_minute'),
(457, 40, 'renewed', 'test_minute', '2026-01-27 16:56:58', 'Auto-renewal via status check'),
(458, 40, 'renewed', 'test_minute', '2026-01-27 17:01:56', 'Auto-renewal via status check'),
(459, 40, 'renewed', 'test_minute', '2026-01-27 17:05:55', 'Auto-renewal via status check'),
(460, 40, 'renewed', 'test_minute', '2026-01-27 17:09:02', 'Auto-renewal via status check'),
(461, 40, 'renewed', 'test_minute', '2026-01-27 17:10:41', 'Auto-renewal via status check'),
(462, 40, 'renewed', 'test_minute', '2026-01-27 17:41:49', 'Auto-renewal via status check'),
(463, 40, 'renewed', 'test_minute', '2026-01-27 17:42:50', 'Auto-renewal via status check'),
(464, 40, 'renewed', 'test_minute', '2026-01-27 17:44:39', 'Auto-renewal via status check'),
(465, 40, 'renewed', 'test_minute', '2026-01-27 17:46:44', 'Auto-renewal via status check'),
(466, 41, 'subscribed', 'test_minute', '2026-01-27 17:47:20', 'Test mode subscription - test_minute'),
(467, 41, 'renewed', 'test_minute', '2026-01-27 17:49:58', 'Auto-renewal via status check'),
(468, 41, 'renewed', 'test_minute', '2026-01-27 18:05:50', 'Auto-renewal via status check'),
(469, 41, 'renewed', 'test_minute', '2026-01-27 18:07:06', 'Auto-renewal via status check'),
(470, 41, 'renewed', 'test_minute', '2026-01-27 18:28:54', 'Auto-renewal via status check'),
(471, 41, 'renewed', 'test_minute', '2026-01-27 18:38:43', 'Auto-renewal via status check'),
(472, 41, 'renewed', 'test_minute', '2026-01-27 18:40:17', 'Auto-renewal via status check'),
(473, 41, 'renewed', 'test_minute', '2026-01-27 18:45:47', 'Auto-renewal via status check'),
(474, 40, 'renewed', 'test_minute', '2026-01-27 20:40:44', 'Auto-renewal via status check'),
(475, 40, 'renewed', 'test_minute', '2026-01-27 20:42:55', 'Auto-renewal via status check'),
(476, 40, 'renewed', 'test_minute', '2026-01-28 13:19:05', 'Auto-renewal via status check'),
(477, 40, 'renewed', 'test_minute', '2026-01-28 13:20:19', 'Auto-renewal via status check'),
(478, 40, 'renewed', 'test_minute', '2026-01-28 13:21:32', 'Auto-renewal via status check'),
(479, 40, 'renewed', 'test_minute', '2026-01-28 13:24:32', 'Auto-renewal via status check'),
(480, 40, 'renewed', 'test_minute', '2026-01-28 13:25:44', 'Auto-renewal via status check'),
(481, 40, 'renewed', 'test_minute', '2026-01-28 13:44:04', 'Auto-renewal via status check'),
(482, 40, 'renewed', 'test_minute', '2026-01-28 14:00:39', 'Auto-renewal via status check'),
(483, 40, 'cancelled', NULL, '2026-01-28 14:00:46', 'User cancelled subscription'),
(484, 40, 'renewed', 'test_minute', '2026-01-28 14:48:46', 'Test mode subscription - test_minute'),
(485, 40, 'renewed', 'test_minute', '2026-01-28 17:37:25', 'Auto-renewal via status check'),
(486, 40, 'renewed', 'test_minute', '2026-01-28 17:38:58', 'Auto-renewal via status check'),
(487, 40, 'renewed', 'test_minute', '2026-01-28 17:40:16', 'Auto-renewal via status check'),
(488, 40, 'renewed', 'test_minute', '2026-01-28 17:41:29', 'Auto-renewal via status check'),
(489, 40, 'renewed', 'test_minute', '2026-01-28 18:25:26', 'Auto-renewal via status check'),
(490, 40, 'renewed', 'test_minute', '2026-01-28 18:30:07', 'Auto-renewal via status check'),
(491, 40, 'renewed', 'test_minute', '2026-01-28 18:31:14', 'Auto-renewal via status check'),
(492, 40, 'renewed', 'test_minute', '2026-01-28 18:34:38', 'Auto-renewal via status check'),
(493, 40, 'renewed', 'test_minute', '2026-01-28 18:35:52', 'Auto-renewal via status check'),
(494, 40, 'cancelled', NULL, '2026-01-28 18:35:59', 'User cancelled subscription'),
(495, 41, 'renewed', 'test_minute', '2026-01-28 18:56:04', 'Auto-renewal via status check'),
(496, 41, 'renewed', 'test_minute', '2026-01-28 18:57:12', 'Auto-renewal via status check'),
(497, 41, 'renewed', 'test_minute', '2026-01-28 18:58:41', 'Auto-renewal via status check'),
(498, 41, 'cancelled', NULL, '2026-01-28 18:58:44', 'User cancelled subscription'),
(499, 41, 'renewed', 'monthly', '2026-01-28 19:01:29', 'Test mode subscription - monthly'),
(500, 41, 'cancelled', NULL, '2026-01-29 08:03:54', 'User cancelled subscription'),
(501, 42, 'subscribed', 'test_minute', '2026-01-29 19:09:14', 'Test mode subscription - test_minute'),
(502, 42, 'renewed', 'test_minute', '2026-01-29 19:10:21', 'Auto-renewal via status check');

-- --------------------------------------------------------

--
-- Table structure for table `token_blacklist`
--

CREATE TABLE `token_blacklist` (
  `id` int(11) NOT NULL,
  `token` varchar(500) NOT NULL,
  `blacklisted_at` timestamp NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `token_blacklist`
--

INSERT INTO `token_blacklist` (`id`, `token`, `blacklisted_at`, `expires_at`) VALUES
(484, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjRmNTM1ODkyLTE0YjMtNDk1NC1hN2FkLTk3N2QyYjQ5NGM2NiIsImV4cCI6MTc2OTUzNDMzOCwiaWF0IjoxNzY5NTMwNzM4LCJ0eXBlIjoiYWNjZXNzIn0.rlqiwUPQPeHtsEJset90wNoYUk4pwxwbl9Oly84dJrc', '2026-01-27 16:34:30', '2026-01-27 17:18:58'),
(485, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjRmNTM1ODkyLTE0YjMtNDk1NC1hN2FkLTk3N2QyYjQ5NGM2NiIsImV4cCI6MTc3MjEyMjczOCwiaWF0IjoxNzY5NTMwNzM4LCJ0eXBlIjoicmVmcmVzaCJ9.G46_wvu_y0pzvMafZoR7Lja34N1ASSn9uBsd4IpREJI', '2026-01-27 16:34:30', '2026-02-26 16:18:58'),
(486, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjgxMmZiOTVmLTI4MDQtNDE0ZS04OGViLWRjYjQ2ZGI0NzdkMCIsImV4cCI6MTc2OTUzNTI3NCwiaWF0IjoxNzY5NTMxNjc0LCJ0eXBlIjoiYWNjZXNzIn0.P0NO8Xhl_ZRhIKbwZWN7Hfom-pInVmShJ0IbrQhjF5s', '2026-01-27 16:37:50', '2026-01-27 17:34:34'),
(487, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjgxMmZiOTVmLTI4MDQtNDE0ZS04OGViLWRjYjQ2ZGI0NzdkMCIsImV4cCI6MTc3MjEyMzY3NCwiaWF0IjoxNzY5NTMxNjc0LCJ0eXBlIjoicmVmcmVzaCJ9.DSqNcNb_mSU_nR2SpcPpRYEXP3rBMGzZo5N6Duc--qg', '2026-01-27 16:37:50', '2026-02-26 16:34:34'),
(488, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjkwNTg2NTg5LTQzYjItNGNiZC1hYWVhLWI0M2E1Nzg4MTU4ZiIsImV4cCI6MTc2OTUzNTQ3NCwiaWF0IjoxNzY5NTMxODc0LCJ0eXBlIjoiYWNjZXNzIn0.5eSpY6FG4ndt570A_fW7h2ITK1MtFpbG_XTpAzAfWR4', '2026-01-27 16:57:39', '2026-01-27 17:37:54'),
(489, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjkwNTg2NTg5LTQzYjItNGNiZC1hYWVhLWI0M2E1Nzg4MTU4ZiIsImV4cCI6MTc3MjEyMzg3NCwiaWF0IjoxNzY5NTMxODc0LCJ0eXBlIjoicmVmcmVzaCJ9.hZx1AIGiXiyaPM0AG9MbX1By-zAr2FiNEwdE6SinLW0', '2026-01-27 16:57:39', '2026-02-26 16:37:54'),
(490, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjAwZGFmZDIzLTFlMDctNDgwOS04MzI5LTM5ODE0MDc3ZWUzYyIsImV4cCI6MTc2OTUzNjY2NywiaWF0IjoxNzY5NTMzMDY3LCJ0eXBlIjoiYWNjZXNzIn0.BGo8eIusbjr0MDWovcp4Lv49_4K5hwThWxbxchItMao', '2026-01-27 17:01:48', '2026-01-27 17:57:47'),
(491, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjAwZGFmZDIzLTFlMDctNDgwOS04MzI5LTM5ODE0MDc3ZWUzYyIsImV4cCI6MTc3MjEyNTA2NywiaWF0IjoxNzY5NTMzMDY3LCJ0eXBlIjoicmVmcmVzaCJ9.9tJlqrUmx6F7Xux4OPCHYnh4KjIj14XuKJwDJ62NQ9c', '2026-01-27 17:01:48', '2026-02-26 16:57:47'),
(492, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImQ1YzM5ZmZlLWQwOTktNDA2NC1hOWI0LTRkYjdhM2UzMTJlYiIsImV4cCI6MTc2OTUzNjkxNiwiaWF0IjoxNzY5NTMzMzE2LCJ0eXBlIjoiYWNjZXNzIn0.IIEskXccjsg7jNBPoy7mlrHxeW33ixPFKW6MDvJPYnA', '2026-01-27 17:06:02', '2026-01-27 18:01:56'),
(493, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImQ1YzM5ZmZlLWQwOTktNDA2NC1hOWI0LTRkYjdhM2UzMTJlYiIsImV4cCI6MTc3MjEyNTMxNiwiaWF0IjoxNzY5NTMzMzE2LCJ0eXBlIjoicmVmcmVzaCJ9.VHVTUUN8cfe7EprxiYS6Urd2ajcMmUw3T0tmDcl-KfY', '2026-01-27 17:06:02', '2026-02-26 17:01:56'),
(494, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6ImE3OWY2MTlkLTAwMWQtNGQzMS05NGI5LWM5OWQxZTIzNjY0NSIsImV4cCI6MTc2OTUzNzE2OSwiaWF0IjoxNzY5NTMzNTY5LCJ0eXBlIjoiYWNjZXNzIn0.y6aHLni7ObvPF_ONN3RMxIkswNigCWu0Ki5qX8eIg-4', '2026-01-27 17:07:29', '2026-01-27 18:06:09'),
(495, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6ImE3OWY2MTlkLTAwMWQtNGQzMS05NGI5LWM5OWQxZTIzNjY0NSIsImV4cCI6MTc3MjEyNTU2OSwiaWF0IjoxNzY5NTMzNTY5LCJ0eXBlIjoicmVmcmVzaCJ9.gVQL2lcBAzkW4xNPxyD3I5Rq0LaPfEgsdLQwLluntx0', '2026-01-27 17:07:29', '2026-02-26 17:06:09'),
(496, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImQzYmY3MzUwLTI0MzYtNDU2Mi04ZjM0LWZkYTlmNTExZDZjMSIsImV4cCI6MTc2OTUzNzM0MiwiaWF0IjoxNzY5NTMzNzQyLCJ0eXBlIjoiYWNjZXNzIn0.qmRXxnhgX6z_uL7Gis6VDBC6qz9DqSWGHAcWtGXxNF8', '2026-01-27 17:46:59', '2026-01-27 18:09:02'),
(497, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImQzYmY3MzUwLTI0MzYtNDU2Mi04ZjM0LWZkYTlmNTExZDZjMSIsImV4cCI6MTc3MjEyNTc0MiwiaWF0IjoxNzY5NTMzNzQyLCJ0eXBlIjoicmVmcmVzaCJ9.3htyrFB5fb6U_gkAJPdXHvrk7tBkPX6eQyhTJVMh3tY', '2026-01-27 17:46:59', '2026-02-26 17:09:02'),
(498, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImM0YTE3ZGZiLTMxYjAtNDAyMi05M2UxLTM0OTRjNTU1NTQyZiIsImV4cCI6MTc2OTU1MDA0MywiaWF0IjoxNzY5NTQ2NDQzLCJ0eXBlIjoiYWNjZXNzIn0.sct1-WuNS30olPdGg4x7fDxtupnTrFToszc0RyL5d1Q', '2026-01-27 20:40:49', '2026-01-27 21:40:43'),
(499, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImM0YTE3ZGZiLTMxYjAtNDAyMi05M2UxLTM0OTRjNTU1NTQyZiIsImV4cCI6MTc3MjEzODQ0MywiaWF0IjoxNzY5NTQ2NDQzLCJ0eXBlIjoicmVmcmVzaCJ9.1x1RYHokJFsOzYIh7WHcI90fSYGo3SOO0-UtT7-ZL84', '2026-01-27 20:40:49', '2026-02-26 20:40:43'),
(500, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6ImZmM2Q5MzBiLTgxYjYtNDMxOC05NTFmLTA5MDNjNjU4YWQ1YyIsImV4cCI6MTc2OTU1MDA1MywiaWF0IjoxNzY5NTQ2NDUzLCJ0eXBlIjoiYWNjZXNzIn0.3tH36AfuIa8pmZRkMVpljgPXg4doKmQ6kfm7_z9BOew', '2026-01-27 20:42:25', '2026-01-27 21:40:53'),
(501, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6ImZmM2Q5MzBiLTgxYjYtNDMxOC05NTFmLTA5MDNjNjU4YWQ1YyIsImV4cCI6MTc3MjEzODQ1MywiaWF0IjoxNzY5NTQ2NDUzLCJ0eXBlIjoicmVmcmVzaCJ9.U-BBM01RdU6CTSkLmsD8a72NZZ3EoZndbG2VT_5Grmc', '2026-01-27 20:42:25', '2026-02-26 20:40:53'),
(502, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjhhN2U2ZmM0LWE0MzItNDRmOS05OWNiLTg2MjBiYjc4ZDMyYiIsImV4cCI6MTc2OTYwOTIxMywiaWF0IjoxNzY5NjA1NjEzLCJ0eXBlIjoiYWNjZXNzIn0.td3S_HeI_QwUQCX4thSeADHLW9P1VAaeVlWK75tuqsQ', '2026-01-28 13:18:58', '2026-01-28 14:06:53'),
(503, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjhhN2U2ZmM0LWE0MzItNDRmOS05OWNiLTg2MjBiYjc4ZDMyYiIsImV4cCI6MTc3MjE5NzYxMywiaWF0IjoxNzY5NjA1NjEzLCJ0eXBlIjoicmVmcmVzaCJ9.hnYl42MLumgQv2BxZyrGIBEUSfIn7yF7k1ko1oAkS3c', '2026-01-28 13:18:58', '2026-02-27 13:06:53'),
(504, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjY1ZjI3MzNiLWYxMTItNDIzMS05ZDMwLTk0NTVkZTViNmU3MSIsImV4cCI6MTc3MjEzODU3MywiaWF0IjoxNzY5NTQ2NTczLCJ0eXBlIjoicmVmcmVzaCJ9.REp0WdZ2p-r4D65HVrNW9tYxTwzgpqxohLxRPLxdk2s', '2026-01-28 13:19:05', '2026-02-26 19:42:53'),
(505, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjEyOWI3NTk0LTg2Y2QtNDhkYy1hNzdmLTQ2M2FlNmIwMmJhYiIsImV4cCI6MTc2OTYwOTk0NSwiaWF0IjoxNzY5NjA2MzQ1LCJ0eXBlIjoiYWNjZXNzIn0.Cr3OdTDcbHNs2ca_46d6f38CW7VcXUg4JDMreCsYcqY', '2026-01-28 13:21:38', '2026-01-28 14:19:05'),
(506, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjEyOWI3NTk0LTg2Y2QtNDhkYy1hNzdmLTQ2M2FlNmIwMmJhYiIsImV4cCI6MTc3MjE5ODM0NSwiaWF0IjoxNzY5NjA2MzQ1LCJ0eXBlIjoicmVmcmVzaCJ9.sTuflMpxBp2KgQat5GAEdT6RWpDDDVdgcr1r1-TxwaE', '2026-01-28 13:21:39', '2026-02-27 13:19:05'),
(507, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6ImQwOWFkOTJhLWI5ZDMtNDFiMS05Y2QzLWQ2OGNhOGE4ZDRlNyIsImV4cCI6MTc2OTYxMDEwMywiaWF0IjoxNzY5NjA2NTAzLCJ0eXBlIjoiYWNjZXNzIn0.mcu4KQTrVyro8hoywOJaiOsOI0PaGWpMMzaeeuQG9P0', '2026-01-28 13:24:26', '2026-01-28 14:21:43'),
(508, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6ImQwOWFkOTJhLWI5ZDMtNDFiMS05Y2QzLWQ2OGNhOGE4ZDRlNyIsImV4cCI6MTc3MjE5ODUwMywiaWF0IjoxNzY5NjA2NTAzLCJ0eXBlIjoicmVmcmVzaCJ9.M9YJr3Yd0gEnZjIWlp4neFlGATReA8GTiKcA_aHtonQ', '2026-01-28 13:24:26', '2026-02-27 13:21:43'),
(509, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjE5MTJmNjExLTcwNTgtNGVlZC1iODc2LTdmYzNhMDU0YmQyNiIsImV4cCI6MTc2OTYxMDI3MSwiaWF0IjoxNzY5NjA2NjcxLCJ0eXBlIjoiYWNjZXNzIn0.yo5O0w50WSopwA9D30MQ67EnCLtJl_Xr5pMknCxi1yc', '2026-01-28 14:03:07', '2026-01-28 14:24:31'),
(510, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjE5MTJmNjExLTcwNTgtNGVlZC1iODc2LTdmYzNhMDU0YmQyNiIsImV4cCI6MTc3MjE5ODY3MSwiaWF0IjoxNzY5NjA2NjcxLCJ0eXBlIjoicmVmcmVzaCJ9.hDRPJF0DhKWqAO6NZC_ItWgkLsHSNEz4WQD_B6tw1js', '2026-01-28 14:03:07', '2026-02-27 13:24:31'),
(511, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjY2N2QwZjFmLWY5MGMtNDdlOC1hNDEzLWMyZDY5MGU2YzgyOSIsImV4cCI6MTc2OTYxMjU5MywiaWF0IjoxNzY5NjA4OTkzLCJ0eXBlIjoiYWNjZXNzIn0.3aRHUOBu0FHCcprM8BsAa8-jgkJ4ETYlGwa6XG8hJTI', '2026-01-28 14:05:05', '2026-01-28 15:03:13'),
(512, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjY2N2QwZjFmLWY5MGMtNDdlOC1hNDEzLWMyZDY5MGU2YzgyOSIsImV4cCI6MTc3MjIwMDk5MywiaWF0IjoxNzY5NjA4OTkzLCJ0eXBlIjoicmVmcmVzaCJ9.niiCINHkZgRNJTYlI3vsjlqCe1NvXfvLdU6W1Cv0t2M', '2026-01-28 14:05:05', '2026-02-27 14:03:13'),
(513, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjEyN2MyZWJiLWNmY2EtNGZkZC1hYWI4LWZiNDA3ZjJkMTcwMyIsImV4cCI6MTc3MjIwMTEwOCwiaWF0IjoxNzY5NjA5MTA4LCJ0eXBlIjoicmVmcmVzaCJ9.cNCPOi5_ColW42K5tH1qNYoKiVzCzQJ4GTJJHWTEc6k', '2026-01-28 14:39:25', '2026-02-27 13:05:08'),
(514, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjU1YmM3YzA2LTczMzAtNDlmMC05YWQ5LWYwNjFkZTVlYzczZCIsImV4cCI6MTc3MjIwMzE2NSwiaWF0IjoxNzY5NjExMTY1LCJ0eXBlIjoicmVmcmVzaCJ9.Mc9SETCu3CU-TwuMf74-p0aXwHFtH7DmcT0oKHq8nUc', '2026-01-28 17:37:25', '2026-02-27 13:39:25'),
(515, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjdkNzJkODBiLTVkMWMtNDJkMy05MDIyLWQzYjBhM2I2ODQ4ZSIsImV4cCI6MTc3MjIxMzg0NSwiaWF0IjoxNzY5NjIxODQ1LCJ0eXBlIjoicmVmcmVzaCJ9.Ta4W0JR-qdEbH7jlyFb9X3OtqJxIzaiSL3YQsI_k2T8', '2026-01-28 18:37:32', '2026-02-27 16:37:25'),
(516, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MSwic2Vzc2lvbl9pZCI6Ijg1Nzk4OTA2LWMwZTQtNGM1OC05MTNkLTJiMWExM2U1MjU5NyIsImV4cCI6MTc3MjEyODAyNSwiaWF0IjoxNzY5NTM2MDI1LCJ0eXBlIjoicmVmcmVzaCJ9.Nb33cbLF6Aivd4d8R-rqbZakEkk8W47fJ5veCUm73vE', '2026-01-28 18:56:02', '2026-02-26 16:47:05'),
(517, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MSwic2Vzc2lvbl9pZCI6IjBlNjM4MDk3LTQ2NmItNDlmMy1iZTE4LTUwZTliNTkzYzdkNCIsImV4cCI6MTc3MjIxODU2MiwiaWF0IjoxNzY5NjI2NTYyLCJ0eXBlIjoicmVmcmVzaCJ9.JfNHVA5_V1PHWF9ZHaWqmILgcEMGXk9UY008aA3QPpM', '2026-01-29 08:02:18', '2026-02-27 17:56:02'),
(518, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImQxODQ3ZmQ1LTdhNTktNGQ1Zi1hMjdhLTY5Njc3YTQ3MDg5NSIsImV4cCI6MTc3MjIxNzQ1MiwiaWF0IjoxNzY5NjI1NDUyLCJ0eXBlIjoicmVmcmVzaCJ9.0iDIJhstBCyleVZLV1pAwk5D0Af9pg7xE1GcLfPsU8g', '2026-01-29 08:22:33', '2026-02-27 17:37:32'),
(519, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjUyOTU3MTFiLTU3NzAtNGM5YS04NmNkLWNkZTBhMzAyZDk0MSIsImV4cCI6MTc2OTY5MzM0OSwiaWF0IjoxNzY5Njg5NzQ5LCJ0eXBlIjoiYWNjZXNzIn0.WXsbmyoKQz-SgOH7-JFuxKZ19_be7UFGR7elkz_NGHk', '2026-01-29 12:31:12', '2026-01-29 13:29:09'),
(520, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjUyOTU3MTFiLTU3NzAtNGM5YS04NmNkLWNkZTBhMzAyZDk0MSIsImV4cCI6MTc3MjI4MTc0OSwiaWF0IjoxNzY5Njg5NzQ5LCJ0eXBlIjoicmVmcmVzaCJ9.OuLACdtpzmMF0jhv3g6GcWYhU0haY9VX_tUN4xi9Vj8', '2026-01-29 12:31:12', '2026-02-28 12:29:09'),
(521, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImQzNGQ1OWM2LWE4NDAtNDNmNC05MmQwLTAzNGNkOGVlMjI5NCIsImV4cCI6MTc3MjI2Njk1MywiaWF0IjoxNzY5Njc0OTUzLCJ0eXBlIjoicmVmcmVzaCJ9.wzoDWHcUCtWPE6r_zMVY5euCNcQj34thKbmaQyCP8N4', '2026-01-29 12:31:17', '2026-02-28 07:22:33'),
(522, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjNhZmNmNjEzLTVhYTMtNDllOS04MzRjLWI0MTUxOGJiZjExMCIsImV4cCI6MTc2OTY5MzQ3NywiaWF0IjoxNzY5Njg5ODc3LCJ0eXBlIjoiYWNjZXNzIn0.SkGCIB8FCv0u8koSsJN397gOicU2n41YyWbBjtDiBuM', '2026-01-29 12:40:16', '2026-01-29 13:31:17'),
(523, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjNhZmNmNjEzLTVhYTMtNDllOS04MzRjLWI0MTUxOGJiZjExMCIsImV4cCI6MTc3MjI4MTg3NywiaWF0IjoxNzY5Njg5ODc3LCJ0eXBlIjoicmVmcmVzaCJ9.At03V_0L3blQ_pKUHaCMkKCJeuY2ZzbnnMf_IvzvqSw', '2026-01-29 12:40:16', '2026-02-28 12:31:17'),
(524, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjliYzlmYjI5LTRiN2MtNGUzNy04ZTE2LWExOWQ1NmYwY2VmNCIsImV4cCI6MTc2OTY5NDAyNSwiaWF0IjoxNzY5NjkwNDI1LCJ0eXBlIjoiYWNjZXNzIn0._7lxoJ560XYAOk5Gmo8ui3SD2efepR5pH60wIaLshx0', '2026-01-29 12:43:10', '2026-01-29 13:40:25'),
(525, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjliYzlmYjI5LTRiN2MtNGUzNy04ZTE2LWExOWQ1NmYwY2VmNCIsImV4cCI6MTc3MjI4MjQyNSwiaWF0IjoxNzY5NjkwNDI1LCJ0eXBlIjoicmVmcmVzaCJ9.CrA5-mSj4265Iz8haH2foGLsh_rPDOWhRO4cGT6gMw4', '2026-01-29 12:43:10', '2026-02-28 12:40:25'),
(526, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjFhMzkwNTkyLTkyZjgtNDQ2MC04MTIwLTRmZTU5MWNmNjBlNiIsImV4cCI6MTc2OTY5NDE5NiwiaWF0IjoxNzY5NjkwNTk2LCJ0eXBlIjoiYWNjZXNzIn0.upEu3ifyuzJZ6ULMqeVeatS9R0TNuNcrBGusO0KanwM', '2026-01-29 12:54:57', '2026-01-29 13:43:16'),
(527, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6IjFhMzkwNTkyLTkyZjgtNDQ2MC04MTIwLTRmZTU5MWNmNjBlNiIsImV4cCI6MTc3MjI4MjU5NiwiaWF0IjoxNzY5NjkwNTk2LCJ0eXBlIjoicmVmcmVzaCJ9.X00E9ML5gY9al88psFZrKWGlTJIjV1lPsbju-DyIrDg', '2026-01-29 12:54:57', '2026-02-28 12:43:16'),
(528, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImFiZDY3YzFiLWQ4OTktNGE3MC1iNTI2LTFlNjNiNzBiYmU3NyIsImV4cCI6MTc2OTY5NDkwMiwiaWF0IjoxNzY5NjkxMzAyLCJ0eXBlIjoiYWNjZXNzIn0.2lQhAC9MhWbktHBjWoM2AdHiv9tHjb-0nr63QTF9DsA', '2026-01-29 12:55:05', '2026-01-29 13:55:02'),
(529, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MCwic2Vzc2lvbl9pZCI6ImFiZDY3YzFiLWQ4OTktNGE3MC1iNTI2LTFlNjNiNzBiYmU3NyIsImV4cCI6MTc3MjI4MzMwMiwiaWF0IjoxNzY5NjkxMzAyLCJ0eXBlIjoicmVmcmVzaCJ9.tXZYZsluYwpKIns6qNBwyPMiyNXD69vkEGVk28i0858', '2026-01-29 12:55:05', '2026-02-28 12:55:02'),
(530, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MSwic2Vzc2lvbl9pZCI6IjhkYmE2NzM1LTY3YjUtNDZlNS04MDcwLTkwM2Q4Mzc2YTQ3MiIsImV4cCI6MTc3MjI2NTczOCwiaWF0IjoxNzY5NjczNzM4LCJ0eXBlIjoicmVmcmVzaCJ9.1zZMH4XQMAS6hEbEiqbtm2qR5NPri7cVBEEldw-GSiI', '2026-01-29 12:55:10', '2026-02-28 07:02:18'),
(531, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MSwic2Vzc2lvbl9pZCI6IjY0ZTU5MWJjLTkwMjktNGFiZC1iZGUzLTk2YTQ4NTJlODc0MCIsImV4cCI6MTc3MjI4MzMxMCwiaWF0IjoxNzY5NjkxMzEwLCJ0eXBlIjoicmVmcmVzaCJ9.25NQO3AzqFJGFptwPMW0WhIMSd6nrwxlm8Zj50fMkHE', '2026-01-29 15:00:02', '2026-02-28 11:55:10');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `aes_key` varchar(64) DEFAULT NULL,
  `status` enum('active','banned','inactive') NOT NULL DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `last_login` timestamp NULL DEFAULT NULL,
  `profile_picture_url` varchar(255) DEFAULT NULL,
  `verification_code` varchar(6) DEFAULT NULL,
  `is_verified` tinyint(1) DEFAULT 0,
  `encryption_key` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `aes_key`, `status`, `created_at`, `last_login`, `profile_picture_url`, `verification_code`, `is_verified`, `encryption_key`) VALUES
(39, 'Bojan', 'bojanpejic97@gmail.com', 'scrypt:32768:8:1$vsVPCZ687N2L9xbQ$9f4be84c51e653ad606f4eb77090e3a48ad33212c4fdeec13fb3201b268544cfe6db40c7500d7768fca5b4bd6858e4cf42abafc9b87c754e2c91ed2280088a47', 'GuJliJKJHrzuDvySfrg9f9Mi00DFH+MOjAhp/DIcJHk=', 'active', '2026-01-27 16:18:58', NULL, NULL, NULL, 0, NULL),
(40, 'Bojan Pejic', 'bojanpejic997@gmail.com', 'scrypt:32768:8:1$AMQi54cbVNwQapdj$4cf3eba69df557de24bedb9fe109c7b184cc62fc4c73edf01a0373ca92d9294f2708b4c39c80e73a66acba97686550c82a39951ed31bab3c9108920a7ff9eee0', 'XoiYMMfZm6gqOEltCZNuAQ6GNOCll5Kyu7y43kYyx1g=', 'active', '2026-01-27 16:37:54', NULL, 'profilePictures/bojanpejic997gmail.com.jpg', NULL, 0, NULL),
(41, 'Nemanja Pejić', 'nemanjapeji@gmail.com', 'scrypt:32768:8:1$mzD7VomCq3NThgJr$a3c656268d80b55856225dcdbacf0757feae38053f3ebc4075d572d429681807fa7d549b37b597f1eb204d8e32395b2dc60feb5dbf7763fc8a753a962cbc3ea3', 'xy9oufp+G0EG9i7ctKeKq49EmMh9XR3dHs3z5MTk3+M=', 'active', '2026-01-27 17:47:05', NULL, NULL, NULL, 0, NULL),
(42, 'trimaster', 'itsaulgoodman95@gmail.com', 'scrypt:32768:8:1$uRp2WJKeU9zp1VVc$7e7d7f824ea68847afb7531e53d0da8c61a7f7a028e9e056f1c45473b3f4e77ea0ed523945abd637d7c097fbd6d15eea3741f52cfaf928978556d6e0ba35025a', 'QYfwTX7ozT515vm19qaZfSSk6hOMunSkbMvuxPrg+Zw=', 'active', '2026-01-29 19:07:22', NULL, NULL, NULL, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_badges`
--

CREATE TABLE `user_badges` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `badge_id` int(11) NOT NULL,
  `earned_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_badges`
--

INSERT INTO `user_badges` (`user_id`, `badge_id`, `earned_at`) VALUES
(41, 54, '2026-01-27 18:06:26');

-- --------------------------------------------------------

--
-- Table structure for table `user_books`
--

CREATE TABLE `user_books` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `last_played_position_seconds` int(10) UNSIGNED DEFAULT 0,
  `playback_speed` decimal(3,1) DEFAULT 1.0,
  `is_downloaded` tinyint(1) DEFAULT 0,
  `download_path` varchar(255) DEFAULT NULL,
  `purchased_at` timestamp NULL DEFAULT current_timestamp(),
  `last_accessed_at` timestamp NULL DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `current_playlist_item_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_books`
--

INSERT INTO `user_books` (`id`, `user_id`, `book_id`, `last_played_position_seconds`, `playback_speed`, `is_downloaded`, `download_path`, `purchased_at`, `last_accessed_at`, `is_read`, `started_at`, `completed_at`, `current_playlist_item_id`) VALUES
(41, 39, 17, 0, 1.0, 0, NULL, '2026-01-27 16:20:02', NULL, 0, NULL, NULL, NULL),
(42, 39, 18, 0, 1.0, 0, NULL, '2026-01-27 16:35:33', NULL, 0, NULL, NULL, NULL),
(43, 39, 19, 0, 1.0, 0, NULL, '2026-01-27 16:37:36', NULL, 0, NULL, NULL, NULL),
(44, 40, 19, 108, 1.0, 0, NULL, '2026-01-27 16:38:09', '2026-01-27 16:57:39', 0, NULL, NULL, 105),
(45, 39, 20, 0, 1.0, 0, NULL, '2026-01-27 17:01:38', NULL, 0, NULL, NULL, NULL),
(46, 40, 20, 2, 1.0, 0, NULL, '2026-01-27 17:02:35', '2026-01-28 17:39:38', 0, NULL, NULL, 111),
(47, 41, 19, 114, 1.0, 0, NULL, '2026-01-27 18:06:01', '2026-01-27 18:07:31', 1, NULL, NULL, 108),
(48, 39, 21, 0, 1.0, 0, NULL, '2026-01-27 20:41:49', NULL, 0, NULL, NULL, NULL),
(49, 39, 22, 0, 1.0, 0, NULL, '2026-01-28 13:08:07', NULL, 0, NULL, NULL, NULL),
(50, 39, 23, 0, 1.0, 0, NULL, '2026-01-28 13:16:45', NULL, 0, NULL, NULL, NULL),
(51, 39, 24, 0, 1.0, 0, NULL, '2026-01-28 13:17:43', NULL, 0, NULL, NULL, NULL),
(52, 39, 25, 0, 1.0, 0, NULL, '2026-01-28 13:18:44', NULL, 0, NULL, NULL, NULL),
(53, 40, 25, 9, 1.0, 0, NULL, '2026-01-28 13:24:45', '2026-01-28 17:39:33', 0, NULL, NULL, 137),
(54, 40, 18, 7, 1.0, 0, NULL, '2026-01-28 17:40:31', '2026-01-28 17:40:33', 0, NULL, NULL, 98),
(55, 40, 23, 130, 1.0, 0, NULL, '2026-01-28 18:32:06', '2026-01-28 18:34:23', 0, NULL, NULL, 126),
(56, 40, 21, 50, 1.0, 0, NULL, '2026-01-28 18:34:38', '2026-01-28 18:38:08', 0, NULL, NULL, 115),
(57, 41, 25, 10, 1.0, 0, NULL, '2026-01-28 19:01:42', '2026-01-29 15:01:36', 0, NULL, NULL, 136),
(58, 41, 24, 2, 1.0, 0, NULL, '2026-01-29 08:06:22', '2026-01-29 08:06:22', 0, NULL, NULL, 131),
(59, 39, 26, 0, 1.0, 0, NULL, '2026-01-29 12:30:12', NULL, 0, NULL, NULL, NULL),
(60, 39, 27, 0, 1.0, 0, NULL, '2026-01-29 12:41:21', NULL, 0, NULL, NULL, NULL),
(61, 41, 27, 131, 1.0, 0, NULL, '2026-01-29 12:55:28', '2026-01-29 13:14:25', 0, NULL, NULL, 148),
(62, 42, 27, 675, 1.0, 0, NULL, '2026-01-29 19:09:26', '2026-01-29 19:39:11', 0, NULL, NULL, 150);

-- --------------------------------------------------------

--
-- Table structure for table `user_completed_tracks`
--

CREATE TABLE `user_completed_tracks` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `track_id` int(11) NOT NULL,
  `completed_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_completed_tracks`
--

INSERT INTO `user_completed_tracks` (`id`, `user_id`, `track_id`, `completed_at`) VALUES
(351, 40, 103, '2026-01-27 16:38:12'),
(353, 40, 111, '2026-01-27 17:03:01'),
(355, 40, 112, '2026-01-27 17:03:45'),
(357, 41, 103, '2026-01-27 18:06:02'),
(359, 41, 104, '2026-01-27 18:06:07'),
(361, 41, 105, '2026-01-27 18:06:14'),
(363, 41, 106, '2026-01-27 18:06:16'),
(365, 41, 107, '2026-01-27 18:06:17'),
(367, 41, 108, '2026-01-27 18:06:26'),
(378, 40, 135, '2026-01-28 14:45:44'),
(380, 40, 131, '2026-01-28 14:47:30'),
(382, 40, 132, '2026-01-28 14:47:34'),
(384, 40, 133, '2026-01-28 14:47:47'),
(386, 40, 134, '2026-01-28 14:48:08'),
(390, 40, 115, '2026-01-28 18:34:45'),
(392, 41, 135, '2026-01-28 19:01:54'),
(395, 41, 138, '2026-01-28 19:04:06'),
(400, 40, 147, '2026-01-29 12:45:29'),
(401, 41, 147, '2026-01-29 13:00:44'),
(405, 42, 147, '2026-01-29 19:11:58'),
(406, 42, 148, '2026-01-29 19:24:09'),
(407, 42, 149, '2026-01-29 19:27:55');

-- --------------------------------------------------------

--
-- Table structure for table `user_content_keys`
--

CREATE TABLE `user_content_keys` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `device_id` varchar(255) NOT NULL,
  `media_id` int(10) UNSIGNED NOT NULL,
  `wrapped_key` blob NOT NULL COMMENT 'ContentKey wrapped with UserKey',
  `wrap_iv` binary(12) NOT NULL COMMENT 'IV used for key wrapping',
  `wrap_auth_tag` binary(16) NOT NULL COMMENT 'GCM auth tag for wrapping',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_downloads`
--

CREATE TABLE `user_downloads` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `downloaded_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_quiz_results`
--

CREATE TABLE `user_quiz_results` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `quiz_id` int(11) NOT NULL,
  `score_percentage` decimal(5,2) DEFAULT 0.00,
  `is_passed` tinyint(1) DEFAULT 0,
  `completed_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_quiz_results`
--

INSERT INTO `user_quiz_results` (`id`, `user_id`, `quiz_id`, `score_percentage`, `is_passed`, `completed_at`) VALUES
(58, 40, 40, 100.00, 1, '2026-01-28 14:45:47'),
(59, 40, 37, 100.00, 1, '2026-01-28 18:34:47'),
(60, 41, 40, 100.00, 1, '2026-01-29 08:03:27'),
(61, 41, 40, 100.00, 1, '2026-01-29 15:01:31');

-- --------------------------------------------------------

--
-- Table structure for table `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `session_id` varchar(255) DEFAULT NULL,
  `refresh_token` varchar(500) NOT NULL,
  `access_token` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NOT NULL,
  `device_info` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_sessions`
--

INSERT INTO `user_sessions` (`id`, `user_id`, `session_id`, `refresh_token`, `access_token`, `created_at`, `expires_at`, `device_info`) VALUES
(286, 41, '21cf858f-b7f8-4127-acbf-c94776782a43', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MSwic2Vzc2lvbl9pZCI6IjIxY2Y4NThmLWI3ZjgtNDEyNy1hY2JmLWM5NDc3Njc4MmE0MyIsImV4cCI6MTc3MjI5MDgwMiwiaWF0IjoxNzY5Njk4ODAyLCJ0eXBlIjoicmVmcmVzaCJ9._Sma8RqrY32HJLcI3EuN6Gl5fAm99WY2uD3G0HkUx1A', NULL, '2026-01-29 15:00:02', '2026-02-28 14:00:02', NULL),
(309, 42, 'f67f8804-a874-4b35-80c8-b08ff64e584c', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0Miwic2Vzc2lvbl9pZCI6ImY2N2Y4ODA0LWE4NzQtNGIzNS04MGM4LWIwOGZmNjRlNTg0YyIsImV4cCI6MTc3MjMwNTY0MiwiaWF0IjoxNzY5NzEzNjQyLCJ0eXBlIjoicmVmcmVzaCJ9.sjAoaOloRlCpqKrAXl3iM4L9xFiG8xpyyYegqlP9YX8', NULL, '2026-01-29 19:07:22', '2026-02-28 18:07:22', NULL),
(310, 39, '315b99a8-0a3e-4ec3-abf4-64261dd499a0', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjozOSwic2Vzc2lvbl9pZCI6IjMxNWI5OWE4LTBhM2UtNGVjMy1hYmY0LTY0MjYxZGQ0OTlhMCIsImV4cCI6MTc3MjMwOTI3NywiaWF0IjoxNzY5NzE3Mjc3LCJ0eXBlIjoicmVmcmVzaCJ9.dl2Gfw-5G95qip8lJFg706-qfZLviJOsjANuIQCaJwQ', NULL, '2026-01-29 20:07:57', '2026-02-28 19:07:57', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_track_progress`
--

CREATE TABLE `user_track_progress` (
  `id` int(11) NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `book_id` int(10) UNSIGNED NOT NULL,
  `playlist_item_id` int(11) NOT NULL,
  `position_seconds` int(11) DEFAULT 0,
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_track_progress`
--

INSERT INTO `user_track_progress` (`id`, `user_id`, `book_id`, `playlist_item_id`, `position_seconds`, `updated_at`) VALUES
(1188, 40, 19, 103, 1, '2026-01-27 16:38:09'),
(1189, 40, 19, 104, 1046, '2026-01-27 16:55:39'),
(1259, 40, 19, 105, 108, '2026-01-27 16:57:39'),
(1267, 40, 20, 109, 526, '2026-01-27 17:11:08'),
(1269, 40, 20, 111, 2, '2026-01-28 17:39:38'),
(1271, 40, 20, 112, 77, '2026-01-27 17:03:40'),
(1277, 40, 20, 113, 115, '2026-01-27 17:05:40'),
(1296, 41, 19, 103, 327, '2026-01-27 18:06:01'),
(1297, 41, 19, 108, 114, '2026-01-27 18:07:31'),
(1314, 40, 25, 135, 322, '2026-01-28 14:45:38'),
(1326, 40, 25, 136, 76, '2026-01-28 14:47:06'),
(1332, 40, 25, 137, 9, '2026-01-28 17:39:33'),
(1345, 40, 25, 138, 216, '2026-01-28 13:35:30'),
(1360, 40, 25, 139, 415, '2026-01-28 13:43:44'),
(1405, 40, 18, 98, 7, '2026-01-28 17:40:33'),
(1407, 40, 23, 125, 12, '2026-01-28 18:32:08'),
(1409, 40, 23, 126, 130, '2026-01-28 18:34:23'),
(1418, 40, 21, 115, 50, '2026-01-28 18:38:08'),
(1424, 41, 25, 135, 324, '2026-01-29 15:01:21'),
(1427, 41, 25, 136, 10, '2026-01-29 15:01:36'),
(1429, 41, 25, 137, 41, '2026-01-29 08:06:07'),
(1432, 41, 25, 138, 222, '2026-01-28 19:03:57'),
(1433, 41, 25, 139, 21, '2026-01-28 19:04:27'),
(1454, 41, 24, 131, 2, '2026-01-29 08:06:22'),
(1455, 41, 27, 147, 327, '2026-01-29 13:00:44'),
(1498, 41, 27, 148, 131, '2026-01-29 13:14:25'),
(1504, 41, 27, 150, 431, '2026-01-29 13:03:59'),
(1514, 41, 27, 149, 94, '2026-01-29 13:06:29'),
(1535, 42, 27, 147, 326, '2026-01-29 19:11:57'),
(1552, 42, 27, 148, 1054, '2026-01-29 19:24:06'),
(1648, 42, 27, 149, 221, '2026-01-29 19:27:51'),
(1678, 42, 27, 150, 675, '2026-01-29 19:39:11');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `badges`
--
ALTER TABLE `badges`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_bookmark` (`user_id`,`book_id`,`chapter`),
  ADD KEY `book_id` (`book_id`);

--
-- Indexes for table `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_books_primary_category` (`primary_category_id`);

--
-- Indexes for table `book_categories`
--
ALTER TABLE `book_categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_book_category` (`book_id`,`category_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `book_ratings`
--
ALTER TABLE `book_ratings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_book` (`user_id`,`book_id`),
  ADD KEY `idx_book_id` (`book_id`),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `slug` (`slug`),
  ADD KEY `parent_id` (`parent_id`);

--
-- Indexes for table `encrypted_files`
--
ALTER TABLE `encrypted_files`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `encrypted_path` (`encrypted_path`),
  ADD KEY `idx_original_path` (`original_path`);

--
-- Indexes for table `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`user_id`,`book_id`),
  ADD KEY `book_id` (`book_id`);

--
-- Indexes for table `pending_users`
--
ALTER TABLE `pending_users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `playback_history`
--
ALTER TABLE `playback_history`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_book_track` (`user_id`,`book_id`,`playlist_item_id`),
  ADD KEY `book_id` (`book_id`),
  ADD KEY `idx_playlist_item_id` (`playlist_item_id`);

--
-- Indexes for table `playlist_items`
--
ALTER TABLE `playlist_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_book_id` (`book_id`);

--
-- Indexes for table `quizzes`
--
ALTER TABLE `quizzes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_book_track_quiz` (`book_id`,`playlist_item_id`),
  ADD KEY `fk_quizzes_playlist_item` (`playlist_item_id`);

--
-- Indexes for table `quiz_questions`
--
ALTER TABLE `quiz_questions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `quiz_id` (`quiz_id`);

--
-- Indexes for table `server_config`
--
ALTER TABLE `server_config`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `config_key` (`config_key`);

--
-- Indexes for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`),
  ADD KEY `idx_user_status` (`user_id`,`status`),
  ADD KEY `idx_end_date` (`end_date`);

--
-- Indexes for table `subscription_history`
--
ALTER TABLE `subscription_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_action` (`user_id`,`action_date`);

--
-- Indexes for table `token_blacklist`
--
ALTER TABLE `token_blacklist`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_expires` (`expires_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `user_badges`
--
ALTER TABLE `user_badges`
  ADD PRIMARY KEY (`user_id`,`badge_id`),
  ADD KEY `badge_id` (`badge_id`);

--
-- Indexes for table `user_books`
--
ALTER TABLE `user_books`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_book` (`user_id`,`book_id`),
  ADD KEY `book_id` (`book_id`);

--
-- Indexes for table `user_completed_tracks`
--
ALTER TABLE `user_completed_tracks`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_completion` (`user_id`,`track_id`),
  ADD KEY `track_id` (`track_id`);

--
-- Indexes for table `user_content_keys`
--
ALTER TABLE `user_content_keys`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_device_media` (`user_id`,`device_id`,`media_id`),
  ADD KEY `idx_user_device` (`user_id`,`device_id`),
  ADD KEY `idx_media` (`media_id`);

--
-- Indexes for table `user_downloads`
--
ALTER TABLE `user_downloads`
  ADD PRIMARY KEY (`user_id`,`book_id`),
  ADD KEY `book_id` (`book_id`);

--
-- Indexes for table `user_quiz_results`
--
ALTER TABLE `user_quiz_results`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `quiz_id` (`quiz_id`);

--
-- Indexes for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `refresh_token` (`refresh_token`),
  ADD UNIQUE KEY `unique_user` (`user_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_refresh_token` (`refresh_token`),
  ADD KEY `idx_expires` (`expires_at`),
  ADD KEY `idx_access_token` (`access_token`);

--
-- Indexes for table `user_track_progress`
--
ALTER TABLE `user_track_progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_track` (`user_id`,`playlist_item_id`),
  ADD KEY `book_id` (`book_id`),
  ADD KEY `playlist_item_id` (`playlist_item_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `badges`
--
ALTER TABLE `badges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `bookmarks`
--
ALTER TABLE `bookmarks`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `books`
--
ALTER TABLE `books`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=28;

--
-- AUTO_INCREMENT for table `book_categories`
--
ALTER TABLE `book_categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `book_ratings`
--
ALTER TABLE `book_ratings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=133;

--
-- AUTO_INCREMENT for table `encrypted_files`
--
ALTER TABLE `encrypted_files`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pending_users`
--
ALTER TABLE `pending_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `playback_history`
--
ALTER TABLE `playback_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1074;

--
-- AUTO_INCREMENT for table `playlist_items`
--
ALTER TABLE `playlist_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=151;

--
-- AUTO_INCREMENT for table `quizzes`
--
ALTER TABLE `quizzes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `quiz_questions`
--
ALTER TABLE `quiz_questions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `server_config`
--
ALTER TABLE `server_config`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `subscriptions`
--
ALTER TABLE `subscriptions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `subscription_history`
--
ALTER TABLE `subscription_history`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=503;

--
-- AUTO_INCREMENT for table `token_blacklist`
--
ALTER TABLE `token_blacklist`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=532;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=43;

--
-- AUTO_INCREMENT for table `user_books`
--
ALTER TABLE `user_books`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=63;

--
-- AUTO_INCREMENT for table `user_completed_tracks`
--
ALTER TABLE `user_completed_tracks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=408;

--
-- AUTO_INCREMENT for table `user_content_keys`
--
ALTER TABLE `user_content_keys`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_quiz_results`
--
ALTER TABLE `user_quiz_results`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=311;

--
-- AUTO_INCREMENT for table `user_track_progress`
--
ALTER TABLE `user_track_progress`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1768;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD CONSTRAINT `bookmarks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookmarks_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `books`
--
ALTER TABLE `books`
  ADD CONSTRAINT `fk_books_primary_category` FOREIGN KEY (`primary_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `book_categories`
--
ALTER TABLE `book_categories`
  ADD CONSTRAINT `book_categories_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `book_categories_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `playback_history`
--
ALTER TABLE `playback_history`
  ADD CONSTRAINT `fk_playback_playlist_item` FOREIGN KEY (`playlist_item_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `playback_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `playback_history_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `quizzes`
--
ALTER TABLE `quizzes`
  ADD CONSTRAINT `fk_quizzes_playlist_item` FOREIGN KEY (`playlist_item_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `quizzes_ibfk_1` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `quiz_questions`
--
ALTER TABLE `quiz_questions`
  ADD CONSTRAINT `quiz_questions_ibfk_1` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `subscriptions`
--
ALTER TABLE `subscriptions`
  ADD CONSTRAINT `subscriptions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `subscription_history`
--
ALTER TABLE `subscription_history`
  ADD CONSTRAINT `subscription_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_badges`
--
ALTER TABLE `user_badges`
  ADD CONSTRAINT `user_badges_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_badges_ibfk_2` FOREIGN KEY (`badge_id`) REFERENCES `badges` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_books`
--
ALTER TABLE `user_books`
  ADD CONSTRAINT `user_books_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_books_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_completed_tracks`
--
ALTER TABLE `user_completed_tracks`
  ADD CONSTRAINT `user_completed_tracks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_completed_tracks_ibfk_2` FOREIGN KEY (`track_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_downloads`
--
ALTER TABLE `user_downloads`
  ADD CONSTRAINT `user_downloads_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_downloads_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_quiz_results`
--
ALTER TABLE `user_quiz_results`
  ADD CONSTRAINT `user_quiz_results_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_quiz_results_ibfk_2` FOREIGN KEY (`quiz_id`) REFERENCES `quizzes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD CONSTRAINT `user_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_track_progress`
--
ALTER TABLE `user_track_progress`
  ADD CONSTRAINT `user_track_progress_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_track_progress_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_track_progress_ibfk_3` FOREIGN KEY (`playlist_item_id`) REFERENCES `playlist_items` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
