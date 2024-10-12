# Vault Secrets Script

## Overview

This script is designed to interact with a HashiCorp Vault server to retrieve and manage secrets. It provides various command-line options to customize its execution based on user needs. This project is particularly useful for security professionals and developers who need to manage sensitive data securely.

## Features

- Connects to a HashiCorp Vault server and retrieves secrets recursively.
- Supports command-line arguments for flexible execution:
  - `--help`: Displays usage information.
  - `--skip`: Skips the main logic and jumps to additional script execution if specific conditions are met.
  - `--noskip`: Ensures the main logic runs even when `--skip` is specified.
  - `--scrape`: Executes a scraping operation to gather secrets from the Vault server.
  - `--encode`: Encrypts all sensitive files found in the specified directories.
  - `--decode`: Decrypts all encrypted files found in the `encrypted_files` directory.
- Outputs retrieved secrets to a file (`vault_secrets.txt`).
- Provides informative messages and error handling.
- Measures execution time for performance monitoring.

## Requirements

- [HashiCorp Vault](https://www.vaultproject.io/) must be installed and configured.
- The `jq` command-line JSON processor must be installed for processing JSON output.
- Python 3 is required for running the `scrap.py` script.
- OpenSSL must be installed for file encryption and decryption.

## Usage

1. **Run the script**:

   ```bash
   ./main.sh [OPTIONS]
   ```

   ### Options:

   - `--help`: Show help message and exit.
   - `--skip`: Skip the main logic and jump to the end of the program.
   - `--noskip`: Ensure the main logic runs.
   - `--scrape`: Scrape the Vault server for secrets.
   - `--encode`: Encrypt all sensitive files.
   - `--decode`: Decrypt all encrypted files.

2. **Enter your Vault token** when prompted.

## Example

- To scrape the vault server for secrets, you can run:

  ```bash
  ./main.sh --noskip
  ```

- To skip the main logic and run the additional scripts:

  ```bash
  ./main.sh --skip
  ```

- To analyse the output, you need to run 

  ```bash
  ./main.sh --scrape
  ```

- To encrypt files:

  ```bash
  ./main.sh --encode
  ```

- To decrypt files:

  ```bash
  ./main.sh --decode
  ```

## Error Handling

- The script provides clear error messages for invalid options or issues connecting to the Vault server.
- Ensure that `vault_secrets.txt` is present in the current directory when using the `--skip` option.
- If files cannot be found during encryption or decryption, appropriate warnings will be displayed.

## Scripts

- `format.sh`: Script for formatting the retrieved secrets.
- `combine.sh`: Script for combining the formatted secrets into a single output.
- `scrap.py`: Python script to scrape the Vault server.

## Contributions

Contributions are welcome! Please submit a pull request or open an issue for any improvements or bug fixes.
