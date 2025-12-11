"""Test script to populate history for testing."""
import requests
import sys

# Since clipboard doesn't work on Linux, we'll test with what we can
# Let's test the history folders endpoint with empty history
response = requests.get('http://localhost:49917/api/history/folders')
print(f"History folders (empty): {response.json()}")

# Test update and delete operations
print("\nTesting snippet operations:")

# Get the SQL snippet ID we created
response = requests.get('http://localhost:49917/api/snippets')
snippets = response.json()
print(f"Current snippets: {len(snippets)} folders")

# Test update snippet
if snippets and snippets[1]['snippets']:  # Code Snippets folder
    snippet_id = snippets[1]['snippets'][0]['clip_id']
    update_data = {
        'name': 'Updated SQL Query',
        'content': 'SELECT * FROM users WHERE active = 1',
        'tags': ['sql', 'query', 'updated']
    }
    response = requests.put(
        f'http://localhost:49917/api/snippets/Code Snippets/{snippet_id}',
        json=update_data
    )
    print(f"Update snippet: {response.json()}")

    # Verify update
    response = requests.get('http://localhost:49917/api/snippets/Code Snippets')
    print(f"Updated snippet: {response.json()[0]['snippet_name']}")

# Test search with updated content
response = requests.get('http://localhost:49917/api/search?q=active')
print(f"\nSearch for 'active': Found {len(response.json()['snippets'])} snippets")

print("\n✅ Snippet operations test complete!")
