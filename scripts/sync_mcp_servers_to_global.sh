#!/bin/bash
# ABOUTME: Merges mcpServers from repo (claude-code/global_mcp_settings.json) into global Claude config
# ABOUTME: Resolves environment variable references from .env and replaces them with actual values

set -e

# Define paths
REPO_MCP_SETTINGS_FILE="$(dirname "$0")/../claude-code/global_mcp_settings.json"
REPO_ENV_FILE="$(dirname "$0")/../.env"
GLOBAL_CLAUDE_FILE="$HOME/.claude.json"

# Check if repo MCP settings file exists
if [ ! -f "$REPO_MCP_SETTINGS_FILE" ]; then
    echo "Error: Repo MCP settings file not found at $REPO_MCP_SETTINGS_FILE"
    exit 1
fi

# Check if global Claude file exists
if [ ! -f "$GLOBAL_CLAUDE_FILE" ]; then
    echo "Error: Global Claude configuration not found at $GLOBAL_CLAUDE_FILE"
    exit 1
fi

# Check if .env file exists
if [ ! -f "$REPO_ENV_FILE" ]; then
    echo "Warning: .env file not found at $REPO_ENV_FILE"
    echo "Will sync MCP servers without resolving environment variables"
fi

# Merge mcpServers key into global config, resolving env vars from .env
echo "Merging mcpServers from $REPO_MCP_SETTINGS_FILE into $GLOBAL_CLAUDE_FILE..."
if [ -f "$REPO_ENV_FILE" ]; then
    echo "Resolving environment variables from $REPO_ENV_FILE..."
fi

if command -v python3 &> /dev/null; then
    # Export environment variables for Python script
    export REPO_MCP_SETTINGS_FILE
    export REPO_ENV_FILE
    export GLOBAL_CLAUDE_FILE

    python3 << 'PYTHON_SCRIPT'
import json
import os
import re
import sys

repo_file = os.environ['REPO_MCP_SETTINGS_FILE']
env_file = os.environ['REPO_ENV_FILE']
global_file = os.environ['GLOBAL_CLAUDE_FILE']

try:
    # Read .env file if it exists
    env_vars = {}
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key.strip()] = value.strip()

    # Read repo MCP settings
    with open(repo_file, 'r') as f:
        repo_data = json.load(f)

    mcp_servers = repo_data.get('mcpServers', {})

    # Resolve environment variable references in env fields
    resolved_count = 0
    for server_name, server_config in mcp_servers.items():
        if 'env' in server_config and isinstance(server_config['env'], dict):
            for key, value in server_config['env'].items():
                # Check if value is a variable reference like ${VAR_NAME}
                if isinstance(value, str):
                    match = re.match(r'\$\{([^}]+)\}', value)
                    if match:
                        var_name = match.group(1)
                        if var_name in env_vars:
                            server_config['env'][key] = env_vars[var_name]
                            resolved_count += 1
                        else:
                            print(f"Warning: Environment variable {var_name} not found in .env file", file=sys.stderr)

    # Read global Claude config
    with open(global_file, 'r') as f:
        global_data = json.load(f)

    # Overwrite mcpServers key
    global_data['mcpServers'] = mcp_servers

    # Write back to global file
    with open(global_file, 'w') as f:
        json.dump(global_data, f, indent=2)

    if resolved_count > 0:
        print(f'Successfully resolved {resolved_count} environment variable(s)')
    print('Successfully merged mcpServers configuration using python')

except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        echo "Sync complete! MCP servers merged into $GLOBAL_CLAUDE_FILE"
    else
        echo "Error: Failed to merge MCP servers configuration"
        exit 1
    fi
else
    echo "Error: python3 is required for this script but is not available."
    exit 1
fi
