# SaneClip App Store Submission Checklist

This checklist guides the creation of a dedicated **App Store Build** while preserving the existing Website/Direct version.

## Phase 1: Dual Distribution Setup (Project Config)
*Objective: Create a separate build mode that excludes non-App Store features.*

- [x] **Create App Store Configuration**
    - [x] In `project.yml` (or Xcode), duplicate the `Release` configuration and name it `Release-AppStore`.
    - [x] Add the Swift Compiler Flag `-D APP_STORE` to this new configuration.
- [x] **Configure Entitlements**
    - [x] Create a new entitlement file: `SaneClip/SaneClipAppStore.entitlements`.
    - [x] Add `com.apple.security.app-sandbox` (Boolean: YES).
    - [x] Keep `com.apple.security.automation.apple-events` (needed for CGEvent paste simulation).
    - [x] Point the `Release-AppStore` config to use this new entitlements file.

## Phase 2: Code Modifications
*Objective: Strip out prohibited features using the `#if !APP_STORE` flag.*

- [x] **Sparkle (Updates)**
    - [x] Wrap `import Sparkle` in `SaneClipApp.swift` with `#if !APP_STORE`.
    - [x] Wrap `UpdateService` class, initialization, and property with `#if !APP_STORE`.
    - [x] Wrap "Check for Updates" button and "Software Updates" section in SettingsView with `#if !APP_STORE`.
    - [x] Wrap `checkForUpdates()` function in AboutSettingsView with `#if !APP_STORE`.
    - [x] Wrap `autoCheckUpdates` state initialization and onAppear sync with `#if !APP_STORE`.
- [x] **Sparkle Framework & Info.plist Stripping**
    - [x] Post-build script strips `Sparkle.framework` from app bundle for Release-AppStore.
    - [x] Post-build script removes `SUFeedURL`, `SUPublicEDKey`, `SUEnableAutomaticChecks`, `SUEnableSystemProfiling` from built Info.plist.
- [x] **Lemon Squeezy (Licensing)**
    - [x] No Lemon Squeezy code exists in the codebase — nothing to wrap.
- [x] **Info.plist Cleanup**
    - [x] Sparkle keys are stripped from the built Info.plist by post-build script (source `info.properties` kept for Direct builds).

## Phase 3: Sandboxing & Permissions
*Objective: Ensure the app works inside the "Sandbox" container.*

- [x] **File Storage Verification**
    - [x] Verify `ClipboardManager.swift` uses `FileManager.default.urls(for: .applicationSupportDirectory, ...)` correctly.
    - [x] *Note:* In the sandbox, this path automatically resolves to `~/Library/Containers/com.saneclip.app/Data/Library/Application Support/`. No code change is usually needed, but you must verify data persists across launches.
- [x] **Accessibility Permissions (Critical)**
    - [x] Your paste simulation uses `CGEvent`, which requires "Accessibility" permission.
    - [x] Add a check at launch: `AXIsProcessTrusted()`. (Implemented in OnboardingView.swift)
    - [x] If `false`, show a tailored UI explaining why SaneClip needs Accessibility permissions to paste, with a button to open System Settings. (PermissionsPage in OnboardingView.swift)
- [x] **Privacy Manifest**
    - [x] Created `Resources/PrivacyInfo.xcprivacy` declaring `NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1`).
    - [x] No tracking, no collected data types declared.

## Phase 4: Assets & Metadata
*Objective: Prepare marketing materials for Apple.*

- [x] **Privacy Policy**
    - [x] Host the content of `PRIVACY.md` at a public URL (e.g., `https://saneclip.com/privacy`).
    - [x] Created `docs/privacy.html` for `saneclip.com/privacy`.
    - [x] Updated PRIVACY.md to clarify Sparkle is direct-download only; removed Lemon Squeezy section.
- [x] **Support URL**
    - [x] Created `docs/support.html` for `saneclip.com/support` (FAQ, contact email, system requirements).
- [x] **Screenshots**
    - [x] Capture screenshots at required resolutions (e.g., 1280x800 or 1440x900). (docs/images/ contains screenshots)
    - [ ] Re-take screenshots from App Store build (no "Check for Updates" button, no "Software Updates" section).
- [x] **App Icon**
    - [x] Verify `AppIcon.appiconset` contains a 1024x1024 version (512x512@2x present, which is sufficient).

## Phase 5: Submission
*Objective: Upload to App Store Connect.*

- [ ] **App Store Connect**
    - [ ] Create the App Record in App Store Connect.
    - [ ] Fill in Description, Keywords, URLs, and Pricing.
- [ ] **Archive & Upload**
    - [ ] Install "Mac App Distribution" and "Mac Installer Distribution" certificates.
    - [ ] Create provisioning profile for App Store distribution.
    - [ ] Run `xcodebuild archive -scheme SaneClip -configuration Release-AppStore`.
    - [ ] Validate the archive.
    - [ ] Upload to App Store Connect.
- [ ] **Sandbox Testing**
    - [ ] Test the archived App Store build in sandbox mode (clipboard access, paste simulation, data persistence).

---

## Status Summary

**Completed:** 27 items
**Remaining:** 5 items (screenshots from App Store build + Phase 5 submission)

*Last updated: 2026-01-27*
