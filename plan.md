# OpenDisplay Engineering Roadmap: Detailed Color Mode Architecture

> **Context:** Reverse-engineered from BetterDisplay v5.1.1 (`Color Mode` submenu analysis) and user testing on multi-display setups (HDMI 27E1Q external monitors + built-in Liquid Retina XDR).
> **Reference Artifacts:**
> - Interactive Anatomy: [`betterdisplay_structure/index.html`](betterdisplay_structure/index.html)
> - Technical Decompilation & Symbols Plan: [`betterdisplay_structure/plan.md`](betterdisplay_structure/plan.md)

---

## 1. Diagnostics & Immediate Bug Fixes (Hotfixes)

### 1.1 Resolution Selector Empty / No Feedback on Change
- **Root Cause:** When an external display connects via HDMI, `CGDisplayCopyAllDisplayModes` may return modes before SkyLight finishes handshake, or the mode matcher in `SkyLightModeEngine.setDisplayResolution` fails because point dimensions don't match exactly without scaling flags.
- **Fix:**
  1. Fallback mode resolution: if `modes` are empty, probe with `CGSGetCurrentDisplayMode` and populate with current native pixel dimensions.
  2. Implement direct mode switching via `SLSSetDisplayModeDescription` / `CGSConfigureDisplayMode(config, displayID, modeNumber)` using the explicit `mode.modeNumber`.
  3. **User Feedback:** Display transient HUD / status line message (`WorkspaceStore.shared.activeTooltipText = "Resolution switched to \(mode.userLabel)"` or error notification).

### 1.2 "Force RGB" Switch Does Not Work & Fails Silently
- **Root Cause:** `WorkspaceStore.toggleForceRGB` casts `io_service_t(item.id)` directly, which is an invalid IOKit service handle. Real handles must be resolved via `IOAVServiceMatcher.service(for: item.id)`.
- **Fix:**
  1. In `WorkspaceStore.toggleForceRGB`, resolve `IOAVServiceMatcher.service(for: item.id)`.
  2. Read current display EDID, patch CTA-861 flags using `RGBForcingEngine.patchEDIDForRGBOnly(edidBytes:)`, and apply live via `RGBForcingEngine.applyLiveVirtualEDID`.
  3. **User Feedback:** Immediate status line message: `"Forcing RGB 4:4:4... Screen may flash briefly"` + OSD indicator.

### 1.3 ColorSync Profile Switch Crash
- **Root Cause:** `ColorSyncDeviceSetCustomProfiles` crashes when invoked with unverified CoreGraphics Display UUIDs or when `kColorSyncDisplayDeviceClass` / `kColorSyncDeviceDefaultProfileID` are uninitialized or nil in the runtime bridge.
- **Fix:**
  1. Add safety guards in `ColorProfileController.setProfile`: verify UUID existence, catch exceptions, check file URL accessibility.
  2. Provide fallback to system default profile without crashing.
  3. **User Feedback:** Update status line to `"Color Profile applied: \(profile.name)"`.

---

## 2. Detailed "Color Mode" Submenu Specification (BetterDisplay Parity)

Based on the inspected BetterDisplay submenu, we implement a dedicated modular section in `DisplayAdvancedControlsDrawerView` / `DisplayCardView`:

### 2.1 Submenu Header: Color Mode
- Swatch/palette icon + `Color Mode` label + chevron expansion toggle.

### 2.2 Color Depth & Encoding Options (Selectable Options)
1. **Option 1: 8-bit (SDR, RGB, Full Range)**
   - Icon: Circular sun/brightness glyph.
   - Badges: `[SDR - Green]`, `[RGB - Green]`, `[Full Range - Green]`.
2. **Option 2: 8-bit (SDR, YCbCr 4:4:4, Limited Range)** (or active mode)
   - Badges: `[SDR - Green]`, `[YCbCr - Amber]`, `[4:4:4 - Green]`, `[Limited Range - Red]`.
3. **Option 3: 10-bit Deep Color (ARGB2101010)** (if hardware supports)
   - Badges: `[HDR/SDR]`, `[10-Bit]`, `[Full Range]`.
- **Informational Note:** Half-shield icon + `"Configuration Protection can make color mode changes persistent."`

### 2.3 HDR Settings Section
- Layered-squares icon + `Pro` badge + `Allow Forced HDR` switch (enabled for HDR monitors, disabled with explanation if monitor is SDR-only).

### 2.4 GPU Dithering Section
- Waveform/signal bars icon + `GPU Dithering` toggle switch.
- **Warning / Explanation Note:**
  - Triangle warning icon + `"Connection color depth (8-bit) is lower than the framebuffer depth (10-bit). The GPU may use temporal dithering to improve colors."`

### 2.5 Appearance & Color Filter Presets (System Colors)
- Quick one-click visual mode buttons:
  - 🔘 **Standard Appearance** (aperture icon).
  - 🌗 **Inverted Appearance** (contrasting aperture icon).
  - ⚪ **Grayscale Appearance** (empty circle icon).
  - ⚫ **Inverted Grayscale Appearance** (solid circle icon).

---

## 3. Implementation Steps & Verification Protocol

1. **Step 1: Fix Core Bugs (Crash & Silent Failures)**
   - Fix `ColorProfileController` crash with safe unwraps & exception handling.
   - Fix `toggleForceRGB` to resolve real `io_service_t` via `IOAVServiceMatcher`.
   - Fix `setResolution` with mode number fallbacks and instant user feedback.
2. **Step 2: Implement Color Mode & GPU Dithering UI Component**
   - Create `DisplayColorModeSectionView.swift` implementing the 5 sections above.
3. **Step 3: Verification & Review**
   - Run unit tests: `swift test` (Phases 1-21).
   - Run SwiftLint: `DYLD_FRAMEWORK_PATH=/Library/Developer/CommandLineTools/usr/lib swiftlint lint Sources Tests --config .swiftlint.yml`.
   - Perform independent architectural review via `opencode run -m zai-coding-plan/glm-5.3-flash`.
   - Commit cleanly to Git and push.
