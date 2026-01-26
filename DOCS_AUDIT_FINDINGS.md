# SaneClip Documentation Audit Findings
**Generated:** 2026-01-25 7:08 PM EST
**Status:** ✅ COMPLETE
**Overall Score:** 7.5/10 (Good with critical gaps)
**Next Audit:** After v1.2 ships

---

## Phase 1: Feature Inventory

### Entry Points
| Entry Point | Location | Description |
|-------------|----------|-------------|
| Main App | SaneClipApp.swift:78-161 | Menu bar app with Sparkle updater, keyboard shortcuts, onboarding |
| URL Scheme | URLSchemeHandler.swift | `saneclip://` protocol with 8 commands |
| iOS App | SaneClipIOSApp.swift:4-38 | TabView with History, Pinned, Settings |
| Siri Intents | SaneClipIntents.swift | GetClipboardHistory, PasteItem, Search |

### URL Scheme Commands
- `saneclip://paste?index=N` - Paste item at index
- `saneclip://search?q=QUERY` - Open search with query
- `saneclip://export` - Trigger history export
- `saneclip://history` - Show history window
- `saneclip://clear` - Clear history (with confirmation)
- `saneclip://snippet?name=NAME` - Paste snippet with placeholders
- `saneclip://copy?text=TEXT` - Copy text to clipboard

### Public Features
| Feature | Location | Description |
|---------|----------|-------------|
| Menu Bar | SaneClipApp.swift | Left-click: history popover, Right-click: context menu |
| Touch ID | SaneClipApp.swift:288-304 | Optional biometric auth with 30s grace period |
| History Panel | ClipboardHistoryView.swift | 320×500px popover with search, filters, tabs |
| Text Transforms | TextTransformService.swift | 8 transforms: uppercase, lowercase, titleCase, trim, etc. |
| Snippets | SnippetManager.swift | Templates with {{date}}, {{time}}, {{clipboard}} placeholders |
| Paste Stack | ClipboardManager.swift | FIFO queue for Cmd+Ctrl+V |

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| Cmd+Shift+V | Show clipboard history |
| Cmd+Shift+Option+V | Paste as plain text |
| Cmd+Ctrl+V | Paste from stack (FIFO) |
| Cmd+Ctrl+1-9 | Quick paste items 1-9 |

### Configuration Options (SettingsModel.swift)
- `maxHistorySize` - Max items (default: 50)
- `showInDock` - Dock visibility (default: true)
- `protectPasswords` - Exclude password managers (default: true)
- `requireTouchID` - Require biometric auth (default: false)
- `excludedApps` - Bundle IDs to skip
- `playSounds` - Pop sound on paste (default: false)
- `menuBarIcon` - Icon selection (default: "list.clipboard.fill")
- `autoExpireHours` - Auto-remove hours (0=never)

### Clipboard Rules (ClipboardRulesManager.swift)
- `stripTrackingParams` - Remove utm_*, fbclid, gclid (default: true)
- `autoTrimWhitespace` - Trim whitespace (default: off)
- `lowercaseURLs` - Lowercase URL hosts (default: off)
- `normalizeLineEndings` - Unix LF (default: off)
- `removeDuplicateSpaces` - Collapse spaces (default: off)

### Security Features
| Feature | Description |
|---------|-------------|
| Sensitive Data Detector | Detects: credit cards, SSNs, API keys, passwords, private keys, emails |
| Auto-Purge | Configurable delays per data type (1-15 min) |
| Password Manager Protection | Auto-skip 1Password, Dashlane, LastPass |
| Data Encryption | `.completeFileProtection` on saved files |

### Integrations
| Integration | Description |
|-------------|-------------|
| Sparkle | Auto-updates via Cloudflare R2 |
| Webhooks | WebhookService.swift - onCopy/onPaste/onDelete/onClear events |
| Widgets | macOS + iOS widgets for pinned/recent clips |
| App Groups | Share data with widgets |

### Codebase Stats
- **41 Swift files**
- **8,153 lines of code**
- **40+ user-facing features**

---

## Current Documentation State

### README.md (338 lines)
**Status:** ⚠️ OUTDATED
- Good structure and feature organization
- **CRITICAL:** Still mentions iCloud sync, E2E encryption (REMOVED in v1.2)
- **CRITICAL:** Webhooks marked "coming soon" - unclear status
- Version numbers may be stale

### DEVELOPMENT.md (441 lines)
**Status:** ✅ EXCELLENT
- Version 1.1 (Jan 24, 2026)
- 12 numbered rules with clear prescriptions
- "THIS HAS BURNED YOU" failure table
- Bundle ID reference (critical: .dev vs .app)
- XcodeBuildMCP setup instructions

### CONTRIBUTING.md (168 lines)
**Status:** ⚠️ INCOMPLETE
- Missing xcodegen reference (critical for project)
- Testing section incomplete
- No link to bug tracking

### SESSION_HANDOFF.md (88 lines)
**Status:** ✅ CURRENT
- v1.2 CloudKit removal documented
- Files deleted listed
- Build status PASSING
- Ready for notarization

### CHANGELOG.md (77 lines)
**Status:** ⚠️ MISSING v1.2
- v1.1, v1.0.1, v1.0.0 documented
- **CRITICAL:** v1.2 changes NOT documented

### ROADMAP.md (134 lines)
**Status:** ⚠️ INCONSISTENT
- Phase 3 mentions "Secure clipboard mode" but sync infrastructure removed
- iOS app timeline unclear

### SECURITY.md (83 lines)
**Status:** ⚠️ OUTDATED
- Still references E2E encryption (removed)
- Local-only claim needs v1.2 clarification

### PRIVACY.md (114 lines)
**Status:** ⚠️ OUTDATED
- References E2E encryption and iCloud sync (removed)
- "Local-Only Storage" description incorrect for v1.2

### docs/ Folder (Website)
**Status:** ✅ EXISTS
- appcast.xml, index.html, sitemap.xml, robots.txt
- SANEAPPS_DESIGN_LANGUAGE.md
- releases/ and images/ folders
- No comprehensive docs site with guides

---

## Phase 2: Perspective Audits

### 1. Engineer Audit
**Status:** ✅ GOOD | **Score:** 8/10
- Code quality solid with minimal force unwraps
- Proper actor isolation with @MainActor
- Sparkle, KeyboardShortcuts well-integrated
- 0 TODO/FIXME comments (clean)

### 2. Designer Audit
**Status:** ⚠️ NOT FULLY ASSESSED
- Requires visual review of running app
- Brand colors defined but inconsistently applied
- See Brand Compliance Audit for color violations

### 3. Marketer Audit
**Status:** ⚠️ GAPS IN STORY
- See Marketing Framework Audit
- Website missing threat/barrier narrative
- Value proposition clear but not compelling

### 4. User Advocate Audit
**Status:** ⚠️ NOT FULLY ASSESSED
- Requires hands-on first-launch testing
- Onboarding exists (3-page wizard)
- Keyboard shortcuts documented

### 5. QA Audit
**Status:** ⚠️ NOT FULLY ASSESSED
- Requires manual testing
- No automated test suite found
- Edge cases not documented

### 6. Hygiene Audit
**Status:** ⚠️ SOME SPRAWL

#### Document Overlap
| Purpose | Files | Recommendation |
|---------|-------|----------------|
| Session context | SESSION_HANDOFF.md | ✅ Single source |
| Next tasks | ROADMAP.md, SESSION_HANDOFF.md | ⚠️ ROADMAP for long-term, HANDOFF for session |
| Bug tracking | None in files | ✅ Using memory MCP |
| Dev setup | DEVELOPMENT.md, CONTRIBUTING.md | ⚠️ Slight overlap |

#### Multiple CLAUDE.md Files
| Location | Purpose |
|----------|---------|
| CLAUDE.md (root) | Project instructions |
| .claude/CLAUDE.md | Claude-mem context |
| Core/CLAUDE.md | Directory-specific |
| UI/*/CLAUDE.md | UI-specific notes |

**Note:** Multiple CLAUDE.md is acceptable pattern for directory-specific context.

#### Terminology Consistency
| Term | Variations | Standardize To |
|------|------------|----------------|
| Next steps | "roadmap", "todos", "pending" | "Next Steps" in HANDOFF |
| Handoff | Used consistently | ✅ |

#### Action Items
1. [ ] Review DEVELOPMENT.md vs CONTRIBUTING.md overlap
2. [ ] Ensure ROADMAP.md is long-term only (not session tasks)

### 7. Security Audit
**Status:** ✅ COMPLETED | **Score:** 8.5/10

#### Strengths
| Category | Score | Notes |
|----------|-------|-------|
| Input Validation | 9/10 | URL scheme validates all inputs, bounds checking |
| Authentication | 9/10 | Biometric + device password fallback, 30s grace |
| Code Injection Protection | 10/10 | No NSTask, no shell execution, no AppleScript eval |
| Minimal Permissions | 10/10 | Only Apple Events entitlement needed |
| Sensitive Data Detection | 10/10 | 10+ patterns: credit cards, API keys, SSNs, etc. |

#### Medium Priority Issues
| Issue | Severity | Location | Recommendation |
|-------|----------|----------|----------------|
| Unencrypted history at rest | MEDIUM | ~/Library/Application Support/SaneClip/ | Implement CryptoKit encryption |
| print() instead of os.log | MEDIUM | URLSchemeHandler.swift (8 instances) | Replace with Logger framework |
| Fixed 30s grace period | LOW-MEDIUM | SaneClipApp.swift | Add settings toggle |

#### Verified Safe
- [x] No hardcoded credentials
- [x] Input validation present
- [x] No sensitive logging
- [x] Hardened runtime enabled
- [x] File protection enabled (.completeFileProtection)

### 8. Freshness Audit
**Status:** 🔴 STALE CONTENT DETECTED

#### Version Numbers
| Location | Shows | Actual | Status |
|----------|-------|--------|--------|
| project.yml | 1.2 | 1.2 | ✅ |
| CHANGELOG.md | 1.1 | 1.2 | ❌ STALE |
| README.md | - | 1.2 | No badge |

#### Stale Documentation
| File | Issue | Current Reality |
|------|-------|-----------------|
| README.md | iCloud sync section | **REMOVED in v1.2** |
| README.md | E2E encryption | **REMOVED in v1.2** |
| README.md | Webhooks "coming soon" | WebhookService.swift exists |
| SECURITY.md | E2E encryption reference | Removed |
| PRIVACY.md | iCloud sync reference | Removed |
| ROADMAP.md | Phase 3 sync features | Infrastructure removed |

#### Action Items
1. [ ] **CRITICAL:** Remove iCloud/E2E sections from README.md
2. [ ] **CRITICAL:** Update PRIVACY.md to remove sync references
3. [ ] **CRITICAL:** Update SECURITY.md local-only claims
4. [ ] Add v1.2 to CHANGELOG.md
5. [ ] Clarify Webhooks status (shipped vs coming)

### 9. Completeness Audit
**Status:** ⚠️ INCOMPLETE ITEMS

#### Unchecked Items in Docs
| File | Unchecked | Notes |
|------|-----------|-------|
| APP_STORE_CHECKLIST.md | Many | Pre-submission checklist |
| CONTRIBUTING.md | Some | Testing section incomplete |

#### Placeholder Text Found
| Location | Issue |
|----------|-------|
| ROADMAP.md | Phase 3/4 timelines vague |
| README.md | Webhooks "coming soon" but shipped |

#### Stale Promises
| Promise | Where | Status |
|---------|-------|--------|
| "Coming soon" Webhooks | README.md | Actually shipped |
| Phase 3 sync features | ROADMAP.md | Infrastructure removed |

#### Action Items
1. [ ] Update Webhooks from "coming soon" to documented
2. [ ] Remove or update Phase 3 sync features in ROADMAP.md
3. [ ] Complete APP_STORE_CHECKLIST.md if preparing for store

### 10. Ops Audit
**Status:** ✅ COMPLETED | **Score:** 9/10

#### Git Hygiene
| Check | Status | Notes |
|-------|--------|-------|
| Stale branches | ✅ Clean | No unmerged branches |
| Uncommitted changes | ⚠️ 64 files | Major release staged (CloudKit removal) |
| Recent activity | ✅ Active | 23 commits in last 7 days |

#### Dependencies
| Dependency | Version | Status |
|------------|---------|--------|
| KeyboardShortcuts | 2.0.0+ | ✅ Current |
| Sparkle | 2.6.0+ | ✅ Current |

#### Code Hygiene
| Metric | Count | Status |
|--------|-------|--------|
| TODO/FIXME comments | 0 | ✅ Clean |
| print() statements | ~10 | ⚠️ Should use Logger |

#### Version Consistency
| Location | Version | Build | Notes |
|----------|---------|-------|-------|
| project.yml (macOS) | 1.2 | 4 | Source of truth |
| project.yml (iOS) | 1.0 | 1 | Separate versioning |
| CHANGELOG.md | 1.1 | - | **MISSING v1.2 entry** |

#### Legal
| Item | Status |
|------|--------|
| LICENSE | ✅ MIT, Copyright 2025 |
| Copyright year | ✅ Current |

#### Action Items
1. [ ] Commit 64 pending files before release
2. [ ] Add v1.2 release notes to CHANGELOG.md
3. [ ] Replace print() with Logger framework

### 11. Brand Compliance Audit
**Status:** ⚠️ VIOLATIONS DETECTED | **Score:** 68/100

#### Color System
- ✅ BrandColors.swift properly defines palette
- ✅ SaneClip accent (#4f8ffa - Clip Blue) implemented
- ⚠️ 18 instances of system colors violating brand

#### Violations Found
| Type | Count | Files | Severity |
|------|-------|-------|----------|
| System colors (.blue, .green, etc.) | 18 | 7 files | MEDIUM |
| Hardcoded RGB gradients | 6 | 2 files | LOW |
| System semantic colors | 3 | 3 files | LOW |

#### Files Requiring Updates
| File | Issues | Lines |
|------|--------|-------|
| UI/Settings/SettingsView.swift | System colors, RGB gradients | 84, 702, 891, 897, 933 |
| UI/Onboarding/OnboardingView.swift | .green, .purple | 88, 147, 163, 165 |
| UI/History/ClipboardItemRow.swift | .orange, .green | 98, 151 |
| UI/Settings/SnippetsSettingsView.swift | .blue, .orange | 136, 258, 321 |
| Widgets/RecentClipsWidget.swift | System colors | 160-162 |
| Widgets/PinnedClipsWidget.swift | .orange | 89, 132 |

#### Recommendations
1. [ ] Replace system colors with brand palette equivalents
2. [ ] Extract hardcoded gradients to Color extensions
3. [ ] Update widgets to use brand colors
4. [ ] Add linter rule to catch system color usage

### 12. Consistency Audit
**Status:** ✅ MOSTLY CONSISTENT

#### File Path References
| Reference | Exists | Notes |
|-----------|--------|-------|
| Core/ClipboardManager.swift | ✅ | |
| Core/SettingsModel.swift | ✅ | |
| ~/SaneApps/apps/SaneClip/ | ✅ | |

#### Deleted Files Still Referenced
| File | Referenced In | Status |
|------|---------------|--------|
| Core/Encryption/EncryptionService.swift | README.md (E2E section) | ❌ DELETED |
| Core/Sync/CloudKitSyncService.swift | README.md (iCloud section) | ❌ DELETED |
| UI/Settings/SyncSettingsView.swift | - | ❌ DELETED |

#### MCP Tools
| Tool | Status |
|------|--------|
| mcp__plugin_claude-mem_mcp-search__search | ✅ Configured |
| XcodeBuildMCP | ✅ Configured |

#### Action Items
1. [ ] Remove references to deleted files in README.md

### 13. Website Standards Audit
**Status:** ⚠️ MOSTLY COMPLIANT | **Score:** 85/100

#### Standards Checklist
| Standard | Status | Notes |
|----------|--------|-------|
| Sane Apps family link (header) | ✅ | "Part of the SaneApps family" with link |
| Sane Apps family link (footer) | ✅ | Present |
| Trust badges | ⚠️ PARTIAL | Privacy messaging in copy, not distinct badges |
| $5 download button | ✅ | Lemon Squeezy integration |
| GitHub source link | ✅ | Header + footer |
| GitHub Sponsors | ✅ | "Sponsor on GitHub" button |
| Crypto addresses | ✅ | BTC, SOL, ZEC with copy functionality |
| No Homebrew | ✅ | None mentioned |
| Brand colors | ✅ | Neon blue accent, dark theme |
| Privacy policy link | ❌ MISSING | Critical for privacy-focused app |

#### Action Items
1. [ ] **CRITICAL:** Add privacy policy link to footer
2. [ ] Add formatted trust badges: 🔒 No spying · 💵 No subscription · 🛠️ Actively maintained

### 14. Marketing Framework Audit
**Status:** ⚠️ INCOMPLETE | **Score:** 2.5/5

#### Framework Elements (Website)
| Element | Present | Quality | Location |
|---------|---------|---------|----------|
| Threat | ⚠️ WEAK | Generic "privacy-first" not specific threat | Hero |
| Barrier A (DIY painful) | ❌ MISSING | No explanation of why users can't do this themselves | - |
| Barrier B (Others betray) | ⚠️ WEAK | "No cloud sync, no analytics" but no competitor comparison | Features |
| Solution (solves both) | ⚠️ PARTIAL | Shows simplicity, ethics less explicit | Features |
| Promise (3 pillars) | ✅ | 2 Timothy 1:7 quote in footer | Footer |

#### What's Missing
1. **Specific Threat Statement:** Need "Every clipboard manager tracks what you copy" or similar
2. **Barrier A:** "Building your own means managing files, writing scripts..."
3. **Barrier B:** "Other clipboard managers sync to the cloud, require subscriptions..."
4. **Solution Framing:** "SaneClip is 100% local AND one-time purchase"

#### In-App Onboarding (OnboardingView.swift)
| Element | Present | Screen |
|---------|---------|--------|
| Threat | ❌ | Not in onboarding |
| Barrier A/B | ❌ | Not in onboarding |
| Solution | ⚠️ | Feature list only |
| Promise | ❌ | Not in onboarding |

#### Action Items
1. [ ] Rewrite website hero with specific threat statement
2. [ ] Add "Why SaneClip?" section with Barrier A + B
3. [ ] Update onboarding to include Promise screen
4. [ ] Add comparison table showing what others do wrong

---

## Phase 3: Gap Report

### Executive Summary
- **Features in code:** 40+
- **Features documented:** ~35 (87.5% coverage)
- **Critical gaps:** 5 (documentation correctness)
- **Estimated effort:** Medium (2-4 hours to fix critical items)

---

### 🔴 CRITICAL GAPS (Fix Before Ship)

| # | Gap | Why It Matters | File | Status |
|---|-----|----------------|------|--------|
| 1 | README.md mentions iCloud sync | **Feature removed in v1.2** | README.md | ✅ [RESOLVED 2026-01-25] |
| 2 | README.md mentions E2E encryption | **Feature removed in v1.2** | README.md | ✅ [RESOLVED 2026-01-25] |
| 3 | CHANGELOG.md missing v1.2 | Users can't see what changed | CHANGELOG.md | ✅ [RESOLVED 2026-01-25] |
| 4 | PRIVACY.md references sync | Incorrect privacy claims | PRIVACY.md | ✅ [RESOLVED 2026-01-25] |
| 5 | Website missing privacy policy link | Critical for privacy-focused app | docs/index.html | ✅ [RESOLVED 2026-01-25] |

---

### 🟡 HIGH PRIORITY (Fix This Week)

| Gap | Why It Matters | Recommendation | Effort |
|-----|----------------|----------------|--------|
| Webhooks "coming soon" | Feature shipped, docs say coming | Update README.md | 10 min |
| SECURITY.md E2E reference | Incorrect security claims | Update to "local-only" | 10 min |
| ROADMAP.md Phase 3 sync | Plans for removed features | Update or remove | 15 min |
| CONTRIBUTING.md xcodegen | Developers can't regenerate project | Add xcodegen section | 20 min |
| Brand color violations (18) | Inconsistent UI, brand dilution | Replace system colors | 2 hr |

---

### 🟢 MEDIUM PRIORITY (Fix This Month)

| Gap | Why It Matters | Recommendation | Effort |
|-----|----------------|----------------|--------|
| Trust badges on website | Brand consistency | Add formatted badges | 30 min |
| Marketing framework weak | Conversion optimization | Rewrite hero section | 1 hr |
| print() logging | Should use os.log | Replace with Logger | 30 min |
| Unencrypted history at rest | Security enhancement | Add CryptoKit | 4 hr |
| Widget brand colors | UI consistency | Update 4 files | 1 hr |

---

### Website Status
- [x] Exists at saneclip.com
- [x] Sane Apps family link present
- [x] $5 download button (Lemon Squeezy)
- [x] GitHub + Sponsors links
- [x] Crypto addresses
- [x] No Homebrew mentions
- [x] Brand colors (not grey-on-grey)
- [ ] **Privacy policy link MISSING**
- [ ] Trust badges not formatted
- [ ] Marketing framework incomplete

---

### Documentation Health Summary

| Document | Status | Action |
|----------|--------|--------|
| README.md | ⚠️ STALE | Remove iCloud/E2E sections |
| DEVELOPMENT.md | ✅ CURRENT | None |
| CONTRIBUTING.md | ⚠️ INCOMPLETE | Add xcodegen |
| SESSION_HANDOFF.md | ✅ CURRENT | None |
| CHANGELOG.md | ❌ MISSING v1.2 | Add release notes |
| ROADMAP.md | ⚠️ INCONSISTENT | Update Phase 3 |
| SECURITY.md | ⚠️ OUTDATED | Update claims |
| PRIVACY.md | ⚠️ OUTDATED | Remove sync refs |

---

### Recommended Actions (Priority Order)

#### Immediate (Before v1.2 Ship) — ✅ ALL RESOLVED
1. [x] Remove iCloud sync section from README.md — [RESOLVED 2026-01-25]
2. [x] Remove E2E encryption references from README.md — [RESOLVED 2026-01-25]
3. [x] Add v1.2 release notes to CHANGELOG.md — [RESOLVED 2026-01-25]
4. [x] Update PRIVACY.md to remove sync references — [RESOLVED 2026-01-25]
5. [x] Add privacy policy link to website footer — [RESOLVED 2026-01-25]
6. [x] Update website version to 1.2 — [RESOLVED 2026-01-25]
7. [x] Update iOS companion section (now "Coming Soon") — [RESOLVED 2026-01-25]
8. [x] Clarify Webhooks status (API available, UI coming) — [RESOLVED 2026-01-25]

#### This Week
6. [ ] Update SECURITY.md local-only claims
7. [ ] Update Webhooks from "coming soon" to documented
8. [ ] Update ROADMAP.md Phase 3
9. [ ] Add xcodegen to CONTRIBUTING.md
10. [ ] Commit 64 pending git changes

#### This Month
11. [ ] Add trust badges to website
12. [ ] Improve marketing framework on website
13. [ ] Replace system colors with brand palette (18 violations)
14. [ ] Replace print() with Logger framework
15. [ ] Consider CryptoKit encryption for history

---

### Audit Trail
- **First audit:** 2026-01-25 7:08 PM EST
- **Auditor:** Claude (docs-audit skill)
- **Next audit:** After v1.2 ships

*Mark items as `[RESOLVED YYYY-MM-DD]` when fixed.*
