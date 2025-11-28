#!/usr/bin/env bash
# gw - Git Worktree Helper
# A git worktree manager using the subdirectory strategy
#
# Installation:
#   Source this file in your .zshrc or .bashrc:
#   source /path/to/gw.sh
#
# Usage:
#   gw create <name>     - Create a new worktree
#   gw rm <name>         - Remove a worktree
#   gw cd <name>         - Navigate to a worktree
#   gw list              - List all worktrees
#   gw clean             - Remove all worktrees (with confirmation)

# Allow overriding the suffix for worktree directories (default: /.worktrees).
: "${GW_WORKTREE_SUFFIX:=/.worktrees}"
: "${GW_TAB_COUNT:=3}"

# Yakuake tab management
_gw_yakuake_is_running() {
    qdbus org.kde.yakuake >/dev/null 2>&1
}

_gw_get_project_name() {
    local worktree_name="$1"
    # ss-alcampo-es -> alcampo
    if [[ "$worktree_name" =~ ^ss-([a-zA-Z0-9]+)-[a-zA-Z0-9]+$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo "$worktree_name"
    fi
}

_gw_find_project_tabs() {
    local project_name_prefix="$1"
    local session_ids
    session_ids=$(qdbus org.kde.yakuake /yakuake/sessions sessionIds)
    for session_id in $session_ids; do
        local title
        title=$(qdbus org.kde.yakuake /yakuake/tabs tabTitle "$session_id")
        if [[ "$title" =~ ^$project_name_prefix[[:space:]][0-9]+$ ]]; then
            echo "$title"
        fi
    done
}

_gw_get_next_tab_number() {
    local project_name="$1"
    local tabs
    tabs=$(_gw_find_project_tabs "$project_name")
    if [ -z "$tabs" ]; then
        echo 1
        return
    fi

    local max_num=0
    while IFS= read -r tab_title; do
        local num
        num=${tab_title##* }
        if [[ "$num" -gt "$max_num" ]]; then
            max_num=$num
        fi
    done <<< "$tabs"
    echo $((max_num + 1))
}

_gw_create_tabs() {
    local worktree_name="$1"
    local worktree_path="$2"

    if ! _gw_yakuake_is_running; then
        echo "Warning: Yakuake is not running. Tabs not created."
        return
    fi

    local project_name
    project_name=$(_gw_get_project_name "$worktree_name")

    # Collision check
    local existing_tabs
    existing_tabs=$(_gw_find_project_tabs "$project_name")
    if [ -n "$existing_tabs" ]; then
        echo "Warning: Tabs with prefix '$project_name' already exist. Using full worktree name."
        project_name="$worktree_name"
    fi

    local tab_count="${GW_TAB_COUNT}"
    echo "Creating $tab_count Yakuake tabs for project '$project_name'..."

    for i in $(seq 1 "$tab_count"); do
        local session_id
        session_id=$(qdbus org.kde.yakuake /yakuake/sessions addSession)
        qdbus org.kde.yakuake /yakuake/tabs setTabTitle "$session_id" "$project_name $i"
        qdbus org.kde.yakuake /yakuake/sessions runCommand "cd '$worktree_path'"

        local status_msg="✓ Tab $i: $project_name $i"
        if [ "$i" -eq 1 ]; then
            if command -v carto_claude >/dev/null 2>&1; then
                local terminal_id
                terminal_id=$(qdbus org.kde.yakuake /yakuake/sessions terminalIdForSessionId "$session_id")
                qdbus org.kde.yakuake /yakuake/sessions runCommandInTerminal "$terminal_id" "carto_claude"
                status_msg+=" (running carto_claude)"
            else
                status_msg+=" (Warning: carto_claude not found)"
            fi
        fi
        echo "  $status_msg"
    done
}

_gw_detect_current_project() {
    # Directory-based detection
    local repo_root
    repo_root=$(_gw_get_repo_root)
    if [ -n "$repo_root" ]; then
        local current_dir
        current_dir=$(pwd)
        local worktree_base
        worktree_base="$(_gw_get_worktree_base)"
        if [[ "$current_dir" == "$worktree_base"* ]]; then
            local worktree_dir_name
            worktree_dir_name=${current_dir#$worktree_base/}
            worktree_dir_name=${worktree_dir_name%%/*} # handle subdirs
            local worktree_name="${worktree_dir_name//__/\/}"
            _gw_get_project_name "$worktree_name"
            return
        fi
    fi

    # Fallback: Tab title-based detection
    if _gw_yakuake_is_running; then
        local active_session
        active_session=$(qdbus org.kde.yakuake /yakuake/sessions activeSessionId)
        if [ -n "$active_session" ]; then
            local title
            title=$(qdbus org.kde.yakuake /yakuake/tabs tabTitle "$active_session")
            if [[ "$title" =~ ^([^[:space:]]+)[[:space:]][0-9]+$ ]]; then
                echo "${BASH_REMATCH[1]}"
                return
            fi
        fi
    fi

    echo ""
}

_gw_add_tab() {
    if ! _gw_yakuake_is_running; then
        echo "Error: Yakuake is not running." >&2
        return 1
    fi

    local project_name
    project_name=$(_gw_detect_current_project)

    if [ -z "$project_name" ]; then
        # If project not detected, use current tab's title as the project name
        local active_session
        active_session=$(qdbus org.kde.yakuake /yakuake/sessions activeSessionId)
        if [ -n "$active_session" ]; then
            local current_title
            current_title=$(qdbus org.kde.yakuake /yakuake/tabs tabTitle "$active_session")

            # If the title has a number at the end, use the part before it as the project name
            if [[ "$current_title" =~ ^(.*[^[:space:]])[[:space:]]+[0-9]+$ ]]; then
                project_name="${BASH_REMATCH[1]}"
            else
                project_name="$current_title"
            fi
        fi
    fi

    if [ -z "$project_name" ]; then
        echo "Error: Could not detect project or get current tab title. Run 'gw tab' from within a worktree or a project tab." >&2
        return 1
    fi

    echo "Detected project: $project_name"
    local existing_tabs
    existing_tabs=$(qdbus org.kde.yakuake /yakuake/sessions sessionIds | while read -r id; do qdbus org.kde.yakuake /yakuake/tabs tabTitle "$id"; done | grep "^$project_name [0-9]\+$" | tr '\n' ',' | sed 's/,$//')
    echo "Found existing tabs: ${existing_tabs//,/ }"


    local next_num
    next_num=$(_gw_get_next_tab_number "$project_name")
    local tab_title="$project_name $next_num"
    echo "Creating tab: $tab_title"

    local worktree_path
    worktree_path=$(pwd) # Assume we are in the correct worktree path

    local session_id
    session_id=$(qdbus org.kde.yakuake /yakuake/sessions addSession)
    qdbus org.kde.yakuake /yakuake/tabs setTabTitle "$session_id" "$tab_title"
    qdbus org.kde.yakuake /yakuake/sessions runCommand "cd '$worktree_path'"

    echo "  ✓ Tab created successfully"
    echo "Note: New tab created at end of tab bar. Reorder manually if needed."
}


# Input validation function to prevent path traversal and command injection
_gw_validate_name() {
    local name="$1"

    # Check if name is empty
    if [[ -z "$name" ]]; then
        echo "Error: Worktree name cannot be empty" >&2
        return 1
    fi

    # Check length (max 255 characters)
    if [[ ${#name} -gt 255 ]]; then
        echo "Error: Worktree name too long (max 255 characters)" >&2
        return 1
    fi

    # Check for path traversal attempts (but allow single forward slashes)
    if [[ "$name" == *".."* ]] || [[ "$name" == *"\\"* ]]; then
        echo "Error: Invalid worktree name. Cannot contain '..' or '\\'" >&2
        return 1
    fi

    # Check for valid characters (alphanumeric, dash, underscore, dot, forward slash)
    if ! [[ "$name" =~ ^[a-zA-Z0-9._/-]+$ ]]; then
        echo "Error: Invalid worktree name. Use only letters, numbers, dots, dashes, underscores, and forward slashes" >&2
        return 1
    fi

    # Prevent leading or trailing slashes, or multiple consecutive slashes
    if [[ "$name" =~ ^/ ]] || [[ "$name" =~ /$ ]] || [[ "$name" =~ // ]]; then
        echo "Error: Invalid worktree name. Cannot start/end with '/' or contain consecutive '/'" >&2
        return 1
    fi

    # Check for special names that could be problematic
    if [[ "$name" == "." ]] || [[ "$name" == ".." ]] || [[ "$name" == ".git" ]]; then
        echo "Error: Reserved name cannot be used" >&2
        return 1
    fi

    return 0
}

gw() {
    local cmd="$1"
    if [ -z "$cmd" ]; then
        local repo_root
        repo_root="$(_gw_get_repo_root)"
        if [ -n "$repo_root" ]; then
            _gw_list
        else
            _gw_usage
        fi
        return 0
    fi
    shift

    case "$cmd" in
        create)  _gw_create "$@" ;;
        review)  _gw_review "$@" ;;
        rm|remove) _gw_remove "$@" ;;
        cd)      _gw_cd "$@" ;;
        list|ls) _gw_list "$@" ;;
        clean)   _gw_clean "$@" ;;
        tab|tabs)  _gw_add_tab "$@" ;;
        help|-h|--help) _gw_usage ;;
        *)       echo "Unknown command: $cmd"; _gw_usage; return 1 ;;
    esac
}

_gw_usage() {
    cat <<EOF
gw - Git Worktree Helper

Commands:
  create <name> [directory] [--stay] [--tabs] Create a worktree and cd to it (uses existing branch if found; --stay to not cd, --tabs to create yakuake tabs)
  review <name> [--stay]              Create a worktree from existing local/remote branch and cd to it (--stay to not cd)
  rm <name> [--keep-branch]           Remove a worktree (with confirmation; --keep-branch keeps the branch)
  cd [name]                           Navigate to a worktree or repo root (if no name)
  list                                List all worktrees for current repo
  clean                               Remove all worktrees (with confirmation)
  tab                                 Add a yakuake tab to the current project

Examples:
  gw create feature-x              # Create and switch to worktree 'feature-x' (new branch from current)
  gw create feature-x --tabs       # Create worktree and yakuake tabs
  gw create feature-x custom-dir   # Create branch 'feature-x' in directory 'custom-dir'
  gw create feature-x --stay       # Create worktree without switching
  gw create feature-x custom --stay # Create with custom directory, don't switch
  gw create existing-branch        # Create worktree using existing local/remote branch
  gw review feature/pr-123         # Create worktree from existing branch (for review)
  gw review feature/pr-123 --stay  # Create review worktree without switching
  gw cd feature-x                  # Navigate to worktree
  gw cd                            # Navigate to repository root
  gw rm feature-x                  # Remove worktree (and branch by default)
  gw rm feature-x --keep-branch    # Remove worktree but keep branch
  gw tab                           # Add a yakuake tab
EOF
}

# Replace $HOME with ~ in a path for display
_gw_display_path() {
    local path="$1"
    if [[ "$path" == "$HOME"/* ]]; then
        echo "~${path#$HOME}"
    else
        echo "$path"
    fi
}

# Get the git repository root
_gw_get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null
}

# Get the main repository root (not worktree)
_gw_get_main_repo_root() {
    # Get the first entry from git worktree list, which is always the main repo
    git worktree list 2>/dev/null | head -n 1 | awk '{print $1}'
}

# Get the base path for worktrees (subdirectory strategy)
_gw_get_worktree_base() {
    local main_repo_root
    main_repo_root="$(_gw_get_main_repo_root)"

    if [ -z "$main_repo_root" ]; then
        main_repo_root="$(_gw_get_repo_root)"
        [ -z "$main_repo_root" ] && return 1
    fi

    echo "${main_repo_root}${GW_WORKTREE_SUFFIX}"
}

# Resolve branch information for create/review commands.
# Sets GW_BRANCH_EXISTS, GW_BRANCH_REF and GW_BRANCH_IS_REMOTE.
_gw_resolve_branch() {
    local branch="$1"
    local require_existing="${2:-false}"

    local branch_exists=false
    local branch_ref=""
    local branch_is_remote=false

    if git show-ref --verify --quiet "refs/heads/$branch"; then
        branch_exists=true
        branch_ref="$branch"
        branch_is_remote=false
        echo "Found local branch '$branch'"
    elif git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        branch_exists=true
        branch_ref="origin/$branch"
        branch_is_remote=true
        echo "Found remote branch 'origin/$branch'"
    fi

    GW_BRANCH_EXISTS="$branch_exists"
    GW_BRANCH_REF="$branch_ref"
    GW_BRANCH_IS_REMOTE="$branch_is_remote"

    if [ "$require_existing" = "true" ] && [ "$branch_exists" = false ]; then
        return 1
    fi

    return 0
}

# Create a new worktree
_gw_create() {
    local name="$1"
    local dir_name=""
    local stay=false
    local tabs=false
    shift

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --stay)
                stay=true
                shift
                ;;
            --tabs)
                tabs=true
                shift
                ;;
            *)
                if [ -z "$dir_name" ]; then
                    dir_name="$1"
                    shift
                else
                    echo "Error: Unknown argument '$1'" >&2
                    _gw_usage
                    return 1
                fi
                ;;
        esac
    done

    [ -z "$name" ] && { echo "Usage: gw create <name> [directory] [--stay] [--tabs]"; return 1; }

    # Validate the branch name
    if ! _gw_validate_name "$name"; then
        return 1
    fi

    local repo_root
    repo_root="$(_gw_get_repo_root)"
    [ -z "$repo_root" ] && { echo "Not in a git repository"; return 1; }

    local worktree_base
    worktree_base="$(_gw_get_worktree_base)"

    # If no directory name provided, derive from branch name
    if [ -z "$dir_name" ]; then
        dir_name="${name//\//__}"
    fi

    # Validate the directory name
    if ! _gw_validate_name "$dir_name"; then
        return 1
    fi

    local worktree_path="$worktree_base/$dir_name"

    # Check if worktree already exists (use fixed string matching)
    if git worktree list | grep -F -- "$worktree_path" > /dev/null 2>&1; then
        echo "Worktree '$name' already exists at $worktree_path"
        return 1
    fi

    # Resolve branch information (if branch already exists)
    local use_existing_branch=false
    if _gw_resolve_branch "$name" "false"; then
        if [ "$GW_BRANCH_EXISTS" = true ]; then
            use_existing_branch=true
        fi
    else
        echo "Warning: Failed to resolve branch information"
    fi

    # Get current branch for fallback
    local current_branch
    current_branch=$(git branch --show-current)
    if [ -z "$current_branch" ]; then
        echo "Warning: Not on a branch, using HEAD"
        current_branch="HEAD"
    fi

    # Create the worktree base directory if it doesn't exist
    if [ ! -d "$worktree_base" ]; then
        echo "Creating worktree base directory: $worktree_base"
        mkdir -p "$worktree_base"
    fi

    # Create the worktree
    echo "Creating worktree '$name' at $worktree_path"

    if [ "$use_existing_branch" = true ]; then
        if [ "$GW_BRANCH_IS_REMOTE" = true ]; then
            echo "Creating local tracking branch '$name' from $GW_BRANCH_REF"
            if git show-ref --verify --quiet "refs/heads/$name"; then
                echo "Local branch '$name' already exists, using it instead"
                GW_BRANCH_IS_REMOTE=false
                GW_BRANCH_REF="$name"
            fi
        fi

        if [ "$GW_BRANCH_IS_REMOTE" = true ]; then
            if ! git worktree add --track -b "$name" "$worktree_path" "$GW_BRANCH_REF"; then
                echo "Failed to create worktree from remote branch"
                return 1
            fi
        else
            echo "Using existing branch: $GW_BRANCH_REF"
            if ! git worktree add "$worktree_path" "$GW_BRANCH_REF"; then
                echo "Failed to create worktree from existing branch"
                return 1
            fi
        fi
    else
        echo "Creating new branch '$name' based on: $current_branch"
        # Create new branch as before
        if ! git worktree add "$worktree_path" -b "$name" "$current_branch"; then
            echo "Failed to create worktree with new branch"
            return 1
        fi
    fi

    if [ "$stay" = false ]; then
        if cd "$worktree_path"; then
            echo "Switched to worktree: $name"
            echo "Current directory: $(pwd)"
        else
            echo "Warning: Failed to switch to worktree: $worktree_path" >&2
        fi
    else
        echo "Successfully created worktree '$name'"
        echo "To navigate to it, run: gw cd $name"
    fi

    if [ "$tabs" = true ]; then
        _gw_create_tabs "$name" "$worktree_path"
    fi
}

# Create a worktree from an existing branch (for code review)
_gw_review() {
    local name="$1"
    local stay=false
    shift
    if [ $# -gt 0 ] && [ "$1" = "--stay" ]; then
        stay=true
        shift
    fi
    if [ $# -gt 0 ]; then
        echo "Error: Unknown arguments" >&2
        return 1
    fi
    [ -z "$name" ] && { echo "Usage: gw review <name> [--stay]"; return 1; }

    # Validate the worktree name
    if ! _gw_validate_name "$name"; then
        return 1
    fi

    local repo_root
    repo_root="$(_gw_get_repo_root)"
    [ -z "$repo_root" ] && { echo "Not in a git repository"; return 1; }

    local worktree_base
    worktree_base="$(_gw_get_worktree_base)"
    # Replace slashes with double underscores for directory name
    local dir_name="${name//\//__}"
    local worktree_path="$worktree_base/$dir_name"

    # Check if worktree already exists (use fixed string matching)
    if git worktree list | grep -F -- "$worktree_path" > /dev/null 2>&1; then
        echo "Worktree '$name' already exists at $worktree_path"
        return 1
    fi

    if ! _gw_resolve_branch "$name" "true"; then
        echo "Error: Branch '$name' does not exist locally or on origin"
        echo "Use 'gw create $name' to create a new branch, or"
        echo "Use 'git fetch' to update remote branches if needed"
        return 1
    fi

    # Create the worktree base directory if it doesn't exist
    if [ ! -d "$worktree_base" ]; then
        echo "Creating worktree base directory: $worktree_base"
        mkdir -p "$worktree_base"
    fi

    # Create the worktree from existing branch
    echo "Creating worktree '$name' at $worktree_path"

    if [ "$GW_BRANCH_IS_REMOTE" = true ]; then
        echo "Creating local tracking branch '$name' from $GW_BRANCH_REF"
        if git show-ref --verify --quiet "refs/heads/$name"; then
            echo "Local branch '$name' already exists, using it instead"
            GW_BRANCH_IS_REMOTE=false
            GW_BRANCH_REF="$name"
        fi
    fi

    if [ "$GW_BRANCH_IS_REMOTE" = true ]; then
        if ! git worktree add --track -b "$name" "$worktree_path" "$GW_BRANCH_REF"; then
            echo "Failed to create worktree from remote branch"
            return 1
        fi
    else
        echo "Using existing branch: $GW_BRANCH_REF"
        if ! git worktree add "$worktree_path" "$GW_BRANCH_REF"; then
            echo "Failed to create worktree from existing branch"
            return 1
        fi
    fi

    if [ "$stay" = false ]; then
        if cd "$worktree_path"; then
            echo "Switched to worktree: $name"
            echo "Current directory: $(pwd)"
        else
            echo "Warning: Failed to switch to worktree: $worktree_path" >&2
        fi
    else
        echo "Successfully created review worktree '$name'"
        echo "To navigate to it, run: gw cd $name"
    fi
}

# Check for uncommitted changes in a worktree
_gw_check_uncommitted_changes() {
    local worktree_path="$1"
    local name="$2"

    # Check if directory exists
    if [ ! -d "$worktree_path" ]; then
        return 0
    fi

    # Check for uncommitted changes in the worktree
    local has_changes=false
    local status_output=""

    # Run git status in the worktree directory
    pushd "$worktree_path" > /dev/null 2>&1 || return 1

    # Check for any uncommitted changes
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        has_changes=true
        status_output="$(git status --short 2>/dev/null)"
    fi

    popd > /dev/null 2>&1

    if [ "$has_changes" = true ]; then
        echo "⚠️  WARNING: Uncommitted changes detected in worktree '$name'"
        echo
        echo "Changes found:"
        echo "$status_output" | while IFS= read -r line; do
            echo "  $line"
        done
        echo
        return 1
    fi

    return 0
}

# Handle branch deletion logic when removing worktrees
_gw_handle_branch_deletion() {
    local name="$1"

    # Check if local branch exists
    if ! git show-ref --verify --quiet "refs/heads/$name"; then
        echo "Note: No local branch '$name' to delete"
        return 0
    fi

    # Check if the branch is used in other worktrees
    local branch_in_use=false
    while IFS= read -r line; do
        # Extract branch from git worktree list output
        if echo "$line" | grep -q "\[$name\]"; then
            branch_in_use=true
            break
        fi
    done < <(git worktree list)

    if [ "$branch_in_use" = true ]; then
        echo "Note: Branch '$name' is still in use by another worktree, not deleting"
        return 0
    fi

    # Check if branch has a remote counterpart
    local has_remote=false
    if git show-ref --verify --quiet "refs/remotes/origin/$name"; then
        has_remote=true
    fi

    # Try to delete the branch
    if git branch -d "$name" 2>/dev/null; then
        if [ "$has_remote" = true ]; then
            echo "Deleted local branch '$name' (remote branch 'origin/$name' still exists)"
        else
            echo "Deleted local branch '$name'"
        fi
    else
        if [ "$has_remote" = true ]; then
            echo "Note: Local branch '$name' still exists (may have unmerged changes, remote exists)"
        else
            echo "Note: Branch '$name' still exists (may have unmerged changes)"
        fi
        echo "Use 'git branch -D $name' to force delete if needed"
    fi
}

# Remove a worktree
_gw_remove() {
    local name="$1"
    local keep_branch=false
    shift
    if [ $# -gt 0 ] && [ "$1" = "--keep-branch" ]; then
        keep_branch=true
        shift
    fi
    if [ $# -gt 0 ]; then
        echo "Error: Unknown arguments" >&2
        return 1
    fi
    [ -z "$name" ] && { echo "Usage: gw rm <name> [--keep-branch]"; return 1; }

    # Validate the worktree name
    if ! _gw_validate_name "$name"; then
        return 1
    fi

    local worktree_base
    worktree_base="$(_gw_get_worktree_base)"
    # Replace slashes with double underscores for directory name
    local dir_name="${name//\//__}"
    local worktree_path="$worktree_base/$dir_name"

    # Check if worktree exists (use fixed string matching)
    if ! git worktree list | grep -F -- "$worktree_path" > /dev/null 2>&1; then
        echo "Worktree '$name' not found"
        return 1
    fi

    # Check for uncommitted changes before showing removal info
    _gw_check_uncommitted_changes "$worktree_path" "$name"
    local has_uncommitted=$?

    # Show what will be removed
    echo "This will remove the following worktree:"
    echo "  Path: $worktree_path"
    echo "  Branch: $name"
    if [ "$keep_branch" = true ]; then
        echo "  (Branch will be kept)"
    fi
    echo

    # Different confirmation message if there are uncommitted changes
    if [ $has_uncommitted -eq 1 ]; then
        echo "⚠️  This worktree has uncommitted changes that will be LOST."
        echo
        printf "Type 'YES' to confirm you want to remove this worktree with changes: "
        read -r REPLY
        if [ "$REPLY" != "YES" ]; then
            echo "Cancelled"
            return 1
        fi
    else
        printf "Are you sure you want to remove this worktree? [y/N] "
        read -r REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled"
            return 1
        fi
    fi

    # Check if we are in the worktree being removed and switch to main if so
    local current_dir main_repo_root
    current_dir="$(pwd)"
    main_repo_root="$(_gw_get_main_repo_root)"
    if [[ "$current_dir" == "$worktree_path" ]] || [[ "$current_dir" == "$worktree_path"/* ]]; then
        echo "You are currently in the worktree being removed. Switching to main repository root."
        if cd "$main_repo_root"; then
            echo "Switched to main repository root: $(pwd)"
        else
            echo "Warning: Failed to switch to main repository root: $main_repo_root" >&2
        fi
    fi

    # Remove the worktree (try safe removal first, then force)
    if git worktree remove "$worktree_path" 2>/dev/null; then
        echo "Successfully removed worktree '$name'"
        if [ "$keep_branch" = false ]; then
            _gw_handle_branch_deletion "$name"
        else
            echo "Branch '$name' kept as requested."
        fi
    elif git worktree remove --force "$worktree_path" 2>/dev/null; then
        echo "Warning: Forced removal of worktree (may have lost uncommitted changes)"
        echo "Successfully removed worktree '$name'"
        if [ "$keep_branch" = false ]; then
            _gw_handle_branch_deletion "$name"
        else
            echo "Branch '$name' kept as requested."
        fi
    else
        echo "Failed to remove worktree. It may have uncommitted changes."
        echo "Use 'git worktree remove --force $worktree_path' to force removal."
        echo "WARNING: This will lose any uncommitted changes!"
        return 1
    fi
}

# Navigate to a worktree or repo root
_gw_cd() {
    local name="$1"

    # If no name provided, go to the repository root
    if [ -z "$name" ]; then
        local current_dir main_repo_root
        current_dir="$(pwd)"
        main_repo_root="$(_gw_get_main_repo_root)"
        [ -z "$main_repo_root" ] && { echo "Not in a git repository"; return 1; }

        if [ "$current_dir" = "$main_repo_root" ]; then
            echo "Already in repository root: $main_repo_root"
        else
            cd "$main_repo_root" || return 1
            echo "Switched to repository root: $main_repo_root"
            echo "Current directory: $(pwd)"
        fi
        return 0
    fi

    # Validate the worktree name
    if ! _gw_validate_name "$name"; then
        return 1
    fi

    local worktree_base
    worktree_base="$(_gw_get_worktree_base)"
    # Replace slashes with double underscores for directory name
    local dir_name="${name//\//__}"
    local worktree_path="$worktree_base/$dir_name"

    if [ ! -d "$worktree_path" ]; then
        echo "Worktree '$name' not found at $worktree_path"
        echo "Available worktrees:"
        _gw_list
        return 1
    fi

    cd "$worktree_path" || return 1
    echo "Switched to worktree: $name"
    echo "Current directory: $(pwd)"
}

# List all worktrees for current repo
_gw_list() {
    local repo_root
    repo_root="$(_gw_get_main_repo_root)"
    if [ -z "$repo_root" ]; then
        repo_root="$(_gw_get_repo_root)"
        [ -z "$repo_root" ] && { echo "Not in a git repository"; return 1; }
    fi

    local worktree_base
    worktree_base="$(_gw_get_worktree_base)"
    echo "Worktree base: $(_gw_display_path "$worktree_base")"
    echo
    echo "Worktrees:"

    # Fetch latest from remote (silently)
    git fetch --quiet 2>/dev/null || true

    # Get the branch name from the main repository (the one outside .worktrees)
    local main_branch
    pushd "$repo_root" > /dev/null 2>&1
    main_branch="$(git branch --show-current 2>/dev/null)"
    popd > /dev/null 2>&1

    # Use the remote version of that branch for comparison
    local main_remote_branch=""
    if [ -n "$main_branch" ] && git show-ref --verify --quiet "refs/remotes/origin/$main_branch"; then
        main_remote_branch="origin/$main_branch"
    else
        # Fallback: try common main branch names
        if git show-ref --verify --quiet refs/remotes/origin/master; then
            main_remote_branch="origin/master"
        elif git show-ref --verify --quiet refs/remotes/origin/main; then
            main_remote_branch="origin/main"
        elif git show-ref --verify --quiet refs/remotes/origin/dev; then
            main_remote_branch="origin/dev"
        else
            # Last resort: use origin/HEAD
            local default_branch
            default_branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
            if [ -n "$default_branch" ] && git show-ref --verify --quiet "refs/remotes/origin/$default_branch"; then
                main_remote_branch="origin/$default_branch"
            fi
        fi
    fi

    # Get list of branches merged into the main remote branch
    local merged_branches
    if [ -n "$main_remote_branch" ]; then
        merged_branches="$(git branch --merged "$main_remote_branch" 2>/dev/null | sed 's/^[*+ ] *//')"
    else
        merged_branches=""
    fi

    local current_path
    current_path="$(pwd)"
    local found=false
    while IFS= read -r line; do
        local wt_path="" wt_branch="" wt_name=""
        wt_path="${line%% *}"
        wt_branch="${line##*\[}"
        wt_branch="${wt_branch%\]}"
        wt_name="${wt_path##*/}"
        local display_name="${wt_name//__/\/}"

        # Check if branch is merged
        local is_merged=false
        if echo "$merged_branches" | grep -Fxq "$wt_branch"; then
            is_merged=true
        fi

        # Check for uncommitted changes (always check, not just when merged)
        local has_changes=false
        if [ -d "$wt_path" ]; then
            pushd "$wt_path" > /dev/null 2>&1
            if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                has_changes=true
            fi
            popd > /dev/null 2>&1
        fi

        # Only show tick if: merged + no uncommitted changes + synced with origin
        local show_tick=false
        if [ "$is_merged" = true ] && [ "$has_changes" = false ] && [ -d "$wt_path" ]; then
            # Check if local branch is synced with origin (no unpushed commits)
            pushd "$wt_path" > /dev/null 2>&1
            local is_synced=true
            if git show-ref --verify --quiet "refs/remotes/origin/$wt_branch"; then
                # Compare local and remote
                local local_commit remote_commit
                local_commit="$(git rev-parse "$wt_branch" 2>/dev/null)"
                remote_commit="$(git rev-parse "origin/$wt_branch" 2>/dev/null)"
                if [ "$local_commit" != "$remote_commit" ]; then
                    is_synced=false
                fi
            fi
            popd > /dev/null 2>&1

            # Show tick only if merged, no changes, and synced
            if [ "$is_synced" = true ]; then
                show_tick=true
            fi
        fi

        # Check if we're in this worktree by comparing real paths
        # This ensures we only match if we're actually inside this worktree
        local is_current=false
        if [[ -d "$wt_path" ]]; then
            local current_real current_parent wt_real
            current_real="$(readlink -f "$current_path")"
            current_parent="$(readlink -f "$current_real/..")"
            wt_real="$(readlink -f "$wt_path")"
            # Check if we're at the worktree itself, or in a subdirectory of it
            # by checking if the current directory's parent equals the worktree,
            # or if current equals worktree
            if [[ "$current_parent" == "$wt_real" || "$current_real" == "$wt_real" ]]; then
                is_current=true
            fi
        fi

        if [ "$wt_path" = "$repo_root" ]; then
            found=true
            local marker="  -"
            if [ "$is_current" = true ]; then
                marker="  *"
            fi
            local status_indicator=""
            if [ "$show_tick" = true ]; then
                status_indicator=" [✓]"
            elif [ "$has_changes" = true ]; then
                status_indicator=" [*]"
            fi
            echo "$marker root$status_indicator: $(_gw_display_path "$wt_path") ($wt_branch)"
        elif [[ "$wt_path" == "$worktree_base"/* ]]; then
            found=true
            local marker="  -"
            if [ "$is_current" = true ]; then
                marker="  *"
            fi
            local status_indicator=""
            if [ "$show_tick" = true ]; then
                status_indicator=" [✓]"
            elif [ "$has_changes" = true ]; then
                status_indicator=" [*]"
            fi
            echo "$marker $display_name$status_indicator: $(_gw_display_path "$wt_path") ($wt_branch)"
        fi
    done < <(git worktree list)

    if [ "$found" = false ]; then
        echo "  No worktrees found"
    fi
}


# Clean all worktrees
_gw_clean() {
    local repo_root
    repo_root="$(_gw_get_repo_root)"
    [ -z "$repo_root" ] && { echo "Not in a git repository"; return 1; }

    local worktree_base
    worktree_base="$(_gw_get_worktree_base)"

    echo "WARNING: This will remove ALL worktrees for this repository!"
    echo "Worktrees to be removed:"

    local count=0
    local has_uncommitted=false
    while IFS= read -r line; do
        local path
        path=$(echo "$line" | awk '{print $1}')
        # Skip the main repository
        if [ "$path" = "$repo_root" ]; then
            continue
        fi
        # Check if this worktree is in our worktree base
        if [[ "$path" == "$worktree_base"/* ]]; then
            local branch
            branch=$(echo "$line" | sed -n 's/.*\[\(.*\)\].*/\1/p')
            echo "  - $path ($branch)"
            count=$((count + 1))

            # Check for uncommitted changes in this worktree
            if [ -d "$path" ]; then
                pushd "$path" > /dev/null 2>&1
                if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
                    has_uncommitted=true
                fi
                popd > /dev/null 2>&1
            fi
        fi
    done < <(git worktree list)

    if [ "$count" -eq 0 ]; then
        echo "No worktrees to remove"
        return 0
    fi

    echo
    if [ "$has_uncommitted" = true ]; then
        echo "⚠️  WARNING: Some worktrees have uncommitted changes that will be LOST."
        echo
    fi
    echo "This action cannot be undone!"
    printf "Type 'yes' to confirm: "
    read -r REPLY

    if [ "$REPLY" != "yes" ]; then
        echo "Cancelled"
        return 1
    fi

    # Remove all worktrees
    local removed_worktrees=()
    while IFS= read -r line; do
        local path
        path=$(echo "$line" | awk '{print $1}')
        # Skip the main repository
        if [ "$path" = "$repo_root" ]; then
            continue
        fi
        # Check if this worktree is in our worktree base
        if echo "$path" | grep -F -- "$worktree_base" > /dev/null 2>&1; then
            local dir_name worktree_name
            dir_name=$(basename "$path")
            # Convert directory name back to branch name (__ -> /)
            worktree_name="${dir_name//__/\/}"
            echo "Removing: $path"
            # Try safe removal first
            if git worktree remove "$path" 2>/dev/null; then
                removed_worktrees+=("$worktree_name")
            elif git worktree remove --force "$path" 2>/dev/null; then
                echo "  Warning: Used force removal for $path"
                removed_worktrees+=("$worktree_name")
            else
                echo "  Error: Failed to remove $path"
            fi
        fi
    done < <(git worktree list)

    # Handle branch deletion for all removed worktrees
    for worktree_name in "${removed_worktrees[@]}"; do
        _gw_handle_branch_deletion "$worktree_name"
    done

    echo "All worktrees removed"

    # Try to remove the worktree base directory if empty
    if [ -d "$worktree_base" ] && [ -z "$(ls -A "$worktree_base")" ]; then
        rmdir "$worktree_base" 2>/dev/null && echo "Removed empty worktree base directory"
    fi
}

# Bash/Zsh completion for gw
if [ -n "${BASH_VERSION:-}" ]; then
    _gw_complete() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local cmd="${COMP_WORDS[1]}"

        if [ "$COMP_CWORD" -eq 1 ]; then
            # Use readarray if available, otherwise fall back to direct assignment
            if command -v mapfile >/dev/null 2>&1; then
                mapfile -t COMPREPLY < <(compgen -W "create review rm remove cd list ls clean tab help" -- "$cur")
            else
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "create review rm remove cd list ls clean tab help" -- "$cur"))
            fi
        elif [ "$cmd" = "review" ] && [ "$COMP_CWORD" -eq 2 ]; then
            # Complete with existing branch names (local and remote), excluding dependabot branches
            local branches=""
            # Get local branches
            while IFS= read -r branch; do
                if [ -n "$branch" ] && [[ ! "$branch" =~ ^dependabot/ ]]; then
                    branches="$branches$branch "
                fi
            done < <(git branch --format='%(refname:short)' 2>/dev/null)
            # Get remote branches (without origin/ prefix)
            while IFS= read -r branch; do
                if [ -n "$branch" ]; then
                    local clean_branch="${branch#origin/}"
                    if [[ ! "$clean_branch" =~ ^dependabot/ ]]; then
                        branches="$branches$clean_branch "
                    fi
                fi
            done < <(git branch -r --format='%(refname:short)' 2>/dev/null | grep '^origin/')

            if command -v mapfile >/dev/null 2>&1; then
                mapfile -t COMPREPLY < <(compgen -W "$branches" -- "$cur")
            else
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "$branches" -- "$cur"))
            fi
        elif [ "$cmd" = "create" ] && [ "$COMP_CWORD" -eq 2 ]; then
            # Complete with existing branch names (local and remote), excluding dependabot branches
            local branches=""
            # Get local branches
            while IFS= read -r branch; do
                if [ -n "$branch" ] && [[ ! "$branch" =~ ^dependabot/ ]]; then
                    branches="$branches$branch "
                fi
            done < <(git branch --format='%(refname:short)' 2>/dev/null)
            # Get remote branches (without origin/ prefix)
            while IFS= read -r branch; do
                if [ -n "$branch" ]; then
                    local clean_branch="${branch#origin/}"
                    if [[ ! "$clean_branch" =~ ^dependabot/ ]]; then
                        branches="$branches$clean_branch "
                    fi
                fi
            done < <(git branch -r --format='%(refname:short)' 2>/dev/null | grep '^origin/')

            if command -v mapfile >/dev/null 2>&1; then
                mapfile -t COMPREPLY < <(compgen -W "$branches" -- "$cur")
            else
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "$branches" -- "$cur"))
            fi
        elif [ "$cmd" = "create" ] && [ "$COMP_CWORD" -ge 3 ]; then
            # Completion for arguments after `gw create <name>`
            local last_word="${COMP_WORDS[COMP_CWORD-1]}"
            local options="--stay --tabs"

            # If the last word was not a flag, we might be looking for a directory
            if [[ ! "$last_word" =~ ^-- ]]; then
                local worktree_base
                worktree_base="$(_gw_get_worktree_base 2>/dev/null)"
                if [ -n "$worktree_base" ] && [ -d "$worktree_base" ]; then
                    # Add existing directory names as completion options
                    while IFS= read -r dir_name; do
                        if [ -n "$dir_name" ]; then
                            options="$options $dir_name"
                        fi
                    done < <(ls "$worktree_base" 2>/dev/null)
                fi
            fi

            if command -v mapfile >/dev/null 2>&1; then
                mapfile -t COMPREPLY < <(compgen -W "$options" -- "$cur")
            else
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "$options" -- "$cur"))
            fi
        elif [ "$cmd" = "cd" ] && [ "$COMP_CWORD" -eq 2 ]; then
            # Complete with worktree names (safely handle special characters)
            local worktree_base
            worktree_base="$(_gw_get_worktree_base 2>/dev/null)"
            if [ -n "$worktree_base" ] && [ -d "$worktree_base" ]; then
                local names=""
                # Convert directory names back to branch names for completion
                while IFS= read -r dir_name; do
                    if [ -n "$dir_name" ]; then
                        local branch_name="${dir_name//__/\/}"
                        names="$names$branch_name "
                    fi
                done < <(ls "$worktree_base" 2>/dev/null)
                if command -v mapfile >/dev/null 2>&1; then
                    mapfile -t COMPREPLY < <(compgen -W "$names" -- "$cur")
                else
                    # shellcheck disable=SC2207
                    COMPREPLY=($(compgen -W "$names" -- "$cur"))
                fi
            fi
        elif [[ "$cmd" =~ ^(rm|remove)$ ]] && [ "$COMP_CWORD" -eq 2 ]; then
            # Complete with worktree names (safely handle special characters)
            local worktree_base
            worktree_base="$(_gw_get_worktree_base 2>/dev/null)"
            if [ -n "$worktree_base" ] && [ -d "$worktree_base" ]; then
                local names=""
                # Convert directory names back to branch names for completion
                while IFS= read -r dir_name; do
                    if [ -n "$dir_name" ]; then
                        local branch_name="${dir_name//__/\/}"
                        names="$names$branch_name "
                    fi
                done < <(ls "$worktree_base" 2>/dev/null)
                if command -v mapfile >/dev/null 2>&1; then
                    mapfile -t COMPREPLY < <(compgen -W "$names" -- "$cur")
                else
                    # shellcheck disable=SC2207
                    COMPREPLY=($(compgen -W "$names" -- "$cur"))
                fi
            fi
        elif [[ "$cmd" =~ ^(rm|remove)$ ]] && [ "$COMP_CWORD" -eq 3 ]; then
            if command -v mapfile >/dev/null 2>&1; then
                mapfile -t COMPREPLY < <(compgen -W "--keep-branch" -- "$cur")
            else
                # shellcheck disable=SC2207
                COMPREPLY=($(compgen -W "--keep-branch" -- "$cur"))
            fi
        fi
    }
    complete -F _gw_complete gw

elif [ -n "${ZSH_VERSION:-}" ]; then
    # Only set up completion if we're in an interactive shell with completion system
    if [[ -o interactive ]] && command -v compdef &>/dev/null 2>&1; then
        _gw_complete() {
            # These variables are set by ZSH completion system
            # shellcheck disable=SC2034,SC2154
            local -a commands worktree_names

            # shellcheck disable=SC2034  # Used by _describe function below
            commands=(
                'create:Create a new worktree'
                'review:Create worktree from existing branch'
                'rm:Remove a worktree'
                'remove:Remove a worktree'
                'cd:Navigate to a worktree'
                'list:List all worktrees'
                'ls:List all worktrees'
                'clean:Remove all worktrees'
                'tab:Add a yakuake tab'
                'help:Show help'
            )

            # shellcheck disable=SC2154  # 'words' is set by ZSH completion system
            case "${words[2]}" in
                review)
                    if [ "$CURRENT" -eq 3 ]; then
                        # Complete with existing branch names, excluding dependabot branches
                        local -a branch_names
                        branch_names=()
                        # Get local branches
                        while IFS= read -r branch; do
                            if [ -n "$branch" ] && [[ ! "$branch" =~ ^dependabot/ ]]; then
                                branch_names+=("$branch:local branch")
                            fi
                        done < <(git branch --format='%(refname:short)' 2>/dev/null)
                        # Get remote branches (without origin/ prefix)
                        while IFS= read -r branch; do
                            if [ -n "$branch" ]; then
                                local clean_branch="${branch#origin/}"
                                if [[ ! "$clean_branch" =~ ^dependabot/ ]]; then
                                    branch_names+=("$clean_branch:remote branch")
                                fi
                            fi
                        done < <(git branch -r --format='%(refname:short)' 2>/dev/null | grep '^origin/')
                        _describe 'branch' branch_names
                    fi
                    ;;
                create)
                    if [ "$CURRENT" -eq 3 ]; then
                        # Complete with existing branch names, excluding dependabot branches
                        local -a branch_names
                        branch_names=()
                        # Get local branches
                        while IFS= read -r branch; do
                            if [ -n "$branch" ] && [[ ! "$branch" =~ ^dependabot/ ]]; then
                                branch_names+=("$branch:local branch")
                            fi
                        done < <(git branch --format='%(refname:short)' 2>/dev/null)
                        # Get remote branches (without origin/ prefix)
                        while IFS= read -r branch; do
                            if [ -n "$branch" ]; then
                                local clean_branch="${branch#origin/}"
                                if [[ ! "$clean_branch" =~ ^dependabot/ ]]; then
                                    branch_names+=("$clean_branch:remote branch")
                                fi
                            fi
                        done < <(git branch -r --format='%(refname:short)' 2>/dev/null | grep '^origin/')
                        _describe 'branch' branch_names
                    elif [ "$CURRENT" -ge 4 ]; then
                        # Complete with directory names from worktree_base or flags
                        local worktree_base
                        worktree_base="$(_gw_get_worktree_base 2>/dev/null)"
                        local -a dir_options=('--stay:stay in current directory' '--tabs:create yakuake tabs')
                        if [ -n "$worktree_base" ] && [ -d "$worktree_base" ]; then
                            # Add existing directory names
                            while IFS= read -r dir_name; do
                                if [ -n "$dir_name" ]; then
                                    dir_options+=("$dir_name:existing worktree directory")
                                fi
                            done < <(ls "$worktree_base" 2>/dev/null)
                        fi
                        _describe 'directory or flag' dir_options
                    fi
                    ;;
                rm|remove|cd)
                    if [[ "${words[2]}" =~ ^(rm|remove)$ ]] && [ "$CURRENT" -eq 4 ]; then
                        local -a flags=(--keep-branch:keep the branch)
                        _describe 'flag' flags
                    elif [ "$CURRENT" -eq 3 ]; then
                        local worktree_base
                        worktree_base="$(_gw_get_worktree_base 2>/dev/null)"
                        if [ -n "$worktree_base" ] && [ -d "$worktree_base" ]; then
                            # Safely populate array with converted names
                            worktree_names=()
                            while IFS= read -r dir_name; do
                                if [ -n "$dir_name" ]; then
                                    local branch_name="${dir_name//__/\/}"
                                    worktree_names+=("$branch_name")
                                fi
                            done < <(ls "$worktree_base" 2>/dev/null)
                            _describe 'worktree' worktree_names
                        fi
                    fi
                    ;;
                *)
                    if [ "$CURRENT" -eq 2 ]; then
                        _describe 'command' commands
                    fi
                    ;;
            esac
        }

        compdef _gw_complete gw 2>/dev/null
    fi
fi

# Return success
return 0 2>/dev/null || true
