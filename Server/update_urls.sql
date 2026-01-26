-- Update all URLs from 192.168.100.120:5000 to 10.107.89.89:5000

-- Disable safe update mode temporarily
SET SQL_SAFE_UPDATES = 0;

-- Update cover_image_path in books table
UPDATE books
SET cover_image_path = REPLACE(cover_image_path, 'http://192.168.100.120:5000', 'http://10.107.89.89:5000')
WHERE cover_image_path LIKE '%192.168.100.120:5000%';

-- Update audio_path in books table
UPDATE books
SET audio_path = REPLACE(audio_path, 'http://192.168.100.120:5000', 'http://10.107.89.89:5000')
WHERE audio_path LIKE '%192.168.100.120:5000%';

-- Update pdf_path in books table (if any exist)
UPDATE books
SET pdf_path = REPLACE(pdf_path, 'http://192.168.100.120:5000', 'http://10.107.89.89:5000')
WHERE pdf_path LIKE '%192.168.100.120:5000%';

-- Update file_path in playlist_items table
UPDATE playlist_items
SET file_path = REPLACE(file_path, 'http://192.168.100.120:5000', 'http://10.107.89.89:5000')
WHERE file_path LIKE '%192.168.100.120:5000%';

-- Re-enable safe update mode
SET SQL_SAFE_UPDATES = 1;
