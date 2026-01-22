-- Migration script to convert absolute URLs to relative paths in the database
-- This makes the app resilient to base URL changes

-- Update audio_path to use relative paths (192.168.100.15)
UPDATE books
SET audio_path = REPLACE(audio_path, 'http://192.168.100.15:5000', '')
WHERE audio_path LIKE 'http://192.168.100.15:5000%';

-- Update cover_image_path to use relative paths (192.168.100.15)
UPDATE books
SET cover_image_path = REPLACE(cover_image_path, 'http://192.168.100.15:5000', '')
WHERE cover_image_path LIKE 'http://192.168.100.15:5000%';

-- Update audio_path to use relative paths (10.247.143.89 - current IP)
UPDATE books
SET audio_path = REPLACE(audio_path, 'http://10.247.143.89:5000', '')
WHERE audio_path LIKE 'http://10.247.143.89:5000%';

-- Update cover_image_path to use relative paths (10.247.143.89 - current IP)
UPDATE books
SET cover_image_path = REPLACE(cover_image_path, 'http://10.247.143.89:5000', '')
WHERE cover_image_path LIKE 'http://10.247.143.89:5000%';

-- Update audio_path to use relative paths (localhost)
UPDATE books
SET audio_path = REPLACE(audio_path, 'http://localhost:5000', '')
WHERE audio_path LIKE 'http://localhost:5000%';

-- Update cover_image_path to use relative paths (localhost)
UPDATE books
SET cover_image_path = REPLACE(cover_image_path, 'http://localhost:5000', '')
WHERE cover_image_path LIKE 'http://localhost:5000%';

-- Verify the changes
SELECT id, title, audio_path, cover_image_path
FROM books
LIMIT 10;

-- Note: After running this migration, all paths will be relative (e.g., /static/AudioBooks/...)
-- The Flutter app's url_helper.dart will automatically prepend the base URL when needed
