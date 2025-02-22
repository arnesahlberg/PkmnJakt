# Try login
curl -X POST http://127.0.0.1:8080/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111", "password" : "1234"}'

# create user wiht id
curl -X POST http://127.0.0.1:8080/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "name": "Leif Katt", "password": "1234"}'

# now login
curl -X POST http://127.0.0.1:8080/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111", "password" : "1234"}'

# set from previous before continue
export TOKEN="W1RPS0VOLS10Y1hIRlNrYVFQUi0tMTExMTEtLTIwMjUtMDMtMDEgMTQ6MDQ6MDUuNzQ1ODQyIFVUQy0tcFlFXQ=="

# create other user too
curl -X POST http://127.0.0.1:8080/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stur", "password": "stur-pass"}'

# Set token for user 2
export TOKEN2="W1RPS0VOLS12dFlYYllQcEpiUy0tMjIyMjItLTIwMjUtMDMtMDEgMTQ6MDc6MjMuMjQxMTc4IFVUQy0tbWFhXQ=="

# change user name using Authorization header
curl -X POST http://127.0.0.1:8080/set_user_name \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"id": "22222", "name": "Sture Stör"}'

# find some pokemon using header for token
curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"user_id": "11111", "pokemon_id": "1"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"user_id": "22222", "pokemon_id": "6"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"user_id": "11111", "pokemon_id": "92"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"user_id": "11111", "pokemon_id": "111"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"user_id": "22222", "pokemon_id": "121"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"user_id": "11111", "pokemon_id": "31"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"user_id": "11111", "pokemon_id": "32"}'

# view pokemon found by user using header
curl -X POST http://127.0.0.1:8080/view_found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"user_id": "11111", "n": 10}'

# Get Statistics
curl -X GET http://127.0.0.1:8080/statistics_highscore 

curl -X GET http://127.0.0.1:8080/statistics_latest_pokemon_found