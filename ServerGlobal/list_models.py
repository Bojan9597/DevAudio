import os
import requests
from dotenv import load_dotenv

# Load environment variables from .env file
script_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(script_dir, '.env')
load_dotenv(env_path)

def list_models():
    api_key = os.getenv('GEMINI_API_KEY')
    
    if not api_key:
        print("Error: GEMINI_API_KEY not found in environment variables or .env file.")
        print("Please add GEMINI_API_KEY=your_key_here to your .env file.")
        return

    url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        
        data = response.json()
        models = data.get('models', [])
        
        if not models:
            print("No models found.")
            return

        with open('found_models.txt', 'w') as f:
            f.write(f"Found {len(models)} models total.\n")
            f.write("Filtering for 'gemini':\n")
            f.write("-" * 50 + "\n")
            count = 0
            for model in models:
                if 'gemini' in model['name'].lower():
                    f.write(f"{model['name']}\n")
                    print(model['name'])
                    count += 1
            f.write("-" * 50 + "\n")
            f.write(f"Total gemini models found: {count}\n")
            
    except requests.exceptions.HTTPError as e:
        print(f"HTTP Error: {e}")
        if response.status_code == 400:
            print("Check if your API Key is correct and has the necessary permissions.")
        print(f"Response Body: {response.text}")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    list_models()
