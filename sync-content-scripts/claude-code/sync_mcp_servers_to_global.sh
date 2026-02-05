#!/bin/bash
# ABOUTME: Merges mcpServers from repo (claude-code/global_mcp_settings.json) into global Claude config
# ABOUTME: Resolves environment variable references from .env and replaces them with actual values

set -e

# Define paths
REPO_MCP_SETTINGS_FILE="$(dirname "$0")/../../claude-code/global_mcp_settings.json"
REPO_ENV_FILE="$(dirname "$0")/../../.env"
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

def resolve_variable_references(obj, env_vars):
    """Recursively resolve ${VAR} references in nested dictionaries and strings"""
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(value, str):
                # Handle "Bearer ${TOKEN}" pattern
                bearer_match = re.match(r'^(Bearer\s+)?\$\{([^}]+)\}$', value, re.IGNORECASE)
                if bearer_match:
                    prefix = bearer_match.group(1) or ""
                    var_name = bearer_match.group(2)
                    if var_name in env_vars:
                        if prefix:
                            obj[key] = f"{prefix}{env_vars[var_name]}"
                        else:
                            obj[key] = env_vars[var_name]
                    else:
                        print(f"Warning: Environment variable {var_name} not found in .env file", file=sys.stderr)
                else:
                    # Handle inline ${VAR} references within strings
                    def replace_var(match):
                        var_name = match.group(1)
                        if var_name in env_vars:
                            return env_vars[var_name]
                        else:
                            print(f"Warning: Environment variable {var_name} not found in .env file", file=sys.stderr)
                            return match.group(0)

                    obj[key] = re.sub(r'\$\{([^}]+)\}', replace_var, value)
            elif isinstance(value, dict):
                resolve_variable_references(value, env_vars)
            elif isinstance(value, list):
                for item in value:
                    if isinstance(item, dict):
                        resolve_variable_references(item, env_vars)

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

    # Resolve environment variable references in all fields
    resolved_count = 0
    original_count = 0

    for server_name, server_config in mcp_servers.items():
        # Count original variable references
        config_str = json.dumps(server_config)
        original_count += len(re.findall(r'\$\{[^}]+\}', config_str))

        # Process env field
        if 'env' in server_config and isinstance(server_config['env'], dict):
            resolve_variable_references(server_config['env'], env_vars)

        # Process headers field
        if 'headers' in server_config and isinstance(server_config['headers'], dict):
            resolve_variable_references(server_config['headers'], env_vars)

    # Count resolved references
    config_str = json.dumps(mcp_servers)
    remaining_count = len(re.findall(r'\$\{[^}]+\}', config_str))
    resolved_count = original_count - remaining_count

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
    if remaining_count > 0:
        print(f'Warning: {remaining_count} variable reference(s) could not be resolved', file=sys.stderr)
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
