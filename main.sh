


start_time=$(date +%s)

export VAULT_ADDR=CHANGEME
output_file="files/vault_secrets.txt"


GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'



show_help() {
    echo "Usage: $0 [--help] [--skip] [--noskip] [--scrape] [--encode] [--decode]"
    echo
    echo "Options:"
    echo "  --help      Show this help message and exit"
    echo "  --skip      Skip the main logic and jump to the end of the program"
    echo "  --noskip    Ensure the main logic runs"
    echo "  --scrape    Scrape the Vault server for secrets"
    echo "  --encode    Encode all sensitive files"
    echo "  --decode    Decode all sensitive files"
}


if [ $
    show_help
    exit 0
fi


skip=false
noskip=false
scrape=false
encoding=false
decoding=false
for arg in "$@"; do
    case $arg in
        --help)
            show_help
            exit 0
            ;;
        --skip)
            skip=true
            ;;
        --scrape)
            scrape=true
            ;;
        --noskip)
            noskip=true
            ;;
        --encode)
            encoding=true
            ;;
        --decode)
            decoding=true
            ;;
        *)
            echo -e "${RED}[!] Invalid option: $arg${NC}" 1>&2
            show_help
            exit 1
            ;;
    esac
done

trap 'rm -f out.log' EXIT


if [ "$skip" = true ] && [ "$noskip" = false ]; then
    echo -e "${YELLOW}[~] Skipping the main logic as per the --skip option.${NC}"
    
    if [ ! -f "files/vault_secrets.txt" ]; then
        echo -e "${RED}[!] Error: vault_secrets.txt not found, please run the script without the --skip option.${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] File vault_secrets.txt found.${NC}"
        echo -e "${YELLOW}[~] Launching format.sh script.${NC}"
        if ! bash scripts/format.sh > /dev/null 2>&1; then
            echo -e "${RED}[!] Error: format.sh script failed.${NC}"
            exit 1
        fi
        echo -e "${YELLOW}[~] Launching combine.sh script.${NC}"
        if ! bash scripts/combine.sh > /dev/null 2>&1; then
            echo -e "${RED}[!] Error: combine.sh script failed.${NC}"
            exit 1
        fi
        echo -e "${GREEN}[+] All scripts executed successfully, you should find the combined JSON in combined_vault_secrets.json.${NC}"
    fi
    exit 0
fi
    

if [ "$scrape" = true ]; then
    echo -e "${YELLOW}[~] Scraping the Vault server for secrets.${NC}"
    if ! python3 scripts/scrap.py > output/duplicated.log 2>&1; then
        echo -e "${RED}[!] Error: scrap.py script failed.${NC}"
        exit 1
    fi
    sed -i 's/\x1b\[[0-9;]*m//g' output/duplicated.log
    sed -i 's/\x1b\[H//g; s/\x1b\[J//g' output/duplicated.log
    echo -e "${GREEN}[+] Secrets have been scraped from the Vault server.${NC}"
    rm -f files/vault_secrets*
    exit 0
fi

if [ "$encoding" = true ]; then
    
    files_to_encode=$(find output/ files/ -type f)
    read -sp "Enter the password to encrypt the files: " password
    echo
    mkdir -p encrypted_files
    
    
    echo -e "${YELLOW}[~] The following files will be encrypted:${NC}"
    echo "$files_to_encode"
    
    
    read -p "Are you sure you want to encrypt these files with the provided password? Type 'yes' to confirm: " confirmation
    echo
    
    
    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${RED}[!] Operation cancelled.${NC}"
        exit 1
    fi
    for file in $files_to_encode; do
        openssl enc -aes-256-cbc -salt -pbkdf2 -in "$file" -out "encrypted_files/$(basename "$file").enc" -k "$password"
        rm -f $file
    done

    echo -e "${GREEN}[+] All files have been encrypted.${NC}"
    exit 0
fi

if [ "$decoding" = true ]; then
    
    files_to_decode=$(find encrypted_files/ -type f)
    read -sp "Enter the password to decrypt the files: " password
    echo
    mkdir -p decrypted_files
    
    
    echo -e "${YELLOW}[~] The following files will be decrypted:${NC}"
    echo "$files_to_decode"
    
    
    read -p "Are you sure you want to decrypt these files with the provided password? Type 'yes' to confirm: " confirmation
    echo
    
    
    if [[ "$confirmation" != "yes" ]]; then
        echo -e "${RED}[!] Operation cancelled.${NC}"
        exit 1
    fi

    
    for file in $files_to_decode; do
        openssl enc -d -aes-256-cbc -salt -pbkdf2 -in "$file" -out "decrypted_files/$(basename "$file" .enc)" -pass pass:"$password"
    done
    
    echo -e "${GREEN}[+] Files have been decrypted and saved to the decrypted_files directory.${NC}"
    exit 0
fi


read -sp "Enter your Vault token: " VAULT_TOKEN
echo
export VAULT_TOKEN


vault status > /dev/null 2>&1


if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] Connection to Vault server successful.${NC}"
else
    echo -e "${RED}[!] Error: Unable to connect to Vault server.${NC}"
    exit 1
fi

current_user=$(vault token lookup | grep -m1 "display_name" | awk '{print $2}')
echo -e "${YELLOW}[~] Current user in Vault: ${current_user}${NC}"


fetch_secrets() {
    local path=$1
    local subprojects=$(vault kv list -format=json "$path" | jq -r '.[]')

    if [ -z "$subprojects" ]; then
        return
    fi

    for subproject in $subprojects; do
        local full_path="$path/$subproject"
        
        if secret=$(vault kv get -format=json "$full_path" 2>/dev/null); then
            echo -e "Path: $full_path\n$(echo "$secret" | jq .)"
            echo ""
        fi

        
        fetch_secrets "$full_path" & 
    done
    wait  
}


projects=$(vault kv list -format=json "secret/" | jq -r '.[]')

for project in $projects; do
    fetch_secrets "secret/$project" &  
done

wait  

end_time=$(date +%s)
execution_time=$((end_time - start_time))

echo -e "${GREEN}[+] Secrets have been written to $output_file.${NC}"
echo -e "${YELLOW}[~] Time taken: ${execution_time} seconds.${NC}"
