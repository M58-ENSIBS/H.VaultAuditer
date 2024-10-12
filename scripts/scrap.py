import json
from collections import defaultdict
from password_strength import PasswordStats
import subprocess

def red(text):
    return f"\033[91m{text}\033[00m"

def yellow(text):
    return f"\033[93m{text}\033[00m"

def reset(text):
    return f"\033[00m{text}\033[00m"

def clear_screen():
    print("\033[H\033[J")

def find_duplicate_values(json_file):
    
    def extract_values(obj, values):
        if isinstance(obj, dict):
            
            if "data" in obj and isinstance(obj["data"], dict) and "data" in obj["data"]:
                
                nested_data = obj["data"]["data"]
                if isinstance(nested_data, dict):
                    for key, value in nested_data.items():
                        if isinstance(value, (str, int, float, bool, type(None))):
                            
                            full_path = obj['path'] + f"/{key}"
                            values.append((key, value, full_path))
            else:
                
                for key, value in obj.items():
                    extract_values(value, values)
        elif isinstance(obj, list):
            for index, item in enumerate(obj):
                extract_values(item, values)

    
    with open(json_file, 'r') as file:
        data = json.load(file)

    
    all_values = []
    extract_values(data, all_values)

    
    duplicates = defaultdict(list)
    seen = set()

    for key, value, path in all_values:
        if value in seen:
            duplicates[value].append((key, path))
        else:
            seen.add(value)

    
    if duplicates:
        print("Duplicate values found:")
        total_duplicates = 0
        for value, key_paths in duplicates.items():
            if len(key_paths) > 1:  
                sensitive_keywords = ["password", "token", "secret", "key"]
                warning_printed = False
                environments = {"dev": False, "stage": False, "prod": False}

                for _, path in key_paths:
                    if "secret/dev" in path:
                        environments["dev"] = True
                    if "secret/stage" in path:
                        environments["stage"] = True
                    if "secret/prod" in path:
                        environments["prod"] = True

                
                if (
                    (environments["dev"] and environments["stage"] and environments["prod"]) or
                    (environments["dev"] and environments["prod"]) or
                    (environments["stage"] and environments["prod"])
                ):
                    
                    if not warning_printed and any(any(keyword in key.lower() for keyword in sensitive_keywords) for key, path in key_paths):
                        print(red("WARNING: Sensible duplicate found!"))
                        warning_printed = True  

                    print("-------------------")
                    try: 
                        strength = PasswordStats(value).strength()
                        if strength < 0.5:
                            print(f"Value: {value} - Occurrences: {len(key_paths)} - Password Strength: {red(strength)}")
                        else:
                            print(f"Value: {value} - Occurrences: {len(key_paths)} - Password Strength: {yellow(strength)}")
                    except:
                        print(f"Value: {value} - Occurrences: {len(key_paths)}")

                    for key, path in key_paths:
                        print(f"Key: {key}, Path: {path}")
                    print("-------------------\n")
                    total_duplicates += len(key_paths)
        print(f"Total number of duplicated secrets: {total_duplicates}")
    else:
        print("No duplicate values found.")

if __name__ == "__main__":
    subprocess.run(["rm", " files/vault_secrets*"])
    clear_screen()
    json_file = "files/combined_vault_secrets.json"
    find_duplicate_values(json_file)
