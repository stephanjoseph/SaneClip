# Session Handoff - 2026-01-24

> **Navigation**
> | Bugs | Features | How to Work | Releases | Testimonials |
> |------|----------|-------------|----------|--------------|
> | [BUG_TRACKING.md](BUG_TRACKING.md) | [marketing/feature-requests.md](marketing/feature-requests.md) | [DEVELOPMENT.md](DEVELOPMENT.md) | [CHANGELOG.md](CHANGELOG.md) | [marketing/testimonials.md](marketing/testimonials.md) |

---

## Current Status (2026-01-24)

### Build Status
- **All 23 tests passing**
- **Build succeeds**

### Completed Phases

| Phase | Version | Features | Commit |
|-------|---------|----------|--------|
| Phase 2 | v1.5 | 9 Power User features | `e1eeb60` |
| Phase 3 | v2.0 | 8 Pro features (security, sync, automation) | `00f805c`, `7b87296` |
| Phase 4 (partial) | - | macOS Widgets | `64e1cc6` |

### Phase 4 Progress

| Feature | Status |
|---------|--------|
| macOS Widgets | ✅ Complete |
| Shared Data Layer | Deferred (not needed for widgets) |
| iOS Companion App | Not started |
| iOS Widgets | Not started (requires iOS app) |

---

## Recent Session: macOS Widgets (Jan 24)

### Files Created
- `Widgets/SaneClipWidgets.swift` - Widget bundle entry point
- `Widgets/RecentClipsWidget.swift` - Recent clips widget (Small, Medium)
- `Widgets/PinnedClipsWidget.swift` - Pinned clips widget (Small, Medium)
- `Widgets/Info.plist` - Widget extension Info.plist
- `Widgets/SaneClipWidgets.entitlements` - Release entitlements (App Group)
- `Widgets/SaneClipWidgetsDebug.entitlements` - Debug entitlements (no App Group)
- `Core/Models/WidgetClipboardItem.swift` - Shared widget data model

### Files Modified
- `Core/ClipboardManager.swift` - Added updateWidgetData() method
- `SaneClip/SaneClip.entitlements` - Added App Group
- `project.yml` - Added SaneClipWidgets target
- `README.md` - Added Widgets section

### Key Implementation Details

**App Group:** `group.com.saneclip.app`
- Required for sharing data between main app and widget
- Only in Release entitlements (Debug builds without App Group work fine)

**Widget Data Flow:**
1. ClipboardManager.saveHistory() calls updateWidgetData()
2. updateWidgetData() writes WidgetDataContainer to App Group container
3. WidgetKit.reloadAllTimelines() triggers widget refresh
4. Widget providers read from shared container

**Debug vs Release:**
- Debug: No App Group (builds without provisioning profile)
- Release: Full App Group (requires provisioning profile with capability)

---

## Portal Setup Required

### CloudKit (Phase 3)
- Container: `iCloud.com.saneclip.app`
- Must be created in Apple Developer portal before Release builds

### App Group (Phase 4 Widgets)
- Group: `group.com.saneclip.app`
- Must be registered in Apple Developer portal for Release builds

---

## Quick Commands

```bash
# Build & Test (after XcodeBuildMCP defaults set)
build_macos
test_macos

# Regenerate project after new files
xcodegen generate
```

## Bundle IDs

| Target | Debug | Release |
|--------|-------|---------|
| SaneClip | `com.saneclip.dev` | `com.saneclip.app` |
| SaneClipWidgets | `com.saneclip.dev.widgets` | `com.saneclip.app.widgets` |
