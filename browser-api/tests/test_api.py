#!/usr/bin/env python3
"""
Browser API Tests
"""

import requests
import time
import sys

# API base URL
BASE_URL = "http://localhost:8083"


def print_section(title: str):
    """Print section header"""
    print(f"\n{'=' * 50}")
    print(f" {title}")
    print('=' * 50)


def test_health():
    """Test health endpoint"""
    print_section("1. Health Check")

    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        assert response.status_code == 200
        print("✅ Health check passed")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False


def test_open_url():
    """Test opening a URL"""
    print_section("2. Open URL")

    try:
        response = requests.post(
            f"{BASE_URL}/open",
            json={"url": "https://www.google.com"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        assert response.status_code == 200
        assert response.json()["success"] == True
        print("✅ Open URL passed")
        time.sleep(2)  # Wait for page to load
        return True
    except Exception as e:
        print(f"❌ Open URL failed: {e}")
        return False


def test_snapshot():
    """Test getting page snapshot"""
    print_section("3. Snapshot")

    try:
        response = requests.get(f"{BASE_URL}/snapshot")
        print(f"Status: {response.status_code}")
        data = response.json()
        print(f"URL: {data.get('url')}")
        print(f"Title: {data.get('title')}")
        print(f"Elements found: {len(data.get('elements', []))}")
        if data.get('elements'):
            print(f"Sample elements:")
            for elem in data['elements'][:3]:
                print(f"  - {elem['ref']}: {elem['tag']} - {elem['name'][:50]}")
        assert response.status_code == 200
        assert data["success"] == True
        print("✅ Snapshot passed")
        return True
    except Exception as e:
        print(f"❌ Snapshot failed: {e}")
        return False


def test_screenshot():
    """Test taking screenshot"""
    print_section("4. Screenshot")

    try:
        response = requests.post(
            f"{BASE_URL}/screenshot",
            json={"path": "/app/screenshots/test_screenshot.png"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        assert response.status_code == 200
        assert response.json()["success"] == True
        print("✅ Screenshot passed")
        return True
    except Exception as e:
        print(f"❌ Screenshot failed: {e}")
        return False


def test_search_and_fill():
    """Test searching on Google"""
    print_section("5. Search and Fill")

    try:
        # Fill search box
        response = requests.post(
            f"{BASE_URL}/fill",
            json={
                "selector": "textarea[name='q']",
                "value": "Cinderella Browser API"
            }
        )
        print(f"Fill status: {response.status_code}")
        print(f"Fill response: {response.json()}")
        assert response.status_code == 200
        assert response.json()["success"] == True
        print("✅ Fill passed")

        time.sleep(1)

        # Take screenshot after fill
        response = requests.post(
            f"{BASE_URL}/screenshot",
            json={"path": "/app/screenshots/test_after_fill.png"}
        )
        assert response.status_code == 200
        print("✅ Screenshot after fill passed")

        return True
    except Exception as e:
        print(f"❌ Search and fill failed: {e}")
        return False


def test_get_text():
    """Test getting text from element"""
    print_section("6. Get Text")

    try:
        response = requests.get(
            f"{BASE_URL}/text",
            params={"selector": "title"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        assert response.status_code == 200
        assert response.json()["success"] == True
        print("✅ Get text passed")
        return True
    except Exception as e:
        print(f"❌ Get text failed: {e}")
        return False


def test_navigate_to_wikipedia():
    """Test navigating to Wikipedia"""
    print_section("7. Navigate to Wikipedia")

    try:
        response = requests.post(
            f"{BASE_URL}/open",
            json={"url": "https://ja.wikipedia.org/wiki/%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%9A%E3%83%BC%E3%82%B8"}
        )
        print(f"Status: {response.status_code}")
        data = response.json()
        print(f"Title: {data.get('title')}")
        assert response.status_code == 200
        assert data["success"] == True
        print("✅ Navigate to Wikipedia passed")

        time.sleep(2)

        # Take screenshot
        response = requests.post(
            f"{BASE_URL}/screenshot",
            json={"path": "/app/screenshots/test_wikipedia.png"}
        )
        assert response.status_code == 200
        print("✅ Screenshot of Wikipedia passed")

        return True
    except Exception as e:
        print(f"❌ Navigate to Wikipedia failed: {e}")
        return False


def test_close():
    """Test closing browser"""
    print_section("8. Close Browser")

    try:
        response = requests.post(f"{BASE_URL}/close")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        assert response.status_code == 200
        assert response.json()["success"] == True
        print("✅ Close browser passed")
        return True
    except Exception as e:
        print(f"❌ Close browser failed: {e}")
        return False


def main():
    """Run all tests"""
    print("\n" + "=" * 50)
    print(" Cinderella Browser API Tests")
    print("=" * 50)
    print(f"API URL: {BASE_URL}")
    print("=" * 50)

    tests = [
        ("Health Check", test_health),
        ("Open URL", test_open_url),
        ("Snapshot", test_snapshot),
        ("Screenshot", test_screenshot),
        ("Search and Fill", test_search_and_fill),
        ("Get Text", test_get_text),
        ("Navigate to Wikipedia", test_navigate_to_wikipedia),
        ("Close Browser", test_close),
    ]

    results = []
    for name, test_func in tests:
        try:
            result = test_func()
            results.append((name, result))
        except Exception as e:
            print(f"❌ Test '{name}' crashed: {e}")
            results.append((name, False))
        time.sleep(0.5)

    # Summary
    print_section("Test Summary")
    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {name}")

    print(f"\nTotal: {passed}/{total} tests passed")

    if passed == total:
        print("\n🎉 All tests passed!")
        return 0
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
        return 1


if __name__ == "__main__":
    sys.exit(main())
