# Local Dev Start Script

Starts the backend and frontend locally with environment variables resolved from either **AWS Secrets Manager** or **`.env` files**. All variable definitions, sources, and AWS settings live in a single TOML config — the shell script contains no hardcoded variable names.

## Quick Start

```bash
# From .env files (default)
.vscode/scripts/start-local.sh

# From AWS Secrets Manager
.vscode/scripts/start-local.sh --aws

# Sync dependencies first
.vscode/scripts/start-local.sh --sync
```

Flags can be combined: `.vscode/scripts/start-local.sh --aws --sync`

## Files

| File | Role |
|---|---|
| `start-local.sh` | Orchestrator — parses args, calls the resolver, validates, launches processes |
| `env_var_config.toml` | Declares AWS settings, sources, and every environment variable |
| `_resolve_env.py` | Reads the TOML, resolves values from AWS secrets or `.env` files, outputs grouped exports |
| `test_resolve_env.sh` | Test suite for the resolver (71 assertions) |

## How It Works

```
start-local.sh
  │
  ├─ --env mode (default)
  │    └─ _resolve_env.py --env
  │         reads .env files defined in [sources]
  │
  └─ --aws mode
       ├─ _resolve_env.py --list-aws-sources
       │    outputs profile, env_prefix, and secret IDs from [aws] + [sources]
       ├─ aws secretsmanager get-secret-value  (one call per source)
       └─ _resolve_env.py --aws --secrets-dir <tmpdir>
            reads the fetched JSON files

  Resolver outputs:
      ### BACKEND ###
      export VAR='value'
      ### FRONTEND ###
      export VAR='value'
      ### MISSING ###
      VAR_NAME

  start-local.sh then:
    1. Fails if any vars are MISSING
    2. Launches backend in a subshell with only BACKEND exports
    3. Launches frontend in a subshell with only FRONTEND exports
```

## Config Reference (`env_var_config.toml`)

### `[aws]` — AWS Secrets Manager settings

```toml
[aws]
profile = "oleum-demos"        # AWS CLI profile used with --aws mode
project_name = "obsidian-bi"   # First segment of the secret ID
env_prefix = "dev-staging"     # Second segment (e.g. environment name)
```

Secret IDs are built as `project_name/env_prefix/secret_name`, e.g. `obsidian-bi/dev-staging/mongodb`.

### `[sources.<name>]` — Where variables come from

Each source maps to an AWS secret and/or a `.env` file. Both fields are optional — define whichever modes you need.

```toml
[sources.mongodb]
secret_name = "mongodb"       # Used in --aws mode → fetches obsidian-bi/dev-staging/mongodb
env_file = "backend/.env"     # Used in --env mode → reads backend/.env
```

### `[vars.<NAME>]` — Variable definitions

Every variable needs a `target` field: `"backend"`, `"frontend"`, or `"both"`.

**Source variable** — pulls a value from a source (AWS secret JSON key or `.env` file):

```toml
[vars.MONGODB_URI]
source = "mongodb"           # Which source to read from
aws_secret_key = "uri"       # JSON key within the AWS secret (--aws mode)
target = "backend"           # Only passed to the backend process
```

In `--env` mode, the variable name (`MONGODB_URI`) is looked up directly in the source's `.env` file. The `aws_secret_key` field is only used in `--aws` mode.

**Template variable** — interpolates `{VAR_NAME}` placeholders from already-resolved variables:

```toml
[vars.AUTH0_ISSUER]
template = "https://{AUTH0_DOMAIN}/"
target = "backend"
```

Templates always compute from resolved values. They are evaluated after all source variables, so any source var can be referenced.

### Target isolation

Variables are grouped by `target` and only exported to the relevant subprocess:

- `"backend"` — only available in the backend subshell
- `"frontend"` — only available in the frontend subshell
- `"both"` — exported to both

## Adding a New Variable

1. If the variable comes from a new service, add a source:
   ```toml
   [sources.stripe]
   secret_name = "stripe"
   env_file = "backend/.env"
   ```

2. Add the variable:
   ```toml
   [vars.STRIPE_SECRET_KEY]
   source = "stripe"
   aws_secret_key = "secret_key"
   target = "backend"
   ```

3. If you need a derived variable:
   ```toml
   [vars.STRIPE_WEBHOOK_URL]
   template = "https://hooks.example.com/{STRIPE_SECRET_KEY}"
   target = "backend"
   ```

No changes to `start-local.sh` or `_resolve_env.py` are needed.

## Ports

Defaults are `8000` (backend) and `3000` (frontend). Override with environment variables:

```bash
BACKEND_PORT=9000 FRONTEND_PORT=4000 .vscode/scripts/start-local.sh
```

## Requirements

- Python 3.11+ (for `tomllib`), or any Python 3 with the `tomli` package installed
- `uv` (backend dependency manager)
- `npm` (frontend)
- `aws` CLI (only for `--aws` mode)

## Running Tests

```bash
bash .vscode/scripts/test_resolve_env.sh
```

Temporarily swaps the TOML config, runs 18 test scenarios with 71 assertions, and restores the original config on exit.
