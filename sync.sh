#!/usr/bin/env bash
#
# sync.sh - sync local dotfiles with the ppeble/dotfiles repo
#
# Subcommands:
#   backup            Copy local dotfiles into a fresh clone, push a branch,
#                     and open a PR with the changes.
#   restore           Copy the repo's dotfiles down to the local machine.
#     --dry-run       Show what would be copied without writing anything.
#
# Workdir: ~/tmp/dotfiles-sync (override with DOTFILES_WORKDIR).
#
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-git@github.com:ppeble/dotfiles.git}"
REPO_SLUG="${DOTFILES_REPO_SLUG:-ppeble/dotfiles}"
DEFAULT_BRANCH="${DOTFILES_DEFAULT_BRANCH:-master}"
WORKDIR="${DOTFILES_WORKDIR:-$HOME/tmp/dotfiles-sync}"
BACKUP_ROOT="${DOTFILES_BACKUP_ROOT:-$HOME/tmp/dotfiles-sync/backups}"

# Mapping of repo-relative paths to local paths.
# Format: "repo_path::local_path". Either may be a file or a directory.
MAPPINGS=(
  ".tmux.conf::$HOME/.tmux.conf"
  ".zshrc::$HOME/.zshrc"
  ".vimrc::$HOME/.vimrc"
  ".bash_profile::$HOME/.bash_profile"
  "nvim::$HOME/.config/nvim"
)

# Regex (perl, case-insensitive) matching variable names whose values should
# be scrubbed before committing. Override with DOTFILES_REDACT_VAR_REGEX.
REDACT_VAR_REGEX="${DOTFILES_REDACT_VAR_REGEX:-(TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|ACCESS_KEY|PRIVATE_KEY|CREDENTIAL|SLACK_TEAM)}"

# Known secret prefixes used as a post-redaction safety net. If any survive
# after redaction, we abort the backup rather than push.
SECRET_SIGNATURES=(
  'xox[baprs]-'         # Slack
  'glpat-'              # GitLab personal access token
  'gh[pousr]_[A-Za-z0-9]{30,}'  # GitHub
  'AKIA[0-9A-Z]{16}'    # AWS access key
  'sk_live_[0-9a-zA-Z]{20,}'    # Stripe
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)

log()  { printf '[sync] %s\n' "$*" >&2; }
warn() { printf '[sync] WARN: %s\n' "$*" >&2; }
die()  { printf '[sync] ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

require() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "missing required command: $cmd"
  done
}

ensure_clone() {
  mkdir -p "$WORKDIR"
  local clone_dir="$WORKDIR/dotfiles"
  if [[ -d "$clone_dir/.git" ]]; then
    log "refreshing clone at $clone_dir"
    git -C "$clone_dir" remote set-url origin "$REPO_URL"
    git -C "$clone_dir" fetch origin --prune --quiet
    git -C "$clone_dir" checkout --quiet "$DEFAULT_BRANCH"
    git -C "$clone_dir" reset --hard --quiet "origin/$DEFAULT_BRANCH"
    git -C "$clone_dir" clean -fdx --quiet -e backups
  else
    log "cloning $REPO_URL into $clone_dir"
    git clone --quiet "$REPO_URL" "$clone_dir"
  fi
  printf '%s' "$clone_dir"
}

# copy SRC DST, where either may be file or directory.
# Creates parent dirs as needed. Uses rsync when available for directories.
copy_path() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || { warn "skip missing source: $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  if [[ -d "$src" ]]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --delete "$src/" "$dst/"
    else
      rm -rf "$dst"
      mkdir -p "$dst"
      cp -R "$src/." "$dst/"
    fi
  else
    cp -p "$src" "$dst"
  fi
}

redact_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  REDACT_VAR_REGEX="$REDACT_VAR_REGEX" \
  REDACT_IPS="${DOTFILES_REDACT_IPS:-1}" \
  awk '
    BEGIN {
      kw = tolower(ENVIRON["REDACT_VAR_REGEX"])
      var_re = "^[[:space:]]*(export[[:space:]]+)?[a-z_][a-z0-9_]*" kw "[a-z0-9_]*[[:space:]]*="
      redact_ips = (ENVIRON["REDACT_IPS"] != "0")
      ip_re = "([0-9]{1,3}\\.){3}[0-9]{1,3}"
    }
    {
      line = $0
      lower = tolower(line)
      if (match(lower, var_re)) {
        eq = index(line, "=")
        if (eq > 0) {
          prefix = substr(line, 1, eq - 1)
          sub(/[[:space:]]+$/, "", prefix)
          line = prefix "=\"REDACTED\"  # redacted by sync.sh"
        }
      }
      if (redact_ips) {
        out = ""
        rest = line
        while (match(rest, ip_re)) {
          ip = substr(rest, RSTART, RLENGTH)
          before = substr(rest, 1, RSTART - 1)
          after  = substr(rest, RSTART + RLENGTH)
          prev_ch = (RSTART > 1) ? substr(rest, RSTART - 1, 1) : ""
          next_ch = substr(after, 1, 1)
          bounded = (prev_ch !~ /[0-9.]/) && (next_ch !~ /[0-9.]/)
          if (bounded && ip != "127.0.0.1" && ip != "0.0.0.0" && ip != "255.255.255.255") {
            out = out before "REDACTED_IP"
          } else {
            out = out before ip
          }
          rest = after
        }
        line = out rest
      }
      print line
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

redact_tree() {
  local target="$1"
  if [[ -d "$target" ]]; then
    while IFS= read -r -d '' f; do
      redact_file "$f"
    done < <(find "$target" -type f -print0)
  else
    redact_file "$target"
  fi
}

scan_for_secrets() {
  local root="$1"
  local pattern
  pattern="$(IFS='|'; echo "${SECRET_SIGNATURES[*]}")"
  if grep -RInE "$pattern" "$root" >&2; then
    return 1
  fi
  return 0
}

backup_local() {
  local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
  local dest="$BACKUP_ROOT/$stamp"
  mkdir -p "$dest"
  log "backing up current local dotfiles to $dest"
  for entry in "${MAPPINGS[@]}"; do
    local local_path="${entry##*::}"
    local rel="${entry%%::*}"
    if [[ -e "$local_path" ]]; then
      copy_path "$local_path" "$dest/$rel"
    fi
  done
  printf '%s' "$dest"
}

cmd_backup() {
  require git gh rsync awk grep find
  local clone_dir; clone_dir="$(ensure_clone)"

  local backup_dir; backup_dir="$(backup_local)"
  log "local backup saved at $backup_dir"

  log "copying local dotfiles into clone"
  for entry in "${MAPPINGS[@]}"; do
    local rel="${entry%%::*}"
    local local_path="${entry##*::}"
    if [[ ! -e "$local_path" ]]; then
      warn "local path missing, skipping: $local_path"
      continue
    fi
    copy_path "$local_path" "$clone_dir/$rel"
  done

  log "redacting secrets in synced files (pattern: $REDACT_VAR_REGEX)"
  for entry in "${MAPPINGS[@]}"; do
    local rel="${entry%%::*}"
    redact_tree "$clone_dir/$rel"
  done

  if ! scan_for_secrets "$clone_dir"; then
    die "post-redaction scan found suspected secrets above. Refusing to push. Adjust DOTFILES_REDACT_VAR_REGEX or scrub the source file, then retry."
  fi

  if git -C "$clone_dir" diff --quiet && git -C "$clone_dir" diff --cached --quiet; then
    if [[ -z "$(git -C "$clone_dir" status --porcelain)" ]]; then
      log "no changes to sync. Local dotfiles already match the repo."
      return 0
    fi
  fi

  local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
  local branch="sync/local-${stamp}"
  log "creating branch $branch"
  git -C "$clone_dir" checkout -b "$branch" >/dev/null

  git -C "$clone_dir" add -A
  local summary
  summary="$(git -C "$clone_dir" diff --cached --stat | tail -n 1 || true)"
  git -C "$clone_dir" -c user.useConfigOnly=true commit -m "Sync dotfiles from local ($stamp)" \
    -m "Automated sync via sync.sh. ${summary}" >/dev/null

  log "pushing branch to origin"
  git -C "$clone_dir" push --quiet -u origin "$branch"

  log "opening pull request via gh"
  (
    cd "$clone_dir"
    gh pr create \
      --base "$DEFAULT_BRANCH" \
      --head "$branch" \
      --title "Sync dotfiles from local ($stamp)" \
      --body "Automated sync from local machine via \`sync.sh\`.

Backup of pre-sync local state: \`$backup_dir\`

$summary"
  )
}

cmd_restore() {
  require git rsync
  local dry_run=0
  for arg in "$@"; do
    case "$arg" in
      --dry-run|-n) dry_run=1 ;;
      -h|--help) usage 0 ;;
      *) die "unknown restore option: $arg" ;;
    esac
  done

  local clone_dir; clone_dir="$(ensure_clone)"

  if (( dry_run )); then
    log "dry-run: showing what would change. No files written."
  else
    local backup_dir; backup_dir="$(backup_local)"
    log "local backup saved at $backup_dir"
  fi

  for entry in "${MAPPINGS[@]}"; do
    local rel="${entry%%::*}"
    local local_path="${entry##*::}"
    local src="$clone_dir/$rel"
    if [[ ! -e "$src" ]]; then
      warn "repo path missing, skipping: $rel"
      continue
    fi

    if (( dry_run )); then
      if [[ -d "$src" ]]; then
        if [[ -d "$local_path" ]]; then
          rsync -ain --delete "$src/" "$local_path/" \
            | sed "s|^|[would] $local_path/|"
        else
          printf '[would] create directory %s and populate from %s\n' "$local_path" "$rel"
        fi
      else
        if [[ -e "$local_path" ]] && cmp -s "$src" "$local_path"; then
          printf '[same]  %s\n' "$local_path"
        else
          printf '[would] write %s from %s\n' "$local_path" "$rel"
        fi
      fi
    else
      log "restoring $rel -> $local_path"
      copy_path "$src" "$local_path"
    fi
  done

  if (( dry_run )); then
    log "dry-run complete. Re-run without --dry-run to apply."
  else
    log "restore complete."
  fi
}

main() {
  local sub="${1:-}"
  [[ -n "$sub" ]] || usage 1
  shift || true
  case "$sub" in
    backup)  cmd_backup "$@" ;;
    restore) cmd_restore "$@" ;;
    -h|--help|help) usage 0 ;;
    *) die "unknown subcommand: $sub (try: backup, restore)" ;;
  esac
}

main "$@"
