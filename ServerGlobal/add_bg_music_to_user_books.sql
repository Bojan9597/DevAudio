-- Add background_music_id to user_books table to store user preference per book
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='user_books' AND column_name='background_music_id') THEN
        ALTER TABLE user_books ADD COLUMN background_music_id INT DEFAULT NULL;
    END IF;
END $$;
