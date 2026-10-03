#!/usr/bin/env bash

set -eo pipefail

# Upsert KEY=VALUE into a file, replacing an existing KEY line or appending.
# Only touches the given key; all other lines are preserved.
upsert_env() {
    local file=$1 key=$2 value=$3

    [[ -f "$file" ]] || : > "$file"

    if grep -qE "^${key}=" "$file"; then
        # Replace in place without a temp file race; value is treated literally.
        local tmp
        tmp="$(mktemp)"
        grep -vE "^${key}=" "$file" > "$tmp"
        printf '%s=%s\n' "$key" "$value" >> "$tmp"
        mv "$tmp" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}

# Sanitize an arbitrary string into a valid Docker Compose name component:
# lowercase, only [a-z0-9_-], and not starting with a separator.
sanitize_name() {
    local s=$1
    s="$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '-')"
    # Collapse repeated separators and trim leading/trailing ones.
    s="$(printf '%s' "$s" | sed -E 's/-+/-/g; s/^[-_]+//; s/[-_]+$//')"
    printf '%s' "$s"
}

# Resolve the human-readable repo name.
# Worktree (.git is a file): basename of the dir holding the common gitdir.
# Normal repo: basename of the repo root.
resolve_repo_name() {
    local repo_root=$1

    if [[ -f "$repo_root/.git" ]]; then
        local gitdir
        gitdir="$(cd "$repo_root" && git rev-parse --git-common-dir)"
        case $gitdir in
            /*) ;;
            *) gitdir="$repo_root/$gitdir" ;;
        esac
        gitdir="$(cd "$gitdir" && pwd)"
        basename "$(dirname "$gitdir")"
    else
        basename "$repo_root"
    fi
}

set_worktree_env() {
    local repo_root=$1
    local env_file="$2/.env"

    if [[ -f "$repo_root/.git" ]]; then
        # Worktree: .git is a file, resolve the common git dir
        local gitdir
        gitdir="$(cd "$repo_root" && git rev-parse --git-common-dir)"
        case $gitdir in
            /*) ;;
            *) gitdir="$repo_root/$gitdir" ;;
        esac
        gitdir="$(cd "$gitdir" && pwd)"

        upsert_env "$env_file" GIT_REPO "$gitdir"
        upsert_env "$env_file" WORKSPACE_SOURCE "$repo_root"
        upsert_env "$env_file" WORKSPACE_TARGET "$repo_root"
        echo "Worktree detected: GIT_REPO=$gitdir"
    else
        # Normal repo: mount at host path so localWorkspaceFolder resolves
        upsert_env "$env_file" GIT_REPO "/dev/null"
        upsert_env "$env_file" WORKSPACE_SOURCE "$repo_root"
        upsert_env "$env_file" WORKSPACE_TARGET "$repo_root"
        echo "Normal repo detected, no worktree mount needed"
    fi
}

# Set COMPOSE_PROJECT_NAME in the project-root .env (where Compose reads it),
# built from "<repo>-<branch>" with both parts sanitized.
set_project_name() {
    local repo_root=$1
    local root_env_file="$2/.env"

    local repo_name branch project_name
    repo_name="$(resolve_repo_name "$repo_root")"
    branch="$(cd "$repo_root" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

    project_name="$(sanitize_name "$repo_name")-$(sanitize_name "$branch")"
    upsert_env "$root_env_file" COMPOSE_PROJECT_NAME "$project_name"
    echo "COMPOSE_PROJECT_NAME=$project_name"
}

main() {
    local script_dir="$(dirname "$0")"

    # Resolve the repo root (parent of .devcontainer)
    local repo_root
    repo_root="$(cd "$script_dir/.." && pwd)"

    set_worktree_env "$repo_root" "$script_dir"
    set_project_name "$repo_root" "$script_dir"
}

main
