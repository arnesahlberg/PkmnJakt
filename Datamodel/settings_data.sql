-- Initial settings data for the Pokemon game

-- Insert game start and end times (update these as needed)
INSERT OR REPLACE INTO Settings (setting_id, setting_value) VALUES ('game_start_time', '2026-04-25 10:00:00');
INSERT OR REPLACE INTO Settings (setting_id, setting_value) VALUES ('game_end_time', '2026-09-01 00:00:00');

-- Feature toggles (INSERT OR IGNORE preserves any admin overrides on redeploy)
INSERT OR IGNORE INTO Settings (setting_id, setting_value) VALUES ('datamatrix_login_enabled', 'true');