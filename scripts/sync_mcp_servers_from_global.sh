#!/bin/bash
# ABOUTME: Extracts mcpServers from global Claude config (~/.claude.json) to this repo
# ABOUTME: Replaces API keys in env fields with variable references and stores actual values in .env file

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
echo "Extracting API keys from env fields to $REPO_ENV_FILE..."

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

try:
    # Read global Claude config
    with open(global_file, 'r') as f:
        data = json.load(f)

    mcp_servers = data.get('mcpServers', {})

    # Extract environment variables and replace them with variable references
    env_vars = {}

    for server_name, server_config in mcp_servers.items():
        if 'env' in server_config and isinstance(server_config['env'], dict):
            for key, value in server_config['env'].items():
                # Create env var name with server name prefix for clarity
                env_key = f"{server_name.upper()}_{key}"
                env_vars[env_key] = value

                # Replace the actual value with a variable reference ${ENV_VAR_NAME}
                server_config['env'][key] = f"${{{env_key}}}"

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
