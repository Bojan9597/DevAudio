-- 1. Create the background_music table
CREATE TABLE IF NOT EXISTS background_music (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Add the background_music_id column to the books table
-- We use a DO block to safely add the column only if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='books' AND column_name='background_music_id') THEN
        ALTER TABLE books ADD COLUMN background_music_id INT DEFAULT NULL;
    END IF;
END $$;
