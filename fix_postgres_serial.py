import re

def fix_serial(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Replace "id" INTEGER NOT NULL with "id" SERIAL
    # and "id" BIGINT NOT NULL with "id" BIGSERIAL
    # Be careful to match only the column definition "id", not "something_id"
    
    # Regex:
    # Look for line starting with whitespace, then "id", then whitespace, then INTEGER or BIGINT, then NOT NULL
    # Note: The file uses double quotes for identifiers
    
    content = re.sub(r'^\s+"id"\s+INTEGER\s+NOT\s+NULL', '  "id" SERIAL', content, flags=re.MULTILINE)
    content = re.sub(r'^\s+"id"\s+BIGINT\s+NOT\s+NULL', '  "id" BIGSERIAL', content, flags=re.MULTILINE)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Processed {file_path}. Converted id columns to SERIAL/BIGSERIAL.")

if __name__ == "__main__":
    fix_serial(r'c:\Users\bojan\Desktop\TrainingFlutter\velorusb_DevAudio_pg.sql')
