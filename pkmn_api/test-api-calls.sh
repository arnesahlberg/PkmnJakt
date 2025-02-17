curl -X POST http://127.0.0.1:8080/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111"}'

curl -X POST http://127.0.0.1:8080/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "name": "Leif Katt"}'

curl -X POST http://127.0.0.1:8080/login \
    -H "Content-Type: application/json" \
    -d '{"id" : "11111"}'

curl -X POST http://127.0.0.1:8080/create_user \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stur"}'

curl -X POST http://127.0.0.1:8080/set_user_name \
    -H "Content-Type: application/json" \
    -d '{"id": "22222", "name": "Sture Stör"}'

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

curl -X POST http://127.0.0.1:8080/view_found_pokemon \
    -H "Content-Type: application/json" \
    -d '{"id": "11111", "n": 10}'
