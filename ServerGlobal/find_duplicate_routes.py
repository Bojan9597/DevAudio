import re
from collections import defaultdict

def find_duplicates(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find @app.route('...')
    # Handles single/double quotes, and methods argument
    route_pattern = re.compile(r"@app\.route\s*\(\s*['\"]([^'\"]+)['\"]")
    
    routes = []
    lines = content.split('\n')
    
    for i, line in enumerate(lines):
        match = route_pattern.search(line)
        if match:
            route = match.group(1)
            routes.append({'route': route, 'line': i + 1})

    # Find duplicates
    route_map = defaultdict(list)
    for r in routes:
        route_map[r['route']].append(r['line'])

    duplicates = {k: v for k, v in route_map.items() if len(v) > 1}
    
    if duplicates:
        print("Found duplicate routes:")
        for route, lines in duplicates.items():
            print(f"Route '{route}' found on lines: {lines}")
    else:
        print("No duplicate routes found.")

if __name__ == "__main__":
    find_duplicates('c:\\Users\\bojan\\Desktop\\TrainingFlutter\\ServerGlobal\\api.py')
