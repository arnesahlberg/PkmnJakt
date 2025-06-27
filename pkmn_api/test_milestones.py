#!/usr/bin/env python3
"""Test script to verify milestone functionality works after refactoring."""

import requests
import json
import sys
from colorama import Fore, Style, init

init()

BASE_URL = "https://127.0.0.1:8081"
HEADERS = {"Content-Type": "application/json"}

# Disable SSL warnings for local testing
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def make_request(method, endpoint, data=None, token=None):
    """Make a request to the API."""
    url = f"{BASE_URL}/{endpoint}"
    headers = HEADERS.copy()
    
    if token:
        headers["Authorization"] = token
    
    try:
        if method.upper() == "GET":
            response = requests.get(url, headers=headers, verify=False)
        elif method.upper() == "POST":
            response = requests.post(url, headers=headers, data=json.dumps(data) if data else None, verify=False)
        return response
    except requests.exceptions.RequestException as e:
        print(f"{Fore.RED}Request failed: {str(e)}{Style.RESET_ALL}")
        return None

def test_milestones():
    """Test milestone functionality."""
    print(f"{Fore.CYAN}=== Testing Milestone Functionality ==={Style.RESET_ALL}\n")
    
    # 1. Login as admin user first (needed for cleanup)
    print(f"{Fore.YELLOW}1. Logging in as admin user...{Style.RESET_ALL}")
    admin_response = make_request("POST", "login", {
        "id": "admin",
        "password": "stensund"
    })
    if admin_response and admin_response.status_code == 200:
        admin_data = admin_response.json()
        if "token" in admin_data and "encoded_token" in admin_data["token"]:
            admin_token = admin_data["token"]["encoded_token"]
            print(f"{Fore.GREEN}✓ Admin login successful{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ Failed to login as admin: {admin_response.text if admin_response else 'No response'}{Style.RESET_ALL}")
        return
    
    # 2. Create a test user
    test_user = {
        "id": "milestone_test_user",
        "name": "Milestone Tester",
        "password": "TestPassword123!"
    }
    
    print(f"\n{Fore.YELLOW}2. Creating test user...{Style.RESET_ALL}")
    response = make_request("POST", "create_user", test_user)
    if response and response.status_code == 200:
        print(f"{Fore.GREEN}✓ User created successfully{Style.RESET_ALL}")
        # Extract token from response
        data = response.json()
        if "token" in data and "encoded_token" in data["token"]:
            token = data["token"]["encoded_token"]
    else:
        print(f"{Fore.RED}✗ Failed to create user: {response.text if response else 'No response'}{Style.RESET_ALL}")
        return
    
    # Token is already obtained from create_user, so skip login step
    
    # 3. Check initial milestones (should be empty)
    print(f"\n{Fore.YELLOW}3. Checking initial milestones...{Style.RESET_ALL}")
    response = make_request("GET", f"user_milestones/{test_user['id']}")
    if response and response.status_code == 200:
        milestones = response.json()
        print(f"Initial milestones: {milestones}")
        if len(milestones) == 0:
            print(f"{Fore.GREEN}✓ No milestones initially (expected){Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}✗ Unexpected milestones found{Style.RESET_ALL}")
    
    # 4. Register pokemon to test milestones
    # These are some valid catch codes from the test data
    catch_codes = [
        "ac3cf629-e151-45a6-a328-5af466cb471d",  # 1
        "331444e7-7a2b-48e3-abe5-74e486b82fb3",  # 2
        "f3bb7f69-3b66-4cf6-8342-85e17951b502",  # 3
        "2ddf72ec-32a4-40e3-b6c4-e4d03e4339a2",  # 4
        "44cda3fd-62e5-4d68-a41a-7ae472d8aa5b",  # 5
        "7a6af775-748a-44ab-9812-dfe934d5fab5",  # 6
        "d9f5fe6e-22bd-4240-918c-9994a062df82",  # 7
        "5743cf38-643d-45dd-8bff-ebecd81939ff",  # 8
        "3c87f67d-dd24-4711-b1b8-347375732ec1",  # 9
        "9081c390-e46a-40fe-8234-04cad2e97f38",  # 10 - This should trigger milestone!
    ]
    
    print(f"\n{Fore.YELLOW}4. Registering 10 pokemon to trigger first milestone...{Style.RESET_ALL}")
    milestone_triggered = False
    
    for i, catch_code in enumerate(catch_codes, 1):
        response = make_request("POST", "found_pokemon", {
            "catch_code": catch_code
        }, token)
        
        if response and response.status_code == 200:
            data = response.json()
            print(f"  Pokemon {i}: {data.get('message', 'Registered')}")
            if data.get('milestone_reached'):
                print(f"{Fore.GREEN}  ✓ MILESTONE REACHED: {data['milestone_reached']} pokemon!{Style.RESET_ALL}")
                milestone_triggered = True
        else:
            print(f"{Fore.RED}  ✗ Failed to register pokemon {i}{Style.RESET_ALL}")
    
    if milestone_triggered:
        print(f"\n{Fore.GREEN}✓ Milestone system is working correctly!{Style.RESET_ALL}")
    else:
        print(f"\n{Fore.RED}✗ No milestone was triggered (expected at 10 pokemon){Style.RESET_ALL}")
    
    # 5. Check milestones after catching 10 pokemon
    print(f"\n{Fore.YELLOW}5. Checking milestones after catching 10 pokemon...{Style.RESET_ALL}")
    response = make_request("GET", f"user_milestones/{test_user['id']}")
    if response and response.status_code == 200:
        milestones = response.json()
        print(f"Current milestones: {milestones}")
        if 10 in milestones:
            print(f"{Fore.GREEN}✓ 10-pokemon milestone correctly recorded{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}✗ 10-pokemon milestone not found{Style.RESET_ALL}")
    
    # 6. Clean up - delete test user
    print(f"\n{Fore.YELLOW}6. Cleaning up test user...{Style.RESET_ALL}")
    response = make_request("POST", "admin_delete_user", {
        "id": test_user["id"]
    }, admin_token)
    if response and response.status_code == 200:
        print(f"{Fore.GREEN}✓ Test user deleted{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ Failed to delete test user: {response.text if response else 'No response'}{Style.RESET_ALL}")
    
    print(f"\n{Fore.CYAN}=== Milestone Testing Complete ==={Style.RESET_ALL}")

if __name__ == "__main__":
    # Note: Make sure the API server is running before executing this test
    print(f"{Fore.YELLOW}Note: This test requires the API server to be running at {BASE_URL}{Style.RESET_ALL}\n")
    
    try:
        test_milestones()
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}Test interrupted by user{Style.RESET_ALL}")
    except Exception as e:
        print(f"\n{Fore.RED}Test failed with error: {str(e)}{Style.RESET_ALL}")
        sys.exit(1)