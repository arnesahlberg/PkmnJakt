-- Initial settings data for the Pokemon game
-- Game runs from July 7, 2025 at 12:00 CET to July 15, 2025 at 18:00 CET

-- Insert game start and end times
INSERT OR REPLACE INTO Settings (setting_id, setting_value) VALUES ('game_start_time', '2025-07-07 12:00:00');
INSERT OR REPLACE INTO Settings (setting_id, setting_value) VALUES ('game_end_time', '2025-07-15 18:00:00');