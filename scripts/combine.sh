

input_file="files/vault_secrets_with_paths.txt"
output_file="files/combined_vault_secrets.json"


echo "[" > "$output_file"


first=true
while IFS= read -r line; do
    if [[ $line == '{' ]]; then
        if [ "$first" = true ]; then
            first=false
        else
            
            echo "," >> "$output_file"
        fi
    fi
    
    echo "$line" >> "$output_file"
done < "$input_file"


echo "]" >> "$output_file"

echo "Combined JSON saved to files/$output_file"
