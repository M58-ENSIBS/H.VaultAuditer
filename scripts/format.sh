input_file="files/vault_secrets.txt"
output_file="files/vault_secrets_with_paths.txt"

while IFS= read -r line; do
    if [[ $line == Path:* ]]; then
        current_path=$(echo "$line" | awk '{print $2}')
    elif [[ $line == '{' ]]; then
        json_content=""
        json_content+="$line"$'\n'

        while IFS= read -r sub_line && [[ $sub_line != '}' ]]; do
            json_content+="$sub_line"$'\n'
        done
        json_content+="}$'\n'"
        updated_json=$(echo "$json_content" | jq --arg path "$current_path" '. | {path: $path} + .')

        echo "$updated_json" >> "$output_file"
    fi
done < "$input_file"

echo "Updated file with paths saved to files/$output_file"
