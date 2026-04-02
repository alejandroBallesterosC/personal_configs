#!/usr/bin/env bash
# ABOUTME: Starts backend and frontend locally.
# ABOUTME: Two modes: --aws fetches secrets from AWS Secrets Manager, --env loads .env files (default).
# ABOUTME: Fully config-driven — edit env_var_config.toml to add/remove variables, sources, and settings.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
cd "$PROJECT_ROOT"

# --- Defaults ---
MODE="env"
SYNC_DEPS=false
DEFAULT_BACKEND_PORT=8000
DEFAULT_FRONTEND_PORT=3000

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Parse arguments ---
for arg in "$@"; do
  case "$arg" in
    --aws)  MODE="aws" ;;
    --env)  MODE="env" ;;
    --sync) SYNC_DEPS=true ;;
    *)
      echo -e "${RED}Unknown argument: $arg${NC}"
      echo "Usage: $0 [--aws|--env] [--sync]"
      echo ""
      echo "  --aws   Fetch secrets from AWS Secrets Manager (config in env_var_config.toml)"
      echo "  --env   Load from .env files defined in env_var_config.toml (default)"
      echo "  --sync  Install/sync dependencies before starting"
      exit 1
      ;;
  esac
done

# --- Helpers ---
free_port() {
  local port=$1
  if lsof -i:"$port" > /dev/null 2>&1; then
    echo -e "${YELLOW}Port $port is in use — killing existing process...${NC}"
    kill -9 $(lsof -t -i:"$port") 2>/dev/null || true
    sleep 1
  fi
}

# --- Sync dependencies (optional) ---
if [ "$SYNC_DEPS" = true ]; then
  if [ -d "backend" ]; then
    echo -e "${BLUE}Syncing backend dependencies...${NC}"
    (cd backend && uv sync)
  fi
  if [ -d "frontend" ]; then
    echo -e "${BLUE}Installing frontend dependencies...${NC}"
    (cd frontend && npm install)
  fi
  echo ""
fi

# =====================================================================
#  Resolve environment variables via _resolve_env.py
# =====================================================================
RESOLVER="$SCRIPT_DIR/_resolve_env.py"

if [ "$MODE" = "aws" ]; then
  # Discover sources, profile, and env prefix from TOML config
  DISCOVERY=$(python3 "$RESOLVER" --list-aws-sources)
  AWS_PROFILE=$(echo "$DISCOVERY" | awk '/^AWS_PROFILE /{print $2}')
  ENV_PREFIX=$(echo "$DISCOVERY" | awk '/^ENV_PREFIX /{print $2}')

  echo -e "${BLUE}Fetching $ENV_PREFIX secrets from AWS Secrets Manager (profile: $AWS_PROFILE)...${NC}"

  # Fetch each secret into a temp directory
  SECRETS_DIR=$(mktemp -d)
  trap "rm -rf '$SECRETS_DIR'" EXIT

  while read -r _ source_name secret_id; do
    echo -e "${BLUE}  Fetching $source_name ($secret_id)...${NC}"
    aws secretsmanager get-secret-value \
      --secret-id "$secret_id" \
      --profile "$AWS_PROFILE" \
      --query SecretString --output text > "$SECRETS_DIR/$source_name.json"
  done < <(echo "$DISCOVERY" | grep "^SOURCE ")

  # Resolve variables from fetched secrets
  RESOLVER_OUTPUT=$(python3 "$RESOLVER" --aws --project-root "$PROJECT_ROOT" --secrets-dir "$SECRETS_DIR")
  rm -rf "$SECRETS_DIR"
  trap - EXIT

else
  echo -e "${BLUE}Resolving variables from .env files...${NC}"
  RESOLVER_OUTPUT=$(python3 "$RESOLVER" --env --project-root "$PROJECT_ROOT")
fi

# --- Parse resolver output into backend/frontend/missing blocks ---
BACKEND_EXPORTS=$(echo "$RESOLVER_OUTPUT" | awk '/^### BACKEND ###$/{f=1;next} /^###/{f=0} f')
FRONTEND_EXPORTS=$(echo "$RESOLVER_OUTPUT" | awk '/^### FRONTEND ###$/{f=1;next} /^###/{f=0} f')
MISSING_VARS=$(echo "$RESOLVER_OUTPUT" | awk '/^### MISSING ###$/{f=1;next} /^###/{f=0} f' | grep -v '^\s*$' || true)

# --- Validate: fail if any required vars are missing ---
if [ -n "$MISSING_VARS" ]; then
  echo ""
  echo -e "${RED}Missing required environment variables:${NC}"
  while IFS= read -r var; do
    echo -e "${RED}  - $var${NC}"
  done <<< "$MISSING_VARS"
  echo ""
  if [ "$MODE" = "env" ]; then
    echo -e "${YELLOW}Add them to the .env files defined in env_var_config.toml, or use --aws to fetch from Secrets Manager.${NC}"
  else
    echo -e "${YELLOW}Check the secrets in AWS Secrets Manager for the env_prefix defined in env_var_config.toml.${NC}"
  fi
  exit 1
fi

# --- Resolve ports ---
BACKEND_PORT="${BACKEND_PORT:-$DEFAULT_BACKEND_PORT}"
FRONTEND_PORT="${FRONTEND_PORT:-${VITE_PORT:-$DEFAULT_FRONTEND_PORT}}"

# --- Free ports if occupied ---
free_port "$BACKEND_PORT"
free_port "$FRONTEND_PORT"

# --- Start backend (in subshell with only backend+both vars) ---
BACKEND_PID=""
if [ -d "backend" ]; then
  echo ""
  echo -e "${BLUE}Starting backend on port $BACKEND_PORT...${NC}"
  (
    eval "$BACKEND_EXPORTS"
    # Append tlsCAFile to MONGODB_URI for local TLS against Atlas
    CERTIFI_PATH=$(python3 -c "import certifi; print(certifi.where())" 2>/dev/null || echo "")
    if [ -n "$CERTIFI_PATH" ] && [ -n "${MONGODB_URI:-}" ]; then
      if echo "$MONGODB_URI" | grep -q '?'; then
        export MONGODB_URI="${MONGODB_URI}&tlsCAFile=${CERTIFI_PATH}"
      else
        export MONGODB_URI="${MONGODB_URI}?tlsCAFile=${CERTIFI_PATH}"
      fi
    fi
    cd backend && uv run uvicorn main:app --host 0.0.0.0 --port "$BACKEND_PORT" --reload
  ) &
  BACKEND_PID=$!
else
  echo -e "${YELLOW}backend/ directory not found — skipping${NC}"
fi

sleep 1

# --- Start frontend (in subshell with only frontend+both vars) ---
FRONTEND_PID=""
if [ -d "frontend" ]; then
  echo -e "${BLUE}Starting frontend on port $FRONTEND_PORT...${NC}"
  (
    eval "$FRONTEND_EXPORTS"
    cd frontend && npm run dev
  ) &
  FRONTEND_PID=$!
else
  echo -e "${YELLOW}frontend/ directory not found — skipping${NC}"
fi

# --- Cleanup on exit ---
cleanup() {
  echo ""
  echo -e "${RED}Shutting down...${NC}"
  trap '' SIGINT

  [ -n "$BACKEND_PID" ]  && kill "$BACKEND_PID"  2>/dev/null
  [ -n "$FRONTEND_PID" ] && kill "$FRONTEND_PID" 2>/dev/null

  local waited=0
  while [ $waited -lt 5 ]; do
    local alive=false
    [ -n "$BACKEND_PID" ]  && kill -0 "$BACKEND_PID"  2>/dev/null && alive=true
    [ -n "$FRONTEND_PID" ] && kill -0 "$FRONTEND_PID" 2>/dev/null && alive=true
    $alive || break
    sleep 1
    waited=$((waited + 1))
  done

  [ -n "$BACKEND_PID" ]  && kill -9 "$BACKEND_PID"  2>/dev/null || true
  [ -n "$FRONTEND_PID" ] && kill -9 "$FRONTEND_PID" 2>/dev/null || true

  free_port "$BACKEND_PORT"
  free_port "$FRONTEND_PORT"

  echo -e "${GREEN}All services stopped.${NC}"
  exit 0
}
trap cleanup SIGINT SIGTERM

# --- Summary ---
echo ""
echo -e "${GREEN}=========================================${NC}"
if [ "$MODE" = "aws" ]; then
  echo -e "${GREEN}  Local dev running against $ENV_PREFIX${NC}"
else
  echo -e "${GREEN}  Local dev running from .env files${NC}"
fi
echo -e "${GREEN}=========================================${NC}"
[ -n "$BACKEND_PID" ]  && echo "  Backend:  http://localhost:$BACKEND_PORT"
[ -n "$FRONTEND_PID" ] && echo "  Frontend: http://localhost:$FRONTEND_PORT"
[ -n "$BACKEND_PID" ]  && echo "  Docs:     http://localhost:$BACKEND_PORT/docs"
echo ""
echo "  Press Ctrl+C to stop all services."
echo ""

wait
