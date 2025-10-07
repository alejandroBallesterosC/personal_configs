#!/bin/bash
# ABOUTME: Extracts mcpServers from global Claude config (~/.claude.json) to this repo
# ABOUTME: Replaces API keys in env/headers fields with variable references and stores actual values in .env file

set -e

# Define paths
GLOBAL_CLAUDE_FILE="$HOME/.claude.json"
REPO_MCP_SETTINGS_FILE="$(dirname "$0")/../claude-code/global_mcp_settings.json"
REPO_ENV_FILE="$(dirname "$0")/../.env"

# Check if global Claude file exists
if [ ! -f "$GLOBAL_CLAUDE_FILE" ]; then
    echo "Error: Global Claude configuration not found at $GLOBAL_CLAUDE_FILE"
    exit 1
fi

# Create repo claude-code directory if it doesn't exist
REPO_CLAUDE_DIR="$(dirname "$0")/../claude-code"
mkdir -p "$REPO_CLAUDE_DIR"

# Extract mcpServers key, replace API keys with variable references, and save them to .env
echo "Extracting mcpServers from $GLOBAL_CLAUDE_FILE..."
echo "Extracting API keys from env/headers fields to $REPO_ENV_FILE..."

if command -v python3 &> /dev/null; then
    # Export environment variables for Python script
    export GLOBAL_CLAUDE_FILE
    export REPO_MCP_SETTINGS_FILE
    export REPO_ENV_FILE

    python3 << 'PYTHON_SCRIPT'
import json
import os
import re
import sys

global_file = os.environ['GLOBAL_CLAUDE_FILE']
repo_file = os.environ['REPO_MCP_SETTINGS_FILE']
env_file = os.environ['REPO_ENV_FILE']

def create_env_key(server_name, field_key):
    """Create a clean environment variable name"""
    # Convert server name to uppercase
    server_upper = server_name.upper().replace('-', '_')
    field_upper = field_key.upper().replace('-', '_')

    # Check if the field key already starts with server name (to avoid duplication)
    # e.g., if server is "context7" and field is "CONTEXT7_API_KEY", don't duplicate
    if field_upper.startswith(server_upper + '_'):
        return field_upper
    else:
        return f"{server_upper}_{field_upper}"

def extract_and_replace_secrets(obj, server_name, env_vars, path=""):
    """Recursively find and replace API keys/tokens in nested dictionaries"""
    if isinstance(obj, dict):
        for key, value in obj.items():
            current_path = f"{path}.{key}" if path else key

            if isinstance(value, str):
                # Check if this looks like a secret (contains keywords)
                secret_keywords = ['key', 'token', 'secret', 'password', 'auth', 'bearer', 'api']
                if any(keyword in key.lower() for keyword in secret_keywords):
                    # Handle "Bearer TOKEN" pattern
                    bearer_match = re.match(r'^Bearer\s+(.+)$', value, re.IGNORECASE)
                    if bearer_match:
                        actual_token = bearer_match.group(1)
                        # Don't re-extract if already a variable reference
                        if not actual_token.startswith('${'):
                            env_key = create_env_key(server_name, key)
                            env_vars[env_key] = actual_token
                            obj[key] = f"Bearer ${{{env_key}}}"
                    # Handle direct values that aren't already variable references
                    elif not value.startswith('${'):
                        env_key = create_env_key(server_name, key)
                        env_vars[env_key] = value
                        obj[key] = f"${{{env_key}}}"
            elif isinstance(value, dict):
                extract_and_replace_secrets(value, server_name, env_vars, current_path)
            elif isinstance(value, list):
                for item in value:
                    if isinstance(item, dict):
                        extract_and_replace_secrets(item, server_name, env_vars, current_path)

try:
    # Read global Claude config
    with open(global_file, 'r') as f:
        data = json.load(f)

    mcp_servers = data.get('mcpServers', {})

    # Extract environment variables and replace them with variable references
    env_vars = {}

    for server_name, server_config in mcp_servers.items():
        # Process env field
        if 'env' in server_config and isinstance(server_config['env'], dict):
            extract_and_replace_secrets(server_config['env'], server_name, env_vars)

        # Process headers field
        if 'headers' in server_config and isinstance(server_config['headers'], dict):
            extract_and_replace_secrets(server_config['headers'], server_name, env_vars)

    # Write the MCP servers config with variable references
    with open(repo_file, 'w') as f:
        json.dump({'mcpServers': mcp_servers}, f, indent=2)

    # Read existing .env file if it exists
    existing_env = {}
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    existing_env[key.strip()] = value.strip()

    # Merge new env vars with existing ones (new ones take precedence)
    existing_env.update(env_vars)

    # Write all env vars to .env file
    with open(env_file, 'w') as f:
        for key, value in sorted(existing_env.items()):
            f.write(f"{key}={value}\n")

    if env_vars:
        print(f"Successfully extracted {len(env_vars)} environment variable(s) to .env")
        print(f"Extracted variables: {', '.join(env_vars.keys())}")
    else:
        print("No environment variables found in MCP server configurations")

    print(f"Successfully extracted mcpServers configuration using python")

except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        echo "Sync complete! MCP servers saved to $REPO_MCP_SETTINGS_FILE"
        echo "Environment variables saved to $REPO_ENV_FILE"
    else
        echo "Error: Failed to process MCP servers configuration"
        exit 1
    fi
else
    echo "Error: python3 is required for this script but is not available."
    exit 1
fi
