#!/usr/bin/env python3
# ABOUTME: Reads env_var_config.toml and resolves variable values from AWS secret JSON or .env files.
# ABOUTME: Outputs grouped export statements (BACKEND/FRONTEND/MISSING) for the bash start script.

"""
Three modes:

  _resolve_env.py --list-aws-sources
      Outputs AWS source discovery info (profile, env_prefix, sources) from the TOML config.
      Format:  AWS_PROFILE <profile>
               ENV_PREFIX <prefix>
               SOURCE <name> <full_secret_id>

  _resolve_env.py --aws --project-root <path> --secrets-dir <dir>
      Resolves from pre-fetched secret JSON files in <dir>/<source_name>.json.

  _resolve_env.py --env --project-root <path>
      Resolves from .env files specified in each source's env_file field.

Variable types in TOML:
  - Source var (source + aws_secret_key): from AWS secret JSON or .env file
  - Template var (template): interpolates {VAR_NAME} references from other resolved vars

Output for --aws and --env (stdout):
    ### BACKEND ###
    export VAR='value'
    ### FRONTEND ###
    export VAR='value'
    ### MISSING ###
    VAR_NAME

Errors go to stderr.
"""

import argparse
import json
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    try:
        import tomli as tomllib  # type: ignore[no-redef]
    except ModuleNotFoundError:
        print("ERROR: Python 3.11+ (tomllib) or the 'tomli' package is required.", file=sys.stderr)
        sys.exit(1)


def load_config() -> dict:
    config_path = Path(__file__).resolve().parent / "env_var_config.toml"
    if not config_path.exists():
        print(f"ERROR: Config not found: {config_path}", file=sys.stderr)
        sys.exit(1)
    with open(config_path, "rb") as f:
        return tomllib.load(f)


def parse_env_file(filepath: Path) -> dict[str, str]:
    """Parse a .env file into a dict, skipping comments and blank lines."""
    env = {}
    if not filepath.exists():
        return env
    for line in filepath.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if "=" not in stripped:
            continue
        key, _, value = stripped.partition("=")
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
            value = value[1:-1]
        env[key] = value
    return env


def shell_escape(value: str) -> str:
    """Escape a value for safe use in shell single-quoted strings."""
    return value.replace("'", "'\\''")



def get_var_type(var_cfg: dict) -> str:
    if "source" in var_cfg:
        return "source"
    if "template" in var_cfg:
        return "template"
    return "unknown"


# ---- list-aws-sources -------------------------------------------------

def cmd_list_aws_sources(config: dict) -> None:
    aws_cfg = config.get("aws", {})
    profile = aws_cfg.get("profile", "")
    project_name = aws_cfg.get("project_name", "")
    env_prefix = aws_cfg.get("env_prefix", "")

    if not env_prefix:
        print("ERROR: aws.env_prefix is not set in config", file=sys.stderr)
        sys.exit(1)

    print(f"AWS_PROFILE {profile}")
    print(f"ENV_PREFIX {env_prefix}")

    for name, src in config.get("sources", {}).items():
        suffix = src.get("secret_name")
        if suffix is None:
            continue
        parts = [p for p in (project_name, env_prefix, suffix) if p]
        print(f"SOURCE {name} {'/'.join(parts)}")


# ---- resolve: aws mode -------------------------------------------------

def resolve_aws(config: dict, secrets_dir: Path) -> dict[str, str]:
    sources = config.get("sources", {})
    variables = config.get("vars", {})
    resolved: dict[str, str] = {}

    parsed_secrets: dict[str, dict] = {}
    for source_name, source_cfg in sources.items():
        if "secret_name" not in source_cfg:
            continue
        secret_file = secrets_dir / f"{source_name}.json"
        if not secret_file.exists():
            print(f"ERROR: Expected secret file not found: {secret_file}", file=sys.stderr)
            sys.exit(1)
        try:
            parsed_secrets[source_name] = json.loads(secret_file.read_text())
        except json.JSONDecodeError as e:
            print(f"ERROR: Failed to parse JSON for source '{source_name}': {e}", file=sys.stderr)
            sys.exit(1)

    # Pass 1: source vars
    for var_name, var_cfg in variables.items():
        vtype = get_var_type(var_cfg)
        if vtype == "source":
            source_name = var_cfg["source"]
            if source_name not in sources:
                print(f"ERROR: Variable '{var_name}' references unknown source '{source_name}'", file=sys.stderr)
                sys.exit(1)
            if "secret_name" not in sources[source_name]:
                print(f"ERROR: Source '{source_name}' has no secret_name — cannot use --aws mode", file=sys.stderr)
                sys.exit(1)
            secret_data = parsed_secrets.get(source_name, {})
            key = var_cfg["aws_secret_key"]
            if key in secret_data:
                resolved[var_name] = str(secret_data[key])

    # Pass 2: template vars
    for var_name, var_cfg in variables.items():
        vtype = get_var_type(var_cfg)
        if vtype == "template":
            tpl = var_cfg["template"]
            try:
                resolved[var_name] = tpl.format(**resolved)
            except KeyError:
                pass  # will show up as missing

    return resolved


# ---- resolve: env mode -------------------------------------------------

def resolve_env(config: dict, project_root: Path) -> dict[str, str]:
    sources = config.get("sources", {})
    variables = config.get("vars", {})
    resolved: dict[str, str] = {}

    # Read all unique .env files
    env_cache: dict[str, dict[str, str]] = {}
    all_env_data: dict[str, str] = {}
    for source_cfg in sources.values():
        env_file = source_cfg.get("env_file")
        if env_file and env_file not in env_cache:
            env_cache[env_file] = parse_env_file(project_root / env_file)
            all_env_data.update(env_cache[env_file])

    # Pass 1: source vars
    for var_name, var_cfg in variables.items():
        vtype = get_var_type(var_cfg)
        if vtype == "source":
            source_name = var_cfg["source"]
            source_cfg = sources.get(source_name)
            if not source_cfg:
                print(f"ERROR: Variable '{var_name}' references unknown source '{source_name}'", file=sys.stderr)
                sys.exit(1)
            if "env_file" not in source_cfg:
                print(f"ERROR: Source '{source_name}' has no env_file — cannot use --env mode", file=sys.stderr)
                sys.exit(1)
            env_file = source_cfg["env_file"]
            env_data = env_cache.get(env_file, {})
            if var_name in env_data:
                resolved[var_name] = env_data[var_name]

    # Pass 2: template vars — always interpolate from resolved values
    for var_name, var_cfg in variables.items():
        vtype = get_var_type(var_cfg)
        if vtype == "template":
            tpl = var_cfg["template"]
            try:
                resolved[var_name] = tpl.format(**resolved)
            except KeyError:
                pass

    return resolved


# ---- output -------------------------------------------------------------

def output_exports(config: dict, resolved: dict[str, str]) -> None:
    variables = config.get("vars", {})
    backend_exports = []
    frontend_exports = []
    missing = []

    for var_name, var_cfg in variables.items():
        target = var_cfg.get("target", "both")
        if var_name not in resolved:
            missing.append(var_name)
            continue

        escaped = shell_escape(resolved[var_name])
        line = f"export {var_name}='{escaped}'"

        if target in ("backend", "both"):
            backend_exports.append(line)
        if target in ("frontend", "both"):
            frontend_exports.append(line)

    print("### BACKEND ###")
    for line in backend_exports:
        print(line)
    print("### FRONTEND ###")
    for line in frontend_exports:
        print(line)
    print("### MISSING ###")
    for var in missing:
        print(var)


# ---- main ---------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Resolve env vars from TOML config")
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument("--list-aws-sources", action="store_true", help="Output AWS source discovery info")
    mode_group.add_argument("--aws", action="store_true", help="Resolve from AWS secret JSON files")
    mode_group.add_argument("--env", action="store_true", help="Resolve from .env files")

    parser.add_argument("--project-root", help="Path to the project root directory")
    parser.add_argument("--secrets-dir", help="Directory containing <source>.json files (--aws mode)")

    args = parser.parse_args()
    config = load_config()

    if args.list_aws_sources:
        cmd_list_aws_sources(config)

    elif args.aws:
        if not args.project_root or not args.secrets_dir:
            print("ERROR: --project-root and --secrets-dir are required with --aws", file=sys.stderr)
            sys.exit(1)
        resolved = resolve_aws(config, Path(args.secrets_dir))
        output_exports(config, resolved)

    elif args.env:
        if not args.project_root:
            print("ERROR: --project-root is required with --env", file=sys.stderr)
            sys.exit(1)
        resolved = resolve_env(config, Path(args.project_root).resolve())
        output_exports(config, resolved)


if __name__ == "__main__":
    main()
