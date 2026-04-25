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

def print_response(response, endpoint, color=Fore.CYAN):
    """Pretty print the response with status code."""
    print(f"\n{Fore.CYAN}==== {endpoint} ===={Style.RESET_ALL}")
    print(f"Status code: {response.status_code}")
    
    try:
        if response.status_code >= 400:
            print(f"{color}Error: {response.text}{Style.RESET_ALL}")
        else:
            # Try to pretty print the JSON
            parsed = json.loads(response.text)
            print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError:
        print(f"Response: {response.text}")
    except Exception as e:
        print(f"{Fore.RED}Error processing response: {str(e)}{Style.RESET_ALL}")

def make_request(method, endpoint, data=None, token=None, expected_status=None, silent=False):
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
        

        if expected_status is not None and response.status_code != expected_status:
            print(f"{Fore.RED}Expected status {expected_status} but got {response.status_code}{Style.RESET_ALL}")
            print_response(response, endpoint, Fore.RED)
            sys.exit(1)
        if not silent:
            print_response(response, endpoint, Fore.GREEN)
        
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
    print(f"{Fore.YELLOW}Test 1: Attempt login with non-existent user (expecting 401){Style.RESET_ALL}")
    login_response = make_request("POST", "login", {
        "id": "11111",
        "password": "1234"
    }, expected_status=404)
    
    # 2. Create users
    users = [
        {"id": "11111", "name": "Leif Katt", "password": "1234"},
        {"id": "22222", "name": "Sture Stur", "password": "stur-pass"},
        {"id": "33333", "name": "Lisa Lis", "password": "lis-pass"},
        {"id": "44444", "name": "Frulle Frull", "password": "frull-pass"},
        {"id": "55555", "name": "Sven Svensson", "password": "sven-pass"},
        {"id": "66666", "name": "Anna Andersson", "password": "anna-pass"},
        {"id": "77777", "name": "Bertil Bertilsson", "password": "bertil-pass"},
        {"id": "88888", "name": "Ceci Ceder", "password": "ceci-pass"},
        {"id": "99999", "name": "Dennis Dunder", "password": "dennis-pass"},
        {"id": "10000", "name": "Eva Evert", "password": "eva-pass"},
        {"id": "10101", "name": "Fia Fjäril", "password": "fia-pass"},
        {"id": "20202", "name": "Gösta Gök", "password": "gösta-pass"},
        {"id": "30303", "name": "Hanna Hjärta", "password": "hanna-pass"},
        {"id": "40404", "name": "Ivar Is", "password": "ivar-pass"},
        {"id": "50505", "name": "Jenny Järn", "password": "jenny-pass"},
        {"id": "60606", "name": "Kalle Katt", "password": "kalle-pass"},
        {"id": "70707", "name": "Lena Löv", "password": "lena-pass"},
        {"id": "80808", "name": "Mats Mås", "password": "mats-pass"},
        {"id": "90909", "name": "Nina Natt", "password": "nina-pass"},
        {"id": "01010", "name": "Olof Orm", "password": "olof-pass"},
        {"id": "11112", "name": "Pia Pigg", "password": "pia-pass"},
        {"id": "21213", "name": "Qvarn Qvist", "password": "qvarn-pass"},
        {"id": "31314", "name": "Rolf Råtta", "password": "rolf-pass"},
        {"id": "41415", "name": "Sara Sjö", "password": "sara-pass"},
        {"id": "51516", "name": "Tobias Tjur", "password": "tobias-pass"},
        {"id": "61617", "name": "Ulla Uggla", "password": "ulla-pass"},
        {"id": "71718", "name": "Viktor Varg", "password": "viktor-pass"},
        {"id": "81819", "name": "Wilma Warg", "password": "wilma-pass"},
        {"id": "91920", "name": "Xerxes Xylofon", "password": "xerxes-pass"},
        {"id": "02021", "name": "Ylva Ylle", "password": "ylva-pass"},
    ]
    for user in users:
        print(f"{Fore.YELLOW}Test 2: Creating user {user['id']} ({user['name']}) (expecting 200){Style.RESET_ALL}")
        response = make_request("POST", "create_user", user, expected_status=200)
        if response and response.status_code == 200:
            data = json.loads(response.text)
            if "token" in data and "encoded_token" in data["token"]:
                tokens[user["id"]] = data["token"]["encoded_token"]
                print(f"Stored token for user {user['id']}")
    
    # 3. Logout first user
    print(f"{Fore.YELLOW}Test 3: Logging out user 11111 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "logout", None, tokens["11111"], expected_status=200)
    
    # 4. Login again with first user
    print(f"{Fore.YELLOW}Test 4: Logging in user 11111 (expecting 200){Style.RESET_ALL}")
    login_response = make_request("POST", "login", {
        "id": "11111",
        "password": "1234"
    }, expected_status=200)
    if login_response and login_response.status_code == 200:
        data = json.loads(login_response.text)
        if "token" in data and "encoded_token" in data["token"]:
            tokens["11111"] = data["token"]["encoded_token"]
            print(f"Updated token for user 11111")
    
    # 5. Update username for second user
    print(f"{Fore.YELLOW}Test 5: Updating username for user 22222 (expecting 200){Style.RESET_ALL}")
    if "22222" in tokens:
        make_request("POST", "set_user_name", {
            "name": "Sture Stör"
        }, tokens["22222"], expected_status=200)
    
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
            print(f"{Fore.YELLOW}Test 6: User {catch['user']} found pokemon with code {catch['catch_code']} (expecting 200){Style.RESET_ALL}")
            make_request("POST", "found_pokemon", {
                "catch_code": catch["catch_code"]
            }, tokens[catch["user"]], expected_status=200)
    
    # 7. View found pokemon for user 1
    print(f"{Fore.YELLOW}Test 7: Viewing found pokemon for user 11111 (expecting 200){Style.RESET_ALL}")
    if "11111" in tokens:
        make_request("POST", "view_found_pokemon", {
            "n": 10
        }, tokens["11111"], expected_status=200)
    
    # 8. Get user's pokedex
    print(f"{Fore.YELLOW}Test 8: Getting pokedex for user 11111 (expecting 200){Style.RESET_ALL}")
    if "11111" in tokens:
        make_request("GET", "my_pokedex", None, tokens["11111"], expected_status=200)
    
    # 9. Statistics calls
    print(f"{Fore.YELLOW}Test 9a: Getting statistics highscore (expecting 200){Style.RESET_ALL}")
    make_request("GET", "statistics_highscore", expected_status=200)
    print(f"{Fore.YELLOW}Test 9b: Getting latest pokemon found statistics (expecting 200){Style.RESET_ALL}")
    make_request("GET", "statistics_latest_pokemon_found", expected_status=200)
    print(f"{Fore.YELLOW}Test 9c: Getting pokemon with id 1 (expecting 200){Style.RESET_ALL}")
    make_request("GET", "get_pokemon/1", expected_status=200)

    # 10. Change user password
    print(f"{Fore.YELLOW}Test 10a: Changing password with wrong old password for user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("POST", "set_password", {
        "old_password": "1233",  # wrong old password
        "new_password": "new_password"
    }, tokens["11111"], expected_status=401)
    print(f"{Fore.YELLOW}Test 10b: Changing password with correct old password for user 11111 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "set_password", {
        "old_password": "1234",  # correct old password
        "new_password": "new_password"
    }, tokens["11111"], expected_status=200)
    print(f"{Fore.YELLOW}Test 10c: Logging out after password change (expecting 200){Style.RESET_ALL}")
    make_request("POST", "logout", None, tokens["11111"], expected_status=200)
    print(f"{Fore.YELLOW}Test 10d: Login with old password should fail for user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("POST", "login", {
        "id": "11111",
        "password": "1234"  # test old password, should not work
    }, expected_status=401)
    print(f"{Fore.YELLOW}Test 10e: Login with new password should succeed for user 11111 (expecting 200){Style.RESET_ALL}")
    response = make_request("POST", "login", {
        "id": "11111",
        "password": "new_password"  # test new password, should work
    }, expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if "token" in data and "encoded_token" in data["token"]:
            tokens["11111"] = data["token"]["encoded_token"]
            print(f"Updated token for user 11111")
    
    # 11. Validate password
    print(f"{Fore.YELLOW}Test 11a: Validate password with wrong password for user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("POST", "validate_password", {
        "password": "1234"
    }, tokens["11111"], expected_status=401)
    print(f"{Fore.YELLOW}Test 11b: Validate password with correct password for user 11111 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "validate_password", {
        "password": "new_password"
    }, tokens["11111"], expected_status=200)
    
    # 12. Validate token
    print(f"{Fore.YELLOW}Test 12a: Validate token while logged in for user 11111 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "validate_token", None, tokens["11111"], expected_status=200)
    print(f"{Fore.YELLOW}Test 12b: Logging out user 11111 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "logout", None, tokens["11111"], expected_status=200)
    print(f"{Fore.YELLOW}Test 12c: Validate token after logout for user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("POST", "validate_token", None, tokens["11111"], expected_status=401)
    
    # Test logout_everywhere functionality
    print(f"{Fore.YELLOW}Test 12d: Re-login user 11111 for logout_everywhere test (expecting 200){Style.RESET_ALL}")
    response = make_request("POST", "login", {
        "id": "11111",
        "password": "new_password"  # Password was changed in Test 10e
    }, expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if "token" in data and "encoded_token" in data["token"]:
            tokens["11111"] = data["token"]["encoded_token"]
    
    print(f"{Fore.YELLOW}Test 12e: Test logout_everywhere for user 11111 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "logout_everywhere", None, tokens["11111"], expected_status=200)
    print(f"{Fore.YELLOW}Test 12f: Validate token after logout_everywhere for user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("POST", "validate_token", None, tokens["11111"], expected_status=401)
    
    # 13. Check if user is admin
    print(f"{Fore.YELLOW}Test 13a: Check admin status for non-admin user 11111 (expecting 401){Style.RESET_ALL}")
    response = make_request("GET", "am_i_admin", None, tokens["11111"], expected_status=401)
    if response and response.status_code == 401:
        data = json.loads(response.text)
        if data.get("is_admin") == False:
            print(f"{Fore.GREEN}  ✓ Correctly returned is_admin: false for non-admin user{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: false but got: {data.get('is_admin')}{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}Test 13b: Login as admin user (expecting 200){Style.RESET_ALL}")
    res = make_request("POST", "login", {
        "id": "admin",
        "password": "stensund"
    }, expected_status=200)
    if res and res.status_code == 200:
        data = json.loads(res.text)
        if "token" in data and "encoded_token" in data["token"]:
            tokens["admin"] = data["token"]["encoded_token"]
            print(f"Updated token for user admin")
    else:
        print("Failed to login as admin user.")
        sys.exit(1)
    
    print(f"{Fore.YELLOW}Test 13c: Check admin status for admin user (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "am_i_admin", None, tokens["admin"], expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if data.get("is_admin") == True:
            print(f"{Fore.GREEN}  ✓ Correctly returned is_admin: true for admin user{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: true but got: {data.get('is_admin')}{Style.RESET_ALL}")
    
    # 14. Reset password for user as admin/non-admin
    print(f"{Fore.YELLOW}Test 14a: Non-admin attempting to reset password for user 11111 (expecting 403){Style.RESET_ALL}")
    make_request("POST", "admin_reset_user_password", {
        "id": "11111", "new_password": "123456"
    }, tokens["22222"], expected_status=403)
    print(f"{Fore.YELLOW}Test 14b: Admin resetting password (expecting 200){Style.RESET_ALL}")
    make_request("POST", "admin_reset_user_password", {
        "id": "11111", "new_password": "123456"
    }, tokens["admin"], expected_status=200)


    # 15. Query users
    print(f"{Fore.YELLOW}\nTest 15: Querying users (expecting 200){Style.RESET_ALL}")
    data = {
        "n": 10,
        "skip": 0
    }
    make_request("POST","get_users", data, tokens["admin"], expected_status=200)

    print(f"{Fore.YELLOW}\nTest 15b: Get users without admin token (expecting 403){Style.RESET_ALL}")
    make_request("POST","get_users", data, tokens["22222"], expected_status=403)

    # 15b. query users with filter
    data = {
        "n": 10,
        "filter" : "katt",
    }
    print(f"{Fore.YELLOW}\nTest 15c: Querying users with filter (expecting 200){Style.RESET_ALL}")
    make_request("POST","get_users_filter", data, tokens["admin"], expected_status=200)
    
    # 16. Delete users
    print(f"{Fore.YELLOW}\nTest 16a: Deleting user 44444 (expecting 200){Style.RESET_ALL}")
    data = {
        "id": "44444"
    }
    make_request("POST", "admin_delete_user", data, tokens["admin"], expected_status=200)

    # try to log in as deleted user
    print(f"{Fore.YELLOW}\nTest 16b: Attempting to login as deleted user 44444 (expecting 401){Style.RESET_ALL}")
    make_request("POST", "login", {
        "id": "44444",
        "password": "frull-pass"
    }, expected_status=404)

    # try to delete user as non admin
    data = {
        "id": "33333"
    }
    
    print(f"{Fore.YELLOW}\nTest 16c: Attempting to delete user as non-admin (expecting 403){Style.RESET_ALL}")
    make_request("POST", "admin_delete_user", data, tokens["22222"], expected_status=403)

    # 17. get num users
    print(f"{Fore.YELLOW}\nTest 17: Getting number of users (expecting 200){Style.RESET_ALL}")
    make_request("GET", "num_users", None, tokens["admin"], expected_status=200)

    # Re-login user 11111 since they were logged out in test 12b
    print(f"{Fore.YELLOW}\nRe-logging in user 11111 for further tests...{Style.RESET_ALL}")
    response = make_request("POST", "login", {
        "id": "11111",
        "password": "123456"  # Password was reset by admin in test 14b
    }, expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if "token" in data and "encoded_token" in data["token"]:
            tokens["11111"] = data["token"]["encoded_token"]
            print(f"Updated token for user 11111")

    # 18. Check if user is admin
    print(f"{Fore.YELLOW}Test 18a: Non-admin user checking another user's admin status (expecting 403){Style.RESET_ALL}")
    response = make_request("GET", "is_user_admin/22222", None, tokens["11111"], expected_status=403)
    if response and response.status_code == 403:
        data = json.loads(response.text)
        print(f"{Fore.GREEN}  ✓ Non-admin correctly denied access{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}Test 18b: As admin, check admin status for user 22222 (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "is_user_admin/22222", None, tokens["admin"], expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if data.get("is_admin") == False:
            print(f"{Fore.GREEN}  ✓ Correctly returned is_admin: false for user 22222{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: false but got: {data.get('is_admin')}{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}Test 18c: As admin, check admin status for user admin (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "is_user_admin/admin", None, tokens["admin"], expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if data.get("is_admin") == True:
            print(f"{Fore.GREEN}  ✓ Correctly returned is_admin: true for admin user{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: true but got: {data.get('is_admin')}{Style.RESET_ALL}")

    # 19. Make user into an admin
    print(f"{Fore.YELLOW}Test 19: Make user 22222 into an admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "make_user_admin", {"id": "22222"}, tokens["admin"], expected_status=200)

    # 20. Check if user is admin
    print(f"{Fore.YELLOW}Test 20a: Check admin status for user 22222 after making admin (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "is_user_admin/22222", None, tokens["admin"], expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if data.get("is_admin") == True:
            print(f"{Fore.GREEN}  ✓ Correctly returned is_admin: true for user 22222 after promotion{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: true but got: {data.get('is_admin')}{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}Test 20b: User 22222 checking own admin status via am_i_admin (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "am_i_admin", None, tokens["22222"], expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if data.get("is_admin") == True:
            print(f"{Fore.GREEN}  ✓ User 22222 correctly sees themselves as admin{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: true but got: {data.get('is_admin')}{Style.RESET_ALL}")

    # 21. Remove user from admin
    print(f"{Fore.YELLOW}Test 21: Remove user 22222 from admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "make_user_not_admin", {"id": "22222"}, tokens["admin"], expected_status=200)

    # 22. Check if user is admin
    print(f"{Fore.YELLOW}Test 22a: Check admin status for user 22222 after removal (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "is_user_admin/22222", None, tokens["admin"], expected_status=200)
    if response and response.status_code == 200:
        data = json.loads(response.text)
        if data.get("is_admin") == False:
            print(f"{Fore.GREEN}  ✓ Correctly returned is_admin: false for user 22222 after demotion{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected is_admin: false but got: {data.get('is_admin')}{Style.RESET_ALL}")

    # 23. Test Pokemon type statistics endpoints (with Swedish type names)
    print(f"{Fore.YELLOW}\nTest 23a: Get Pokemon count by type for user 11111 (expecting 200 with Swedish types){Style.RESET_ALL}")
    response = make_request("GET", "user_pokemon_by_type/11111", None, tokens["admin"], expected_status=200)
    if response and "Gräs" in str(response) or "Eld" in str(response):
        print(f"{Fore.GREEN}  ✓ Swedish type names detected{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}Test 23b: Get Pokemon count by type for non-existent user (expecting 404){Style.RESET_ALL}")
    make_request("GET", "user_pokemon_by_type/nonexistent", None, tokens["admin"], expected_status=404)
    
    print(f"{Fore.YELLOW}Test 23c: Get total Pokemon catches by type across all users (expecting 200 with Swedish types){Style.RESET_ALL}")
    response = make_request("GET", "total_pokemon_by_type", None, tokens["admin"], expected_status=200)
    if response and ("Vatten" in str(response) or "Elektro" in str(response)):
        print(f"{Fore.GREEN}  ✓ Swedish type names detected in global stats{Style.RESET_ALL}")
    
    print(f"{Fore.YELLOW}Test 23d: Get total Pokemon catches by type without authentication (expecting 200){Style.RESET_ALL}")
    make_request("GET", "total_pokemon_by_type", None, expected_status=200)

    # 24. Test game status endpoints (no auth required)
    print(f"{Fore.YELLOW}\nTest 24a: Check if game is over{Style.RESET_ALL}")
    response = make_request("GET", "is_game_over", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Game is over: {data.get('is_game_over')}")
        print(f"  Current time: {data.get('current_time')}")
        print(f"  Game end time: {data.get('game_end_time')}")
    
    print(f"{Fore.YELLOW}Test 24b: Check if game has started{Style.RESET_ALL}")
    response = make_request("GET", "has_game_started", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Game has started: {data.get('has_game_started')}")
        print(f"  Current time: {data.get('current_time')}")
        print(f"  Game start time: {data.get('game_start_time')}")
    
    print(f"{Fore.YELLOW}Test 24c: Get server time{Style.RESET_ALL}")
    response = make_request("GET", "server_time", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Server time UTC: {data.get('server_time_utc')}")
        print(f"  Server time CET: {data.get('server_time_cet')}")
    
    # 25. Test game summary statistics endpoint (no auth required)
    print(f"{Fore.YELLOW}\nTest 25a: Get game summary statistics (no time window){Style.RESET_ALL}")
    response = make_request("GET", "statistics/game_summary", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Total users: {data.get('total_users_registered')}")
        print(f"  Users with 10+ catches: {data.get('users_with_10_plus_catches')}")
        print(f"  Users with 100+ catches: {data.get('users_with_100_plus_catches')}")
        print(f"  First catch: {data.get('first_catch')}")
        print(f"  Last catch: {data.get('last_catch')}")
        print(f"  Top 10 players count: {len(data.get('top_10_players', []))}")
        print(f"  Most caught pokemon count: {len(data.get('most_caught_pokemon', []))}")
        print(f"  Least caught pokemon count: {len(data.get('least_caught_pokemon', []))}")
        print(f"  Hourly catches count: {len(data.get('catches_per_hour', []))}")
    
    print(f"{Fore.YELLOW}Test 25b: Get game summary statistics with time window{Style.RESET_ALL}")
    response = make_request("GET", "statistics/game_summary?datetime0=2025-07-07 12:00:00&datetime1=2025-07-15 18:00:00", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Time window start: {data.get('time_window_start')}")
        print(f"  Time window end: {data.get('time_window_end')}")

    # 26. Test missing public endpoints
    print(f"{Fore.YELLOW}\\nTest 26a: Get paginated highscores (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "highscores?page=1&per_page=5", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Page: {data.get('page')}, Per page: {data.get('per_page')}, Total: {data.get('total_count')}")
    
    print(f"{Fore.YELLOW}Test 26b: Search highscores (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "highscores/search?search=katt&page=1&per_page=5", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Search results: {len(data.get('scores', []))} users found")
    
    print(f"{Fore.YELLOW}Test 26c: Get Pokemon found counts (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "pokemon_found_counts", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Pokemon counts returned: {len(data.get('pokemon_counts', []))}")

    # 27. Test user info endpoints (public endpoints)
    print(f"{Fore.YELLOW}\\nTest 27a: Get user info for existing user 22222 (expecting 200){Style.RESET_ALL}")
    make_request("GET", "get_user/22222", None, expected_status=200)
    
    print(f"{Fore.YELLOW}Test 27b: Get user info for non-existent user (expecting 404){Style.RESET_ALL}")
    make_request("GET", "get_user/nonexistent", None, expected_status=404)
    
    print(f"{Fore.YELLOW}Test 27c: Check if user exists for existing user 22222 (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "user_exists/22222", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  User exists: {data.get('exists')}")
    
    print(f"{Fore.YELLOW}Test 27d: Check if user exists for non-existent user (expecting 200 with false){Style.RESET_ALL}")
    response = make_request("GET", "user_exists/nonexistent", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  User exists: {data.get('exists')}")
    
    print(f"{Fore.YELLOW}Test 27e: Get user ranking for existing user 22222 (expecting 200){Style.RESET_ALL}")
    make_request("GET", "user_ranking/22222", None, expected_status=200)
    
    print(f"{Fore.YELLOW}Test 27f: Get user ranking for non-existent user (expecting 404){Style.RESET_ALL}")
    make_request("GET", "user_ranking/nonexistent", None, expected_status=404)
    
    print(f"{Fore.YELLOW}Test 27g: Get user pokedex for user with Pokemon (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "user_pokedex/11111", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Pokemon in pokedex: {len(data) if isinstance(data, list) else 'N/A'}")
    
    print(f"{Fore.YELLOW}Test 27h: Get user pokedex for non-existent user (expecting 404){Style.RESET_ALL}")
    make_request("GET", "user_pokedex/nonexistent", None, expected_status=404)

    # 28. Test admin endpoint missing from earlier tests
    print(f"{Fore.YELLOW}\\nTest 28a: Admin filter users by ID only (expecting 200){Style.RESET_ALL}")
    make_request("POST", "get_users_filter_id", {
        "filter": "111",
        "n": 5
    }, tokens["admin"], expected_status=200)
    
    print(f"{Fore.YELLOW}Test 28b: Non-admin attempting to filter users by ID (expecting 403){Style.RESET_ALL}")
    make_request("POST", "get_users_filter_id", {
        "filter": "111",
        "n": 5
    }, tokens["22222"], expected_status=403)

    # 29. Test milestone endpoints
    print(f"{Fore.YELLOW}\\nTest 29a: Get user milestones for user with Pokemon (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "user_milestones/11111", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Milestones achieved: {data if isinstance(data, list) else 'N/A'}")
    
    print(f"{Fore.YELLOW}Test 29b: Get user milestones for non-existent user (expecting 404){Style.RESET_ALL}")
    make_request("GET", "user_milestones/nonexistent", None, expected_status=404)
    
    print(f"{Fore.YELLOW}Test 29c: Get user milestone definitions for user with Pokemon (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "user_milestone_definitions/11111", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Milestone definitions count: {len(data) if isinstance(data, list) else 'N/A'}")
    
    print(f"{Fore.YELLOW}Test 29d: Get user milestone definitions for non-existent user (expecting 404){Style.RESET_ALL}")
    make_request("GET", "user_milestone_definitions/nonexistent", None, expected_status=404)

    # 30. Edge case and error testing
    print(f"{Fore.YELLOW}\\nTest 30a: Test pagination edge cases{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Test 30a1: Page 0 (should default to 1) (expecting 200){Style.RESET_ALL}")
    make_request("GET", "highscores?page=0&per_page=5", None, expected_status=200)
    
    print(f"{Fore.YELLOW}Test 30a2: Negative page (should clamp to page 1) (expecting 200){Style.RESET_ALL}")
    make_request("GET", "highscores?page=-1&per_page=5", None, expected_status=200)
    
    print(f"{Fore.YELLOW}Test 30a3: Very large per_page (should be capped at 50) (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "highscores?page=1&per_page=1000", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  Actual per_page returned: {data.get('per_page')} (should be 50 or less)")
    
    print(f"{Fore.YELLOW}Test 30a4: Very large page number (should clamp to last page) (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "highscores?page=99999&per_page=5", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        if data.get("page", 0) <= data.get("total_pages", 1):
            print(f"{Fore.GREEN}✓ Large page number clamped to {data.get('page')} (total pages: {data.get('total_pages')}){Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}✗ Large page number not clamped properly{Style.RESET_ALL}")
        print(f"  Results on clamped page: {len(data.get('scores', []))}")

    print(f"{Fore.YELLOW}\\nTest 30b: Test invalid token scenarios{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Test 30b1: Invalid token format for protected endpoint (expecting 401){Style.RESET_ALL}")
    make_request("POST", "validate_token", None, "invalid-token-format", expected_status=401)
    
    print(f"{Fore.YELLOW}Test 30b2: Empty token for protected endpoint (expecting 401){Style.RESET_ALL}")
    make_request("POST", "validate_token", None, "", expected_status=401)
    
    print(f"{Fore.YELLOW}Test 30b3: No token header for protected endpoint (expecting 401){Style.RESET_ALL}")
    make_request("POST", "validate_token", None, None, expected_status=401)

    print(f"{Fore.YELLOW}\\nTest 30c: Test boundary conditions{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Test 30c1: Empty search string (expecting 200){Style.RESET_ALL}")
    make_request("GET", "highscores/search?search=&page=1&per_page=5", None, expected_status=200)
    
    print(f"{Fore.YELLOW}Test 30c2: Very long search string (expecting 200){Style.RESET_ALL}")
    long_search = "a" * 1000
    make_request("GET", f"highscores/search?search={long_search}&page=1&per_page=5", None, expected_status=200)
    
    print(f"{Fore.YELLOW}Test 30c3: Special characters in search (expecting 200){Style.RESET_ALL}")
    make_request("GET", "highscores/search?search=%20%21%40%23&page=1&per_page=5", None, expected_status=200)

    print(f"{Fore.YELLOW}\\nTest 30d: Test admin endpoint error conditions{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Test 30d1: Admin operations without admin token (expecting 403){Style.RESET_ALL}")
    make_request("POST", "make_user_admin", {"id": "22222"}, tokens["22222"], expected_status=403)
    
    print(f"{Fore.YELLOW}Test 30d2: Admin operations on non-existent user (expecting 404 or error){Style.RESET_ALL}")
    make_request("POST", "admin_reset_user_password", {
        "id": "nonexistent", 
        "new_password": "newpass"
    }, tokens["admin"], expected_status=404)
    
    print(f"{Fore.YELLOW}Test 30d3: Make non-existent user admin (expecting 200 but no effect){Style.RESET_ALL}")
    make_request("POST", "make_user_admin", {"id": "nonexistent"}, tokens["admin"], expected_status=200)

    print(f"{Fore.YELLOW}\\nTest 30e: Test Pokemon-related edge cases{Style.RESET_ALL}")
    print(f"{Fore.YELLOW}Test 30e1: Get non-existent Pokemon (expecting 404){Style.RESET_ALL}")
    make_request("GET", "get_pokemon/99999", None, expected_status=404)
    
    print(f"{Fore.YELLOW}Test 30e2: Try to catch Pokemon with invalid catch code (expecting 400){Style.RESET_ALL}")
    make_request("POST", "found_pokemon", {
        "catch_code": "invalid-catch-code-12345"
    }, tokens["admin"], expected_status=400)
    
    print(f"{Fore.YELLOW}Test 30e3: View found Pokemon with 0 limit (expecting 200){Style.RESET_ALL}")
    make_request("POST", "view_found_pokemon", {"n": 0}, tokens["admin"], expected_status=200)
    
    print(f"{Fore.YELLOW}Test 30e4: View found Pokemon with negative limit (expecting 200){Style.RESET_ALL}")
    make_request("POST", "view_found_pokemon", {"n": -1}, tokens["admin"], expected_status=200)

    # 31. Test settings endpoints
    print(f"{Fore.YELLOW}\nTest 31a: GET /settings/datamatrix_login_enabled without auth (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "settings/datamatrix_login_enabled", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        print(f"  datamatrix_login_enabled: {data.get('enabled')}")

    print(f"{Fore.YELLOW}Test 31b: Confirm default is true (expecting 200 with enabled: true){Style.RESET_ALL}")
    response = make_request("GET", "settings/datamatrix_login_enabled", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        if data.get("enabled") == True:
            print(f"{Fore.GREEN}  ✓ Default value is true{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected enabled: true but got: {data.get('enabled')}{Style.RESET_ALL}")

    print(f"{Fore.YELLOW}Test 31c: POST /admin/set_setting as non-admin (expecting 403){Style.RESET_ALL}")
    make_request("POST", "admin/set_setting", {
        "setting_id": "datamatrix_login_enabled",
        "setting_value": "false"
    }, tokens["22222"], expected_status=403)

    print(f"{Fore.YELLOW}Test 31d: POST /admin/set_setting with unknown setting_id (expecting 400){Style.RESET_ALL}")
    make_request("POST", "admin/set_setting", {
        "setting_id": "unknown_setting",
        "setting_value": "true"
    }, tokens["admin"], expected_status=400)

    print(f"{Fore.YELLOW}Test 31e: POST /admin/set_setting disable datamatrix as admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "admin/set_setting", {
        "setting_id": "datamatrix_login_enabled",
        "setting_value": "false"
    }, tokens["admin"], expected_status=200)

    print(f"{Fore.YELLOW}Test 31f: GET /settings/datamatrix_login_enabled after disabling (expecting 200 with enabled: false){Style.RESET_ALL}")
    response = make_request("GET", "settings/datamatrix_login_enabled", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        if data.get("enabled") == False:
            print(f"{Fore.GREEN}  ✓ Correctly disabled, enabled: false{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected enabled: false but got: {data.get('enabled')}{Style.RESET_ALL}")

    print(f"{Fore.YELLOW}Test 31g: POST /admin/set_setting re-enable datamatrix as admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "admin/set_setting", {
        "setting_id": "datamatrix_login_enabled",
        "setting_value": "true"
    }, tokens["admin"], expected_status=200)

    print(f"{Fore.YELLOW}Test 31h: GET /settings/datamatrix_login_enabled after re-enabling (expecting 200 with enabled: true){Style.RESET_ALL}")
    response = make_request("GET", "settings/datamatrix_login_enabled", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        if data.get("enabled") == True:
            print(f"{Fore.GREEN}  ✓ Correctly re-enabled, enabled: true{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}  ✗ Expected enabled: true but got: {data.get('enabled')}{Style.RESET_ALL}")

    # 32. Test pokemon active/disabled endpoints
    print(f"{Fore.YELLOW}\nTest 32a: GET /enabled_pokemon_ids (no auth, expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "enabled_pokemon_ids", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        assert "ids" in data, "Response missing 'ids' field"
        print(f"  Enabled pokemon count: {len(data['ids'])}")

    print(f"{Fore.YELLOW}Test 32b: GET /admin/pokemon_list as admin (expecting 200){Style.RESET_ALL}")
    response = make_request("GET", "admin/pokemon_list", None, tokens["admin"], expected_status=200)
    if response:
        data = json.loads(response.text)
        assert "pokemon" in data, "Response missing 'pokemon' field"
        assert all("id" in p and "name" in p and "active" in p for p in data["pokemon"]), "Pokemon entries missing fields"
        print(f"  Total pokemon in list: {len(data['pokemon'])}")

    print(f"{Fore.YELLOW}Test 32c: GET /admin/pokemon_list without auth (expecting 401){Style.RESET_ALL}")
    make_request("GET", "admin/pokemon_list", None, None, expected_status=401)

    print(f"{Fore.YELLOW}Test 32d: POST /admin/set_pokemon_active disable pokemon 2 as admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "admin/set_pokemon_active", {"pokemon_id": 2, "active": False}, tokens["admin"], expected_status=200)

    print(f"{Fore.YELLOW}Test 32e: GET /enabled_pokemon_ids — verify pokemon 2 is NOT in list{Style.RESET_ALL}")
    response = make_request("GET", "enabled_pokemon_ids", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        assert 2 not in data["ids"], f"Pokemon 2 should be disabled but found in ids: {data['ids']}"
        print(f"{Fore.GREEN}  ✓ Pokemon 2 not in enabled ids{Style.RESET_ALL}")

    print(f"{Fore.YELLOW}Test 32f: GET /admin/pokemon_list — verify pokemon 2 shows active: false{Style.RESET_ALL}")
    response = make_request("GET", "admin/pokemon_list", None, tokens["admin"], expected_status=200)
    if response:
        data = json.loads(response.text)
        pokemon2 = next((p for p in data["pokemon"] if p["id"] == 2), None)
        assert pokemon2 is not None, "Pokemon 2 not found in list"
        assert pokemon2["active"] == False, f"Expected active: false but got: {pokemon2['active']}"
        print(f"{Fore.GREEN}  ✓ Pokemon 2 active: false{Style.RESET_ALL}")

    print(f"{Fore.YELLOW}Test 32g: Try to catch disabled pokemon 2 (expecting 403 with result_code 11){Style.RESET_ALL}")
    response = make_request("POST", "found_pokemon", {
        "catch_code": "bf52b549-27f7-464c-929e-8764621ebfc7"
    }, tokens["11111"], expected_status=403)
    if response:
        data = json.loads(response.text)
        assert data.get("result_code") == 11, f"Expected result_code 11 but got: {data.get('result_code')}"
        print(f"{Fore.GREEN}  ✓ result_code 11 (pokemon disabled){Style.RESET_ALL}")

    print(f"{Fore.YELLOW}Test 32h: POST /admin/set_pokemon_active re-enable pokemon 2 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "admin/set_pokemon_active", {"pokemon_id": 2, "active": True}, tokens["admin"], expected_status=200)

    print(f"{Fore.YELLOW}Test 32i: GET /enabled_pokemon_ids — verify pokemon 2 is back in list{Style.RESET_ALL}")
    response = make_request("GET", "enabled_pokemon_ids", None, expected_status=200)
    if response:
        data = json.loads(response.text)
        assert 2 in data["ids"], f"Pokemon 2 should be enabled but not found in ids"
        print(f"{Fore.GREEN}  ✓ Pokemon 2 back in enabled ids{Style.RESET_ALL}")

    print(f"{Fore.YELLOW}Test 32j: Catch re-enabled pokemon 2 as user 22222 (expecting 200){Style.RESET_ALL}")
    make_request("POST", "found_pokemon", {
        "catch_code": "bf52b549-27f7-464c-929e-8764621ebfc7"
    }, tokens["22222"], expected_status=200)

    print(f"{Fore.YELLOW}Test 32k: POST /admin/set_pokemon_active as non-admin (expecting 403){Style.RESET_ALL}")
    make_request("POST", "admin/set_pokemon_active", {"pokemon_id": 2, "active": False}, tokens["22222"], expected_status=403)

    # Final: DELETE ALL USERS
    print(f"{Fore.YELLOW}\nTest 18: Deleting all users by looping{Style.RESET_ALL}")
    for user in users:
        if user["id"] != "44444": # skip already deleted user
            print(f"{Fore.YELLOW}Deleting user {user['id']}{Style.RESET_ALL}")
            make_request("POST", "admin_delete_user", {"id": user["id"]}, tokens["admin"], expected_status=200, silent=True)
    
    
    print(f"\n{Fore.GREEN}API tests completed!{Style.RESET_ALL}")

if __name__ == "__main__":
    print(f"{Fore.YELLOW}Starting Pokemon API Test Suite{Style.RESET_ALL}")
    run_tests()