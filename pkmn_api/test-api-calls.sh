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
export TOKEN="W1RPS0VOLS1Qald1d2FIRWZXVy0tMTExMTEtLTIwMjUtMDMtMDYgMTE6NTA6NDguODY3NDM1IFVUQy0tQ055XQ=="

# create other user too
curl -X POST https://127.0.0.1:8081/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stur", "password": "stur-pass"}'

curl -X POST https://127.0.0.1:8081/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "33333", "name": "Lisa Lis", "password": "lis-pass"}'


# Set token for user 2 and 3
export TOKEN2="W1RPS0VOLS1TcXp4YlVHUXF1QS0tMjIyMjItLTIwMjUtMDMtMDYgMTE6NTE6MDIuMDgyNzEzIFVUQy0tb01ZXQ=="
export TOKEN3="W1RPS0VOLS1IcWxrRnhUb2hhby0tMzMzMzMtLTIwMjUtMDMtMDYgMTE6NTE6MTAuMDY2MzcyIFVUQy0tdWZNXQ=="

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
    -d '{"catch_code": "331444e7-7a2b-48e3-abe5-74e486b82fb3"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"catch_code": "f3bb7f69-3b66-4cf6-8342-85e17951b502"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"catch_code": "2ddf72ec-32a4-40e3-b6c4-e4d03e4339a2"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN2" \
    -d '{"catch_code": "44cda3fd-62e5-4d68-a41a-7ae472d8aa5b"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"catch_code": "7a6af775-748a-44ab-9812-dfe934d5fab5"}'

curl -X POST https://127.0.0.1:8081/found_pokemon \
    -H "Content-Type: application/json" \
    -H "Authorization: $TOKEN" \
    -d '{"catch_code": "d9f5fe6e-22bd-4240-918c-9994a062df82"}'

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

