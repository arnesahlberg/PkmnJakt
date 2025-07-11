# Statistics and Game Status Endpoints

## Game Status Endpoints (No Authentication Required)

### 1. Check if Game is Over
**GET** `/is_game_over`

Returns whether the game has ended based on the current time and the `game_end_time` setting.

**Response:**
```json
{
  "is_game_over": false,
  "current_time": "2025-01-10T15:30:00Z",
  "game_end_time": "2025-07-15T16:00:00Z"
}
```

### 2. Check if Game has Started
**GET** `/has_game_started`

Returns whether the game has started based on the current time and the `game_start_time` setting.

**Response:**
```json
{
  "has_game_started": true,
  "current_time": "2025-01-10T15:30:00Z",
  "game_start_time": "2025-07-07T10:00:00Z"
}
```

### 3. Get Server Time
**GET** `/server_time`

Returns the current server time in both UTC and CET timezones.

**Response:**
```json
{
  "server_time_utc": "2025-01-10T15:30:00Z",
  "server_time_cet": "2025-01-10 16:30:00 CET"
}
```

## Game Summary Statistics Endpoint (No Authentication Required)

### Get Game Summary Statistics
**GET** `/statistics/game_summary`

Returns comprehensive game statistics. Optionally accepts time window parameters.

**Query Parameters:**
- `datetime0` (optional): Start datetime in format "YYYY-MM-DD HH:MM:SS" (CET)
- `datetime1` (optional): End datetime in format "YYYY-MM-DD HH:MM:SS" (CET)

**Example:**
```
GET /statistics/game_summary?datetime0=2025-07-07 12:00:00&datetime1=2025-07-15 18:00:00
```

**Response:**
```json
{
  "total_users_registered": 150,
  "users_with_10_plus_catches": 75,
  "users_with_100_plus_catches": 12,
  "catches_per_hour": [
    {"hour": 7, "catches": 45},
    {"hour": 8, "catches": 120},
    // ... (excludes hours 22:30-06:30)
  ],
  "first_catch": {
    "user_name": "player1",
    "pokemon_name": "Pikachu",
    "pokemon_number": 25,
    "caught_at": "2025-07-07T10:15:00Z"
  },
  "last_catch": {
    "user_name": "player2",
    "pokemon_name": "Mewtwo",
    "pokemon_number": 150,
    "caught_at": "2025-07-15T15:45:00Z"
  },
  "top_10_players": [
    {
      "id": "user123",
      "name": "PlayerName",
      "score": 145,
      "latest_found": "2025-07-15T15:30:00Z"
    }
    // ... up to 10 players
  ],
  "most_caught_pokemon": [
    {
      "pokemon_name": "Pidgey",
      "pokemon_number": 16,
      "times_caught": 89
    }
    // ... up to 10 pokemon
  ],
  "least_caught_pokemon": [
    {
      "pokemon_name": "Mewtwo",
      "pokemon_number": 150,
      "times_caught": 1
    }
    // ... up to 10 pokemon
  ],
  "time_window_start": "2025-07-07T10:00:00Z",
  "time_window_end": "2025-07-15T16:00:00Z"
}
```

## Database Settings

The game timing is controlled by entries in the Settings table:
- `game_start_time`: When the game begins (format: "YYYY-MM-DD HH:MM:SS" in CET)
- `game_end_time`: When the game ends (format: "YYYY-MM-DD HH:MM:SS" in CET)

To initialize these settings, run:
```sql
INSERT OR REPLACE INTO Settings (setting_id, setting_value) VALUES ('game_start_time', '2025-07-07 12:00:00');
INSERT OR REPLACE INTO Settings (setting_id, setting_value) VALUES ('game_end_time', '2025-07-15 18:00:00');
```