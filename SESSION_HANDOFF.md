# Session Handoff - 2026-01-19

## Completed This Session

### Security Audit & Fixes
- Added transient/concealed clipboard type detection (password protection)
- Added hardcoded password manager bundle IDs exclusion list
- Added `.completeFileProtection` for `history.json` persistence

### Refactoring
- Extracted `ClipboardManager`, `SettingsModel` to `Core/`
- Extracted `ClipboardItem`, `SavedClipboardItem` to `Core/Models/`
- Extracted `ClipboardHistoryView`, `ClipboardItemRow` to `UI/History/`

### UI/UX Improvements
- Single click to paste (removed redundant document icon button)
- Code detection with monospaced font
- Stats now show 'wd' and 'ch' for clarity
- Added 'Paste as Plain Text' to context menu

## Current State

**Security audit complete. UI refreshed.** Ready for release.

## Pending Tasks

### ⚠️ UPDATE MARKETING IMAGES
- Screenshots in `docs/images/` are outdated (old UI with paste buttons)
- Need new screenshots showing:
  - Clean row design (no document icon)
  - "wd · ch" stats format
  - Single-click interaction

### Other
- Verify appcast.xml is current before release
- Consider adding unit tests for `ClipboardManager`

## Bundle IDs (DO NOT CONFUSE)

| Config | Bundle ID | Use |
|--------|-----------|-----|
| Debug | `com.saneclip.dev` | Local testing ONLY |
| Release | `com.saneclip.app` | Production/users |

## Quick Commands

```bash
# Clean launch (ALWAYS use this pattern)
killall SaneClip 2>/dev/null; sleep 1; pgrep SaneClip && echo "ABORT" || open /path/to/SaneClip.app

# Reset onboarding (debug only)
defaults delete com.saneclip.dev hasCompletedOnboarding

# Build
xcodebuild -project SaneClip.xcodeproj -scheme SaneClip -configuration Debug build
```
