#!/usr/bin/env bash

set -eo pipefail

set_git_safe_directory() {
  . "./.devcontainer/.env"

  git config --global --add safe.directory "$WORKSPACE_TARGET"
  if [ "${GIT_REPO:-/dev/null}" != "/dev/null" ]; then
    git config --global --add safe.directory "$GIT_REPO"
  fi
}

main() {
  set_git_safe_directory
}

main
