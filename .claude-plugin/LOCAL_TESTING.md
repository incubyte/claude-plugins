# Local Testing Guide

Quick guide to test the marketplace locally without conflicts with the remote version.

## Setup

The marketplace uses different names to avoid conflicts:

- **Remote:** `incubyte-plugins`
- **Local:** `incubyte-plugins-local` [Change the marketplace name in `.claude-plugin/marketplace.json`]

This allows testing both simultaneously.

## Quick Test

```bash
# 1. Validate marketplace
/plugin validate .

# 2. Add local marketplace
/plugin marketplace add ./

# 3. Verify it's added
/plugin marketplace list

# 4. Install plugins
/plugin install bee@incubyte-plugins-local
/plugin install ralph-wiggum@incubyte-plugins-local

# 5. Test the plugins
/bee:build
/ralph
```

## Cleanup

```bash
# Remove plugins
/plugin uninstall bee@incubyte-plugins-local
/plugin uninstall ralph-wiggum@incubyte-plugins-local

# Remove marketplace
/plugin marketplace remove incubyte-plugins-local
```

## Before Publishing

**Important:** Change the marketplace name back to `incubyte-plugins` in `.claude-plugin/marketplace.json`:

```json
{
  "name": "incubyte-plugins",  // ← Change from "incubyte-plugins-local"
  ...
}
```

## Troubleshooting

| Issue                         | Solution                                     |
| ----------------------------- | -------------------------------------------- |
| Marketplace already installed | Use different name: `incubyte-plugins-local` |
| Plugin not found              | Check `./bee` directory exists               |
| Ralph-wiggum fails            | Verify internet connection and GitHub access |
| Commands not showing          | Run `/debug` to see loading details          |

## Reference

- **Marketplace config:** `.claude-plugin/marketplace.json`
- **Bee plugin:** `./bee/`
- **Ralph-wiggum source:** https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum
