"""Shared substitution rules for opencode generators.

Imported by generate-opencode-agents.py, generate-opencode-commands.py,
and generate-opencode-skills.py to ensure consistent transformation of
Claude-specific content into opencode-compatible content.
"""
import re

BODY_SUBS = [
    # Agent cross-references: Claude invokes via Task(subagent_type="bee:foo").
    # Opencode resolves agents by filename, and we install them as bee-foo.md.
    (re.compile(r'\bbee:([a-z][a-z0-9-]*)\b'), r'bee-\1'),
    # Script path: Claude's $CLAUDE_PLUGIN_ROOT becomes a fixed install location
    # that the opencode install script symlinks from the plugin package.
    (
        re.compile(r'\$\{CLAUDE_PLUGIN_ROOT\}/scripts/'),
        r'$HOME/.config/opencode/bee/scripts/',
    ),
    # State script invocation: prefix BEE_DIR=.opencode so the state script
    # writes to .opencode/ instead of .claude/. Must come after the path
    # substitution above since it matches the transformed text.
    (
        re.compile(r'("\$HOME/\.config/opencode/bee/scripts/update-bee-state\.sh")'),
        r'BEE_DIR=.opencode \1',
    ),
    # Strip the "Deferred Tool Loading" preamble — opencode has no equivalent
    # ToolSearch concept, and its tool schemas are always available.
    (
        re.compile(
            r'\*\*IMPORTANT\s+[—-]\s+Deferred Tool Loading:\*\*[^\n]*(?:\n[^\n]+)*?(?=\n\n)',
            re.MULTILINE,
        ),
        '',
    ),
    # Tool name substitutions: Claude PascalCase -> opencode lowercase.
    (re.compile(r'\bAskUserQuestion\b'), 'question'),
    (re.compile(r'\bTodoWrite\b'), 'todowrite'),
    (re.compile(r'\bTaskCreate\b'), 'todowrite'),
    (re.compile(r'\bTaskUpdate\b'), 'todowrite'),
    (re.compile(r'\bTaskList\b'), 'todowrite'),
    (re.compile(r'\bTaskGet\b'), 'todowrite'),
    (re.compile(r'\bTaskStop\b'), 'todowrite'),
    (re.compile(r'\bTaskOutput\b'), 'todowrite'),
    (re.compile(r'\bWebSearch\b'), 'websearch'),
    (re.compile(r'\bWebFetch\b'), 'webfetch'),
    (re.compile(r'\bToolSearch\b'), 'tool schema search (not needed on opencode)'),
    # File paths: .claude/ → .opencode/ for opencode port. Special-case
    # CLAUDE.md → AGENTS.md first (opencode reads AGENTS.md, not CLAUDE.md).
    (re.compile(r'\.claude/CLAUDE\.md'), '.opencode/AGENTS.md'),
    # Bare CLAUDE.md references (without path) also need to become AGENTS.md.
    # Must come after the path-prefixed rule above.
    (re.compile(r'\bCLAUDE\.md\b'), 'AGENTS.md'),
    (re.compile(r'\.claude/'), '.opencode/'),
    # mkdir: the above misses bare .claude without trailing slash (e.g.
    # "mkdir -p .claude" in bash heredoc blocks).
    (re.compile(r'mkdir -p \.claude\b'), 'mkdir -p .opencode'),
    # Collapse any double-blank-lines introduced by stripped paragraphs.
    (re.compile(r'\n{3,}'), '\n\n'),
]