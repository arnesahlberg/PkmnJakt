
# Try login
curl -X POST http://127.0.0.1:8080/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111"}'

# create user wiht id
curl -X POST http://127.0.0.1:8080/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "name": "Leif Katt"}'

# now login
curl -X POST http://127.0.0.1:8080/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111"}'

# create other user too
curl -X POST http://127.0.0.1:8080/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stur"}'

# chage user name
curl -X POST http://127.0.0.1:8080/set_user_name \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stör"}'

# find some pokemon
curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "pokemon_id": "1"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "pokemon_id": "6"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "pokemon_id": "92"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "pokemon_id": "111"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "pokemon_id": "121"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "pokemon_id": "31"}'

curl -X POST http://127.0.0.1:8080/found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "pokemon_id": "32"}'


# view pokemon found by user
curl -X POST http://127.0.0.1:8080/view_found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "n": 10}'


# Get Statistics
curl -X GET http://127.0.0.1:8080/statistics_highscore \
    -H "Content-Type: application/json" 
    

curl -X GET http://127.0.0.1:8080/statistics_latest_pokemon_found \
    -H "Content-Type: application/json"