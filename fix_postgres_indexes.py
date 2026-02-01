import re

def fix_indexes(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find CREATE INDEX and CREATE UNIQUE INDEX
    # CREATE INDEX "book_id" ON "favorites" ("book_id");
    # CREATE UNIQUE INDEX "code" ON "badges" ("code");
    
    # We will replace "index_name" with "table_index_name" to ensure uniqueness
    
    def replacer(match):
        prefix = match.group(1) # CREATE [UNIQUE] INDEX
        index_name = match.group(2)
        table_name = match.group(3)
        rest = match.group(4)
        
        # New index name: idx_tablename_indexname (sanitize just in case)
        new_index_name = f"idx_{table_name}_{index_name}"
        # If original name already had idx_, avoid double idx_? 
        # But actually simple concatenation is safer for uniqueness. 
        # "book_id" -> "idx_favorites_book_id"
        
        return f'{prefix} "{new_index_name}" ON "{table_name}"{rest}'

    # Pattern:
    # Group 1: CREATE (UNIQUE )?INDEX
    # Group 2: "name" (without quotes)
    # Group 3: "table" (without quotes)
    # Group 4: rest of the string
    
    # Note: re.IGNORECASE might be needed for CREATE INDEX keywords
    pattern = r'(CREATE\s+(?:UNIQUE\s+)?INDEX)\s+"([^"]+)"\s+ON\s+"([^"]+)"(.*)'
    
    output_lines = []
    lines = content.split('\n')
    for line in lines:
        # Check if line matches create index
        if re.search(r'CREATE\s+(?:UNIQUE\s+)?INDEX', line, re.IGNORECASE):
            new_line = re.sub(pattern, replacer, line, flags=re.IGNORECASE)
            output_lines.append(new_line)
        else:
            output_lines.append(line)
            
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(output_lines))
    
    print(f"Processed {file_path}. Fixed duplicate index names.")

if __name__ == "__main__":
    fix_indexes(r'c:\Users\bojan\Desktop\TrainingFlutter\velorusb_DevAudio_pg.sql')
