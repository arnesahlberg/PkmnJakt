# Pokemon API Logging Documentation

## Overview
The Pokemon API includes comprehensive logging for debugging and monitoring purposes.

## Usage

### Running with Logging
```bash
# Default log file (./pkmn_api.log)
cargo run

# Custom log file location
cargo run -- --log-file /path/to/custom.log

# With environment variables
DATABASE_PATH=./pokemon.db cargo run -- --log-file ./logs/pkmn_api.log
```

### Log Levels
Control log verbosity using the `RUST_LOG` environment variable:
```bash
# Default (info level)
RUST_LOG=info cargo run

# Debug level (more verbose)
RUST_LOG=debug cargo run

# Error level only
RUST_LOG=error cargo run

# Specific module logging
RUST_LOG=pkmn_api=debug,actix_web=info cargo run
```

## What Gets Logged

### Request/Response Logging
All HTTP requests are logged with:
- Client IP address
- Request method and path
- Response status code
- Response time
- User agent
- Referer

Example:
```
127.0.0.1 "POST /create_user HTTP/1.1" 200 186 "-" "Mozilla/5.0..." 0.002345
```

### Application Events
- **User Creation**: Attempts, failures (with reasons), and successes
- **Login**: Attempts, failures, and successes
- **Pokemon Catches**: Attempts, validation failures, and successes
- **Errors**: Database connection failures, validation errors

### Security
The following sensitive data is NEVER logged:
- Passwords
- Authentication tokens
- Token contents

## Log Format
```
[YYYY-MM-DD HH:MM:SS LEVEL filename:line] Log message
```

Example:
```
[2025-06-27 15:23:45 INFO api.rs:110] User creation attempt - ID: ash123, Name: Ash Ketchum, Name length: 12
[2025-06-27 15:23:45 INFO api.rs:181] User created successfully - ID: ash123, Name: Ash Ketchum
```

## Common Log Messages

### User Creation
- `User creation attempt - ID: {}, Name: {}, Name length: {}`
- `User creation failed - user already exists: {}`
- `User creation failed - name too short: {} (length: {})`
- `User creation failed - name too long: {} (length: {})`
- `User creation failed - password too short for user: {}`
- `User created successfully - ID: {}, Name: {}`

### Login
- `Login attempt for user: {}`
- `Login failed - user not found: {}`
- `Login failed - invalid password for user: {}`
- `Login successful for user: {} ({})`

### Pokemon Catching
- `Pokemon catch attempt with catch code`
- `Pokemon catch failed - invalid token for user: {}`
- `Pokemon catch failed - user does not exist: {}`
- `Pokemon catch failed - invalid catch code for user: {}`
- `Pokemon already caught - user: {}, pokemon: {} ({})`
- `Pokemon caught successfully - user: {}, pokemon: {} ({})`

## Troubleshooting

### Log File Not Created
Ensure the directory exists and the process has write permissions:
```bash
mkdir -p logs
chmod 755 logs
cargo run -- --log-file ./logs/pkmn_api.log
```

### No Logs Appearing
Check the `RUST_LOG` environment variable:
```bash
export RUST_LOG=info
```

### Log File Growing Too Large
Consider implementing log rotation (not included in current implementation).
Temporary solution:
```bash
# Archive old logs
mv pkmn_api.log pkmn_api.log.$(date +%Y%m%d)
# Restart the server
```