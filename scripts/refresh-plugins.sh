#!/bin/bash
# refresh-plugins.sh -- Refresh/install the Antariksh Skills plugin across Claude Code,
# Codex CLI, and skills.sh agent directories. Intended for WSL/macOS/Linux where the
# `claude`, `codex`, and `npx` CLIs are installed.
#
# Usage: bash scripts/refresh-plugins.sh
set -uo pipefail

REPO_SLUG="antarikshkarmakar/antarikshSkills"
CLAUDE_MARKETPLACE="antariksh-skills-marketplace"
CODEX_MARKETPLACE="antariksh-skills"
PLUGIN_NAME="antariksh-skills"
FAILED=0

section() { printf '\n\033[36m== %s ==\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
note() { printf '\033[33mINFO: %s\033[0m\n' "$1"; }
mark_failed() {
    printf '\033[31mERROR: %s\033[0m\n' "$1" >&2
    FAILED=1
}

# --- Codex CLI ---
if have codex; then
    section "Codex CLI"
    # Register the marketplace on first run; harmless if already registered.
    codex plugin marketplace add "$REPO_SLUG" 2>/dev/null \
        || note "Codex marketplace may already be registered; continuing to refresh it."
    # Pull latest marketplace catalog, then install/refresh the plugin.
    codex plugin marketplace upgrade "$CODEX_MARKETPLACE" \
        || mark_failed "Codex marketplace upgrade failed. Update Codex or run the command manually."
    codex plugin add "$PLUGIN_NAME@$CODEX_MARKETPLACE" \
        || mark_failed "Codex plugin add failed for $PLUGIN_NAME@$CODEX_MARKETPLACE."
    codex plugin list \
        || mark_failed "Codex plugin list failed after refresh."
else
    echo "SKIP: codex CLI not found on PATH."
fi

# --- Claude Code ---
if have claude; then
    section "Claude Code"
    # Register the marketplace on first run; harmless if already registered.
    claude plugin marketplace add "$REPO_SLUG" 2>/dev/null \
        || note "Claude marketplace may already be registered; continuing to refresh it."
    # 'add' does NOT re-fetch an already-registered marketplace; 'update' does.
    claude plugin marketplace update "$CLAUDE_MARKETPLACE" \
        || mark_failed "Claude marketplace update failed for $CLAUDE_MARKETPLACE."
    if ! claude plugin install "$PLUGIN_NAME@$CLAUDE_MARKETPLACE"; then
        note "Claude plugin install did not complete; trying plugin update instead."
        claude plugin update "$PLUGIN_NAME@$CLAUDE_MARKETPLACE" \
            || mark_failed "Claude plugin install/update failed for $PLUGIN_NAME@$CLAUDE_MARKETPLACE."
    fi
    claude plugin list \
        || mark_failed "Claude plugin list failed after refresh."
else
    echo "SKIP: claude CLI not found on PATH."
fi

# --- skills.sh (npx skills) ---
if have npx; then
    section "skills.sh"
    # --full-depth is required: the repo has a root SKILL.md, and without the flag
    # the CLI stops there instead of discovering the 23 skills under skills/.
    # Review the Gen/Socket/Snyk risk assessment shown before confirming installs.
    npx --yes skills@latest add "$REPO_SLUG" --full-depth --skill '*' -g -a codex -a claude-code -y \
        || mark_failed "skills.sh add failed for $REPO_SLUG."
    npx --yes skills@latest list -g \
        || mark_failed "skills.sh global list failed after refresh."
else
    echo "SKIP: npx not found on PATH."
fi

if [ "$FAILED" -ne 0 ]; then
    printf '\n\033[31mRefresh completed with errors. Review the messages above before assuming plugins are updated.\033[0m\n' >&2
    exit 1
fi

printf '\n\033[32mDone. In Claude Code, skills are namespaced as /%s:<skill> (e.g. /%s:align).\033[0m\n' "$PLUGIN_NAME" "$PLUGIN_NAME"
