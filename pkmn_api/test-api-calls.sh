# Try login
curl -X POST https://127.0.0.1:8081/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111", "password" : "1234"}'

# create user wiht id
curl -X POST https://127.0.0.1:8081/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "name": "Leif Katt", "password": "1234"}'

# now login
curl -X POST https://127.0.0.1:8081/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111", "password" : "1234"}'


# set from previous before continue
export TOKEN="W1RPS0VOLS1GZWNUakthTHBnbS0tMTExMTEtLTIwMjUtMDMtMDYgMDc6Mzk6MTAuNzMwNDk3IFVUQy0tY1hOXQ=="

# create other user too
curl -X POST https://127.0.0.1:8081/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stur", "password": "stur-pass"}'

curl -X POST https://127.0.0.1:8081/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "33333", "name": "Lisa Lis", "password": "lis-pass"}'


# Set token for user 2 and 3
export TOKEN2="W1RPS0VOLS1Xc3VrTk9scERXWS0tMjIyMjItLTIwMjUtMDMtMDQgMDc6MTM6NDYuODYxNzgwIFVUQy0taUdsXQ=="
export TOKEN3="W1RPS0VOLS1FdkRQanp0ZVNTYS0tMzMzMzMtLTIwMjUtMDMtMDQgMDc6MzI6MTAuODA3MTc1IFVUQy0tZFFMXQ=="

curl -X POST https://127.0.0.1:8081/logout \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN"


# change user name using Authorization header
curl -X POST https://127.0.0.1:8081/set_user_name \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"name": "Sture Stör"}'

# find some pokemon using header for token
curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"catch_code": "ac3cf629-e151-45a6-a328-5af466cb471d"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"pokemon_id": "6"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"pokemon_id": "92"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"pokemon_id": "111"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"pokemon_id": "121"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"pokemon_id": "31"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"pokemon_id": "32"}'

# view pokemon found by user using header
curl -X POST https://127.0.0.1:8081/view_found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"n": 10}'

# user's pokedex
curl -X GET https://127.0.0.1:8081/my_pokedex \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN"

# Get Statistics
curl -X GET https://127.0.0.1:8081/statistics_highscore 

curl -X GET https://127.0.0.1:8081/statistics_latest_pokemon_found

curl -X GET https://127.0.0.1:8081/get_pokemon/1

