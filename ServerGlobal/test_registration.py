import requests
import json
import random

BASE_URL = "http://127.0.0.1:5000"

def test_registration():
    email = f"test_{random.randint(1000,9999)}@example.com"
    
    # 1. Weak Password
    print("Testing Weak Password...")
    res = requests.post(f"{BASE_URL}/register", json={
        "name": "Test User",
        "email": email,
        "password": "password",
        "confirm_password": "password"
    })
    # Response might be 400 with specific error message
    if res.status_code == 400 and ("at least 8 characters" in res.text or "Password must be" in res.text):
        print("PASS: Weak Password rejected")
    else:
        print(f"FAIL: Weak Password response: {res.status_code} {res.text}")

    # 2. Mismatched Passwords
    print("Testing Mismatched Passwords...")
    res = requests.post(f"{BASE_URL}/register", json={
        "name": "Test User",
        "email": email,
        "password": "Password1!",
        "confirm_password": "Password1@"
    })
    if res.status_code == 400 and "Passwords do not match" in res.text:
        print("PASS: Mismatched Passwords rejected")
    else:
        print(f"FAIL: Mismatched Passwords response: {res.status_code} {res.text}")

    # 3. Valid Password
    print("Testing Valid Password...")
    res = requests.post(f"{BASE_URL}/register", json={
        "name": "Test User",
        "email": email,
        "password": "Password1!",
        "confirm_password": "Password1!"
    })
    # Expect 201 or 202 (Verification code sent)
    if res.status_code in [201, 202]:
        print("PASS: Valid Registration accepted")
    else:
        print(f"FAIL: Valid Registration response: {res.status_code} {res.text}")

if __name__ == "__main__":
    try:
        test_registration()
    except Exception as e:
        print(f"ERROR: {e}")
