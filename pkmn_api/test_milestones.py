#!/usr/bin/env python3
"""Test script to verify comprehensive milestone functionality."""

import requests
import json
import sys
from colorama import Fore, Style, init
import time

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
    """Test comprehensive milestone functionality."""
    print(f"{Fore.CYAN}=== Testing Comprehensive Milestone Functionality ==={Style.RESET_ALL}\n")
    
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
    
    # Also check comprehensive milestone definitions
    response = make_request("GET", f"user_milestone_definitions/{test_user['id']}")
    if response and response.status_code == 200:
        milestone_defs = response.json()
        print(f"Initial milestone definitions count: {len(milestone_defs)}")
        if len(milestone_defs) == 0:
            print(f"{Fore.GREEN}✓ No milestone definitions initially (expected){Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}✗ Found {len(milestone_defs)} milestone definitions initially{Style.RESET_ALL}")
    
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
    milestones_achieved = []
    
    for i, catch_code in enumerate(catch_codes, 1):
        response = make_request("POST", "found_pokemon", {
            "catch_code": catch_code
        }, token)
        
        if response and response.status_code == 200:
            data = response.json()
            print(f"  Pokemon {i}: {data.get('message', 'Registered')}")
            
            # Check both old and new milestone fields
            if data.get('milestone_reached'):
                print(f"{Fore.GREEN}  ✓ MILESTONE REACHED (legacy): {data['milestone_reached']} pokemon!{Style.RESET_ALL}")
                milestone_triggered = True
            
            if data.get('milestones_achieved'):
                for milestone in data['milestones_achieved']:
                    print(f"{Fore.GREEN}  ✓ MILESTONE ACHIEVED: {milestone.get('name', 'Unknown')} - {milestone.get('description', '')}!{Style.RESET_ALL}")
                    milestones_achieved.extend(data['milestones_achieved'])
                    milestone_triggered = True
        else:
            print(f"{Fore.RED}  ✗ Failed to register pokemon {i}{Style.RESET_ALL}")
    
    if milestone_triggered:
        print(f"\n{Fore.GREEN}✓ Milestone system is working correctly!{Style.RESET_ALL}")
        print(f"Total milestones achieved so far: {len(milestones_achieved)}")
    else:
        print(f"\n{Fore.RED}✗ No milestone was triggered (expected at 10 pokemon){Style.RESET_ALL}")
    
    # 5. Check milestones after catching 10 pokemon
    print(f"\n{Fore.YELLOW}5. Checking milestones after catching 10 pokemon...{Style.RESET_ALL}")
    response = make_request("GET", f"user_milestones/{test_user['id']}")
    if response and response.status_code == 200:
        milestones = response.json()
        print(f"Current milestones (legacy): {milestones}")
        if 10 in milestones:
            print(f"{Fore.GREEN}✓ 10-pokemon milestone correctly recorded{Style.RESET_ALL}")
        else:
            print(f"{Fore.RED}✗ 10-pokemon milestone not found{Style.RESET_ALL}")
    
    # Check comprehensive milestone definitions
    response = make_request("GET", f"user_milestone_definitions/{test_user['id']}")
    if response and response.status_code == 200:
        milestone_defs = response.json()
        print(f"\nComprehensive milestones achieved: {len(milestone_defs)}")
        
        # Categorize milestones by type
        count_based = []
        type_based = []
        specific_pokemon = []
        
        for m in milestone_defs:
            milestone_type = m.get('milestone_type', '')
            name = m.get('name', 'Unknown')
            
            if milestone_type == 'CountBased':
                count_based.append(name)
            elif milestone_type == 'TypeBased':
                type_based.append(name)
            elif milestone_type == 'SpecificPokemon':
                specific_pokemon.append(name)
        
        if count_based:
            print(f"  Count-based milestones: {', '.join(count_based)}")
        if type_based:
            print(f"  Type-based milestones: {', '.join(type_based)}")
        if specific_pokemon:
            print(f"  Specific Pokemon milestones: {', '.join(specific_pokemon)}")
    
    # 6. Test multiple milestones at once (e.g., Mew as 151st Pokemon)
    print(f"\n{Fore.YELLOW}6. Testing multiple milestones trigger (catching more Pokemon)...{Style.RESET_ALL}")
    
    # Additional catch codes to test type-based and special milestones
    more_catch_codes = [
        "025e2e1e-e05e-492f-b9a4-02ba9ce58c6f",  # 11 - might be a starter or specific type
        "3b3e87ba-fb48-4b5e-9b7f-c7c3cd956797",  # 12
        # Add more as needed to test different milestone types
    ]
    
    for i, catch_code in enumerate(more_catch_codes, 11):
        response = make_request("POST", "found_pokemon", {
            "catch_code": catch_code
        }, token)
        
        if response and response.status_code == 200:
            data = response.json()
            print(f"  Pokemon {i}: {data.get('message', 'Registered')}")
            
            if data.get('milestones_achieved'):
                print(f"  Multiple milestones achieved in one catch:")
                for milestone in data['milestones_achieved']:
                    print(f"    - {milestone.get('milestone_type', '')}: {milestone.get('name', '')} - {milestone.get('description', '')}")
        else:
            print(f"  ✗ Failed to register pokemon {i}")
    
    # 7. Final milestone check
    print(f"\n{Fore.YELLOW}7. Final comprehensive milestone check...{Style.RESET_ALL}")
    response = make_request("GET", f"user_milestone_definitions/{test_user['id']}")
    if response and response.status_code == 200:
        milestone_defs = response.json()
        print(f"Total milestones achieved: {len(milestone_defs)}")
        
        # Group by type and show summary
        by_type = {}
        for m in milestone_defs:
            m_type = m.get('milestone_type', 'Unknown')
            if m_type not in by_type:
                by_type[m_type] = 0
            by_type[m_type] += 1
        
        for m_type, count in by_type.items():
            print(f"  {m_type}: {count} milestones")
    
    # 8. Clean up - delete test user
    print(f"\n{Fore.YELLOW}8. Cleaning up test user...{Style.RESET_ALL}")
    response = make_request("POST", "admin_delete_user", {
        "id": test_user["id"]
    }, admin_token)
    if response and response.status_code == 200:
        print(f"{Fore.GREEN}✓ Test user deleted{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ Failed to delete test user: {response.text if response else 'No response'}{Style.RESET_ALL}")
    
    print(f"\n{Fore.CYAN}=== Milestone Testing Complete ==={Style.RESET_ALL}")

def test_multiple_milestones_first_catch():
    """Test multiple milestones triggered by catching a dual-type Pokemon."""
    print(f"\n{Fore.CYAN}=== Testing Multiple Milestones (First Dual-Type Pokemon) ==={Style.RESET_ALL}\n")
    
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
        print(f"{Fore.RED}✗ Failed to login as admin{Style.RESET_ALL}")
        return
    
    # 2. Create a fresh test user
    test_user = {
        "id": "multi_milestone_user",
        "name": "Multi Milestone Tester",
        "password": "TestPassword123!"
    }
    
    print(f"\n{Fore.YELLOW}2. Creating test user...{Style.RESET_ALL}")
    response = make_request("POST", "create_user", test_user)
    if response and response.status_code == 200:
        print(f"{Fore.GREEN}✓ User created successfully{Style.RESET_ALL}")
        data = response.json()
        if "token" in data and "encoded_token" in data["token"]:
            token = data["token"]["encoded_token"]
    else:
        print(f"{Fore.RED}✗ Failed to create user{Style.RESET_ALL}")
        return
    
    # 3. Catch Bulbasaur (#1) - which is Grass/Poison type
    # This should trigger multiple milestones:
    # - First Pokemon caught (if that's a milestone)
    # - First Grass type
    # - First Poison type
    # - Possibly a specific Pokemon milestone for Bulbasaur
    print(f"\n{Fore.YELLOW}3. Catching Bulbasaur (Grass/Poison dual-type)...{Style.RESET_ALL}")
    
    bulbasaur_catch_code = "ac3cf629-e151-45a6-a328-5af466cb471d"  # Bulbasaur's catch code
    
    response = make_request("POST", "found_pokemon", {
        "catch_code": bulbasaur_catch_code
    }, token)
    
    if response and response.status_code == 200:
        data = response.json()
        print(f"Caught: {data.get('message', 'Pokemon registered')}")
        
        milestones = data.get('milestones_achieved', [])
        if len(milestones) > 1:
            print(f"\n{Fore.GREEN}✓ Multiple milestones achieved simultaneously!{Style.RESET_ALL}")
            print(f"Total milestones triggered: {len(milestones)}")
            
            for milestone in milestones:
                print(milestone)
                m_type = milestone.get('milestone_type', 'Unknown')
                name = milestone.get('requirement', 'Unknown')
                desc = milestone.get('display_text', 'Unknown')
                print(f"  - [{m_type}] {name}: {desc}")
                
            # Check if we got type-based milestones
            type_milestones = [m for m in milestones if m.get('milestone_type') == 'TypeBased']
            if len(type_milestones) >= 2:
                print(f"\n{Fore.GREEN}✓ Confirmed: Multiple type-based milestones from dual-type Pokemon!{Style.RESET_ALL}")
        else:
            print(f"{Fore.YELLOW}Only {len(milestones)} milestone(s) triggered{Style.RESET_ALL}")
    else:
        print(f"{Fore.RED}✗ Failed to catch Pokemon{Style.RESET_ALL}")
    
    # 4. Check comprehensive milestones
    print(f"\n{Fore.YELLOW}4. Verifying comprehensive milestones...{Style.RESET_ALL}")
    response = make_request("GET", f"user_milestone_definitions/{test_user['id']}")
    if response and response.status_code == 200:
        milestone_defs = response.json()
        print(f"Total milestones achieved: {len(milestone_defs)}")
        
        # Group by type
        by_type = {}
        for m in milestone_defs:
            m_type = m.get('milestone_type', 'Unknown')
            if m_type not in by_type:
                by_type[m_type] = []
            by_type[m_type].append(m.get('requirement', 'Unknown'))
        
        for m_type, names in by_type.items():
            print(f"  {m_type}: {', '.join(names)}")
    
    # 5. Clean up
    print(f"\n{Fore.YELLOW}5. Cleaning up test user...{Style.RESET_ALL}")
    response = make_request("POST", "admin_delete_user", {
        "id": test_user["id"]
    }, admin_token)
    if response and response.status_code == 200:
        print(f"{Fore.GREEN}✓ Test user deleted{Style.RESET_ALL}")
    
    print(f"\n{Fore.CYAN}=== Multiple Milestone Testing Complete ==={Style.RESET_ALL}")
    
if __name__ == "__main__":
    # Note: Make sure the API server is running before executing this test
    print(f"{Fore.YELLOW}Note: This test requires the API server to be running at {BASE_URL}{Style.RESET_ALL}\n")
    
    try:
        test_milestones()
        test_multiple_milestones_first_catch()
    except KeyboardInterrupt:
        print(f"\n{Fore.YELLOW}Test interrupted by user{Style.RESET_ALL}")
    except Exception as e:
        print(f"\n{Fore.RED}Test failed with error: {str(e)}{Style.RESET_ALL}")
        sys.exit(1)