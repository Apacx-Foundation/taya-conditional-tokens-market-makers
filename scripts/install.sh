#!/usr/bin/env bash
set -euo pipefail

# Configurable
NODE_VERSION="${NODE_VERSION:-12.22.12}"
PROJECT_DIR="${PROJECT_DIR:-"$PWD"}"
RUN_BUILD="${RUN_BUILD:-0}"   # 0 = install only; 1 = also run compile and tests

# Track if we add any global git rewrites so we can safely revert them
ADDED_INSTEADOF_GIT=false
ADDED_INSTEADOF_SSH=false

revert_globals() {
  if [ "${ADDED_INSTEADOF_GIT}" = "true" ]; then
    git config --global --unset-all url."https://".insteadOf 'git://' || true
  fi
  if [ "${ADDED_INSTEADOF_SSH}" = "true" ]; then
    git config --global --unset-all url."https://github.com/".insteadOf 'git@github.com:' || true
  fi
}
trap revert_globals EXIT

# Ensure nvm is available
if [ -z "${NVM_DIR:-}" ]; then
  export NVM_DIR="$HOME/.nvm"
fi
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
else
  echo "nvm not found at $NVM_DIR/nvm.sh. Please install nvm and retry." >&2
  exit 1
fi

# Use Node 12 + npm 6
nvm install "${NODE_VERSION}"
nvm use "${NODE_VERSION}"

# Temporary global git URL rewrites to avoid failing git deps
if ! git config --global --get-all url."https://".insteadOf 2>/dev/null | grep -qx 'git://'; then
  git config --global --add url."https://".insteadOf git://
  ADDED_INSTEADOF_GIT=true
fi
if ! git config --global --get-all url."https://github.com/".insteadOf 2>/dev/null | grep -qx 'git@github.com:'; then
  git config --global --add url."https://github.com/".insteadOf git@github.com:
  ADDED_INSTEADOF_SSH=true
fi

# Install dependencies (scripts disabled)
if [ ! -d "${PROJECT_DIR}" ]; then
  echo "Project directory not found: ${PROJECT_DIR}" >&2
  exit 1
fi

pushd "${PROJECT_DIR}" >/dev/null

if [ -f package-lock.json ]; then
  npm ci --ignore-scripts
else
  npm install --ignore-scripts
fi

# Optional: compile and test to verify
if [ "${RUN_BUILD}" = "1" ]; then
  npm run compile
  npm test
fi

popd >/dev/null

echo "Done. Temporary global git config rewrites have been reverted."