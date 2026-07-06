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

section() { printf '\n\033[36m== %s ==\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- Codex CLI ---
if have codex; then
    section "Codex CLI"
    # Register the marketplace on first run; harmless if already registered.
    codex plugin marketplace add "$REPO_SLUG" 2>/dev/null || true
    # Pull latest marketplace catalog, then install/refresh the plugin.
    codex plugin marketplace upgrade "$CODEX_MARKETPLACE" || echo "WARN: codex marketplace upgrade failed (older codex? run 'codex update')."
    codex plugin add "$PLUGIN_NAME@$CODEX_MARKETPLACE" || true
    codex plugin list
else
    echo "SKIP: codex CLI not found on PATH."
fi

# --- Claude Code ---
if have claude; then
    section "Claude Code"
    # Register the marketplace on first run; harmless if already registered.
    claude plugin marketplace add "$REPO_SLUG" 2>/dev/null || true
    # 'add' does NOT re-fetch an already-registered marketplace; 'update' does.
    claude plugin marketplace update "$CLAUDE_MARKETPLACE"
    claude plugin install "$PLUGIN_NAME@$CLAUDE_MARKETPLACE" 2>/dev/null \
        || claude plugin update "$PLUGIN_NAME@$CLAUDE_MARKETPLACE"
    claude plugin list
else
    echo "SKIP: claude CLI not found on PATH."
fi

# --- skills.sh (npx skills) ---
if have npx; then
    section "skills.sh"
    # --full-depth is required: the repo has a root SKILL.md, and without the flag
    # the CLI stops there instead of discovering the 21 skills under skills/.
    # Review the Gen/Socket/Snyk risk assessment shown before confirming installs.
    npx --yes skills@latest add "$REPO_SLUG" --full-depth --skill '*' -g -a codex -a claude-code -y
    npx --yes skills@latest list -g
else
    echo "SKIP: npx not found on PATH."
fi

printf '\n\033[32mDone. In Claude Code, skills are namespaced as /%s:<skill> (e.g. /%s:align).\033[0m\n' "$PLUGIN_NAME" "$PLUGIN_NAME"
