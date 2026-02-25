#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Navigate to the project root (assuming script is in .vscode/scripts)
cd "$SCRIPT_DIR/../.."

API_EXISTS=false
UI_EXISTS=false

# Default ports
DEFAULT_BACKEND_PORT=8001
DEFAULT_FRONTEND_PORT=5173

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Kill any process occupying a given port
free_port() {
  local port=$1
  if lsof -i:$port > /dev/null 2>&1; then
    echo -e "${YELLOW} ⚠️ Port $port is already in use. Stopping the process...${NC}"
    kill -9 $(lsof -t -i:$port) || echo -e "${RED} ❌ Failed to kill process on port $port${NC}"
    sleep 2
  fi
}

echo -e "${BLUE}🚀 Starting All Services...${NC}"
echo ""

# Sync dependencies
echo -e "${BLUE}Syncing Backend Python dependencies...${NC}"
if [ -d "backend" ]; then
  cd backend && uv sync
  cd ..
else
    echo -e "${YELLOW}Backend directory not found. Skipping backend dependencies.${NC}"
fi

# Install UI dependencies
echo -e "${BLUE}Installing UI dependencies...${NC}"
if [ -d "frontend" ]; then
    cd frontend
    npm install
    cd ..
else
    echo -e "${YELLOW}Frontend directory not found. Skipping frontend dependencies.${NC}"
fi

# Load backend environment variables from backend/.env
if [ -f backend/.env ]; then
  export $(grep -v '^#' backend/.env | xargs)
  echo -e "${GREEN}Loaded backend environment variables from backend/.env${NC}"
  if grep -q '^BACKEND_PORT=' backend/.env; then
    echo -e "${GREEN}Using BACKEND_PORT=$BACKEND_PORT from backend/.env${NC}"
  else
    export BACKEND_PORT=$DEFAULT_BACKEND_PORT
    echo -e "${YELLOW}backend/.env exists but BACKEND_PORT is not specified. Using default BACKEND_PORT=$BACKEND_PORT${NC}"
  fi
else
  export BACKEND_PORT=$DEFAULT_BACKEND_PORT
  echo -e "${YELLOW}backend/.env not found. Using default BACKEND_PORT=$BACKEND_PORT${NC}"
fi

# Load frontend environment variables from frontend/.env
if [ -f frontend/.env ]; then
  export $(grep -v '^#' frontend/.env | xargs)
  echo -e "${GREEN}Loaded frontend environment variables from frontend/.env${NC}"
  if grep -q '^FRONTEND_PORT=' frontend/.env; then
    echo -e "${GREEN}Using FRONTEND_PORT=$FRONTEND_PORT from frontend/.env${NC}"
  elif grep -q '^VITE_PORT=' frontend/.env; then
    export FRONTEND_PORT=$VITE_PORT
    echo -e "${GREEN}Using VITE_PORT=$VITE_PORT from frontend/.env as FRONTEND_PORT${NC}"
  else
    export FRONTEND_PORT=$DEFAULT_FRONTEND_PORT
    echo -e "${YELLOW}frontend/.env exists but neither FRONTEND_PORT nor VITE_PORT is specified. Using default FRONTEND_PORT=$FRONTEND_PORT${NC}"
  fi
else
  export FRONTEND_PORT=$DEFAULT_FRONTEND_PORT
  echo -e "${YELLOW}frontend/.env not found. Using default FRONTEND_PORT=$FRONTEND_PORT${NC}"
fi

# Free up ports if in use
free_port $BACKEND_PORT
free_port $FRONTEND_PORT

# Start the FastAPI backend
if [ -d "backend" ]; then
  echo -e "${BLUE}▶️  Starting Backend API (PORT=$BACKEND_PORT)...${NC}"
  cd backend
  uv run uvicorn app.main:app --reload --port $BACKEND_PORT &
  API_PID=$!
  cd ..
  echo -e "${GREEN}✅ Backend PROCESS_ID=$API_PID${NC}"
  API_EXISTS=true
else
  echo -e "${YELLOW}Backend not set up yet. Only running frontend.${NC}"
  API_PID=""
fi

# Start the React frontend
if [ -d "frontend" ]; then
    echo -e "${BLUE}▶️  Starting Frontend (PORT=$FRONTEND_PORT)...${NC}"
    cd frontend && npm run dev &
    UI_PID=$!
    echo -e "${GREEN}✅ Frontend PROCESS_ID=$UI_PID${NC}"
    cd ..
    UI_EXISTS=true
else
    echo -e "${YELLOW}Frontend not set up yet. Only running backend.${NC}"
    UI_PID=""
fi

echo ""
if [ "$API_EXISTS" = true ]; then
  echo -e "${GREEN}Backend is running!${NC}"
  echo "API is available at: http://localhost:$BACKEND_PORT"
  echo "API health endpoint: http://localhost:$BACKEND_PORT/api/health"
fi
if [ "$UI_EXISTS" = true ]; then
  echo -e "${GREEN}Frontend is running!${NC}"
  echo "UI is available at: http://localhost:$FRONTEND_PORT"
fi
echo -e "Press Ctrl+C to stop both services ${NC}"

# Handle clean shutdown
cleanup() {
  echo ""
  echo -e "${RED}Stopping services...${NC}"
  kill $API_PID 2>/dev/null
  [ -n "$UI_PID" ] && kill $UI_PID 2>/dev/null
  exit 0
}

trap cleanup SIGINT

# Wait for processes
wait
