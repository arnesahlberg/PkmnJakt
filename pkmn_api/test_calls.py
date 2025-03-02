import requests
import json
import sys
from colorama import Fore, Style, init

# Initialize colorama for color output
init()

BASE_URL = "https://127.0.0.1:8081"
HEADERS = {"Content-Type": "application/json"}

# Dictionary to store tokens
tokens = {}

def print_response(response, endpoint):
    """Pretty print the response with status code."""
    print(f"\n{Fore.CYAN}==== {endpoint} ===={Style.RESET_ALL}")
    print(f"Status code: {response.status_code}")
    
    try:
        if response.status_code >= 400:
            print(f"{Fore.RED}Error: {response.text}{Style.RESET_ALL}")
        else:
            # Try to pretty print the JSON
            parsed = json.loads(response.text)
            print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError:
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"{Fore.RED}Error processing response: {str(e)}{Style.RESET_ALL}")

def make_request(method, endpoint, data=None, token=None):
    """Make a request to the API and handle errors."""
    url = f"{BASE_URL}/{endpoint}"
    headers = HEADERS.copy()
    
    if token:
        headers["Authorization"] = token
    
    try:
        if method.upper() == "GET":
            response = requests.get(url, headers=headers, verify=False)
        elif method.upper() == "POST":
            response = requests.post(url, headers=headers, data=json.dumps(data) if data else None, verify=False)
        else:
            print(f"{Fore.RED}Unsupported method: {method}{Style.RESET_ALL}")
            return None
        
        print_response(response, endpoint)
        return response
    except requests.exceptions.RequestException as e:
        print(f"{Fore.RED}Request error: {str(e)}{Style.RESET_ALL}")
        return None

def run_tests():
    """Run all API tests in sequence."""
    print(f"{Fore.GREEN}Starting API tests...{Style.RESET_ALL}")
    
    # Disable SSL warnings for self-signed certificates
    requests.packages.urllib3.disable_warnings()
    
    # 1. Try login (should fail for non-existent user)
    login_response = make_request("POST", "login", {
        "id": "11111",
        "password": "1234"
    })
    
    # 2. Create users
    users = [
        {"id": "11111", "name": "Leif Katt", "password": "1234"},
        {"id": "22222", "name": "Sture Stur", "password": "stur-pass"},
        {"id": "33333", "name": "Lisa Lis", "password": "lis-pass"}
    ]
    
    for user in users:
        response = make_request("POST", "create_user", user)
        if response and response.status_code == 200:
            data = json.loads(response.text)
            if "token" in data and "encoded_token" in data["token"]:
                tokens[user["id"]] = data["token"]["encoded_token"]
                print(f"Stored token for user {user['id']}")
    
    # 3. Test logout with first user
    if "11111" in tokens:
        make_request("POST", "logout", None, tokens["11111"])
    
    # 4. Login again with first user
    login_response = make_request("POST", "login", {
        "id": "11111",
        "password": "1234"
    })
    
    if login_response and login_response.status_code == 200:
        data = json.loads(login_response.text)
        if "token" in data and "encoded_token" in data["token"]:
            tokens["11111"] = data["token"]["encoded_token"]
            print(f"Updated token for user 11111")
    
    # 5. Update username for second user
    if "22222" in tokens:
        make_request("POST", "set_user_name", {
            "name": "Sture Stör"
        }, tokens["22222"])
    
    # 6. Found Pokemon calls
    catch_codes = [
        {"user": "11111", "catch_code": "ac3cf629-e151-45a6-a328-5af466cb471d"},
        {"user": "22222", "catch_code": "331444e7-7a2b-48e3-abe5-74e486b82fb3"},
        {"user": "11111", "catch_code": "f3bb7f69-3b66-4cf6-8342-85e17951b502"},
        {"user": "11111", "catch_code": "2ddf72ec-32a4-40e3-b6c4-e4d03e4339a2"},
        {"user": "22222", "catch_code": "44cda3fd-62e5-4d68-a41a-7ae472d8aa5b"},
        {"user": "11111", "catch_code": "7a6af775-748a-44ab-9812-dfe934d5fab5"},
        {"user": "11111", "catch_code": "d9f5fe6e-22bd-4240-918c-9994a062df82"}
    ]
    
    for catch in catch_codes:
        if catch["user"] in tokens:
            make_request("POST", "found_pokemon", {
                "catch_code": catch["catch_code"]
            }, tokens[catch["user"]])
    
    # 7. View found pokemon for user 1
    if "11111" in tokens:
        make_request("POST", "view_found_pokemon", {
            "n": 10
        }, tokens["11111"])
    
    # 8. Get user's pokedex
    if "11111" in tokens:
        make_request("GET", "my_pokedex", None, tokens["11111"])
    
    # 9. Statistics calls
    make_request("GET", "statistics_highscore")
    make_request("GET", "statistics_latest_pokemon_found")
    make_request("GET", "get_pokemon/1")


    #10. change user password
    make_request("POST", "set_password", {
        "old_password": "1233", # test wrong old password
        "new_password": "new_password"
    }, tokens["11111"])

    make_request("POST", "set_password", {
        "old_password": "1234", # test correct old password
        "new_password": "new_password"
    }, tokens["11111"])

    make_request("POST", "logout", None, tokens["11111"])
    make_request("POST", "login", {
        "id": "11111",
        "password": "1234" # test old password, should not work
    })
    make_request("POST", "login", {
        "id": "11111",
        "password": "new_password" # test new password, should work
    })


    
    print(f"\n{Fore.GREEN}API tests completed!{Style.RESET_ALL}")

if __name__ == "__main__":
    print(f"{Fore.YELLOW}Starting Pokemon API Test Suite{Style.RESET_ALL}")
    run_tests()