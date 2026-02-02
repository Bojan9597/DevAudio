-- Grant permission to use the sequence (fix for 'permission denied for sequence background_music_id_seq')
GRANT USAGE, SELECT ON SEQUENCE background_music_id_seq TO "velorusb_echoHistoryAdmin";

-- Grant all permissions on the table just in case
GRANT ALL PRIVILEGES ON TABLE background_music TO "velorusb_echoHistoryAdmin";

-- Ensure permissions on books table (often not needed if same owner, but good practice if issues arise)
GRANT ALL PRIVILEGES ON TABLE books TO "velorusb_echoHistoryAdmin";
