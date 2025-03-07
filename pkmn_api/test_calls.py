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
    
    # 13. Check if user is admin
    print(f"{Fore.YELLOW}Test 13a: Check admin status for non-admin user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("GET", "am_i_admin", None, tokens["11111"], expected_status=401)
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
    make_request("GET", "am_i_admin", None, tokens["admin"], expected_status=200)
    
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


    # 18. Check if user is admin
    print(f"{Fore.YELLOW}Test 18a: Check admin status for non-admin user 11111 (expecting 401){Style.RESET_ALL}")
    make_request("GET", "is_user_admin/22222", None, tokens["11111"], expected_status=401)
    print(f"{Fore.YELLOW}Test 18b: As admin, check admin status for user 22222 (expecting 200){Style.RESET_ALL}")
    make_request("GET", "is_user_admin/22222", None, tokens["admin"], expected_status=200)
    print(f"{Fore.YELLOW}Test 18c: As admin, check admin status for user admin (expecting 401){Style.RESET_ALL}")
    make_request("GET", "is_user_admin/admin", None, tokens["admin"], expected_status=200)

    # 19. Make user into an admin
    print(f"{Fore.YELLOW}Test 19: Make user 22222 into an admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "make_user_admin", {"id": "22222"}, tokens["admin"], expected_status=200)

    # 20. Check if user is admin
    print(f"{Fore.YELLOW}Test 20a: Check admin status for user 22222 (expecting 200){Style.RESET_ALL}")
    make_request("GET", "is_user_admin/22222", None, tokens["admin"], expected_status=200)
    print(f"{Fore.YELLOW}Test 20b: Check admin status for user 22222 (expecting 200){Style.RESET_ALL}")
    make_request("GET", "is_user_admin/22222", None, tokens["22222"], expected_status=200)

    # 21. Remove user from admin
    print(f"{Fore.YELLOW}Test 21: Remove user 22222 from admin (expecting 200){Style.RESET_ALL}")
    make_request("POST", "make_user_not_admin", {"id": "22222"}, tokens["admin"], expected_status=200)

    # 22. Check if user is admin
    print(f"{Fore.YELLOW}Test 22a: Check admin status for user 22222 (expecting 401){Style.RESET_ALL}")
    make_request("GET", "is_user_admin/22222", None, tokens["admin"], expected_status=200)


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