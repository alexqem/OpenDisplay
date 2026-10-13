# OpenDisplay

> **100% Free & Open-Source Advanced Display Management Utility for Apple Silicon (macOS 12+)**

OpenDisplay provides complete, fine-grained control over external and built-in displays on Apple Silicon Macs (M1, M2, M3, M4). Engineered in pure Swift with zero telemetry, zero licensing checks, and zero third-party dependencies.

---

## Key Features

- **Hardware DDC/CI & Apple DisplayServices Control:**
  - Direct hardware brightness, contrast, volume, and input switching via Apple Silicon coprocessor (`IOAVService` / `DCPAVServiceProxy`).
  - Native Apple DisplayServices support for Studio Display, Pro Display XDR, and built-in panels.
  - MCCS 0xF3 capability string tokenizer and hardware verification.
- **Virtual Displays (Dummy Screens):**
  - Instant creation of headless virtual screens with custom aspect ratios (15 standard presets including 16:9, 16:10, 21:9, 32:9).
  - High-refresh rate modes (50Hz, 60Hz, 75Hz, 120Hz) and native 2x HiDPI scaling via private `CoreDisplay` / `CGVirtualDisplay` APIs.
- **Luminance, Gamma Dimming & XDR Overdrive:**
  - Sub-zero software dimming down to true pitch black via custom CoreGraphics gamma transfer tables (LUT).
  - Liquid Retina XDR / EDR Headroom Overdrive (up to 1600 nits) utilizing Metal EDR layers.
  - Night Shift & True Tone controls via dynamic `CoreBrightness` bindings.
- **Ambient Brightness Synchronization:**
  - Real-time synchronization of external display brightness with the MacBook's ambient light sensor and built-in screen.
  - Anti-jitter filtering and adjustable sensitivity factor (0.5x–1.5x).
- **Color Calibration & Pixel Formats:**
  - Raw 128-byte EDID parsing with checksum validation.
  - Force RGB 4:4:4 output by stripping CTA-861 YCbCr capability flags.
  - 10-Bit Deep Color (`ARGB2101010`) inspection and HDR switching.
  - ICC ColorSync profile enumeration and per-display profile assignment.
- **Screen Mirroring & Canvas Arrangement:**
  - Hardware display mirroring and cloning via `CGConfigureDisplayMirrorOfDisplay`.
  - Display canvas coordinates arrangement and primary display switching (`origin: 0, 0`).
  - Software display disconnect/blanking and display rotation (0°, 90°, 180°, 270°).
- **Picture-in-Picture (PiP) Streaming:**
  - High-performance, low-latency display and window mirroring using `ScreenCaptureKit`.
  - Floating borderless PiP panel with adjustable opacity and always-on-top positioning.
- **Native macOS OSD HUD & System Media Keys:**
  - Native macOS brightness OSD indicator with chiclets via private `com.apple.OSDUIHelper` XPC.
  - System media key interception (`NX_SYSDEFINED` events) for external displays with fallback to F1/F2 keys.
  - MacBook camera notch blackout overlay bar.
- **Automation & CLI:**
  - Lightweight, fast CLI (`OpenDisplayCLI` + `DisplayCommandDispatcher`) for terminal scripting, Shortcuts, and automation without opening local network ports.
  - One-click configuration presets with JSON export/import and Launch-at-Login support (`SMAppService`).

---

## Architecture & Code Principles

1. **Target Platform:** Exclusively **Apple Silicon ARM64** (`#if os(macOS) && arch(arm64)`). No legacy Intel/x86 code or BIOS artifacts.
2. **KISS & DRY:** Separation of pure mathematical/protocol logic from hardware callers so every core algorithm is 100% testable offline.
3. **Zero Magic Numbers:** All VCP opcodes, I2C addresses, aspect multipliers, protocol limits, and timeouts reside in dedicated `Constants/` structs and enums.
4. **Dynamic Private API Binding:** Private macOS frameworks (`CoreDisplay`, `SkyLight`, `IOKit`, `DisplayServices`, `CoreBrightness`) are resolved at runtime via dynamic wrappers (`DynamicLibrary` and `DynamicObjCClass`) ensuring stability across macOS updates.
5. **Completely Free & Open Source:** Clean-room implementation, no tracking, no telemetry, no paid tiers, zero open ports.

---

## Project Structure

```
OpenDisplay/
├── Package.swift                  # Swift 5.9 SPM Manifest (.macOS(.v12))
├── Sources/OpenDisplayCore/       # Core Implementation
│   ├── Constants/                 # DDCConstants, DisplayConstants, ColorConstants
│   ├── DynamicBridge/             # DynamicLibrary (dlopen/dlsym), DynamicObjCClass
│   ├── Hardware/                  # IOAVServiceMatcher, IOAVServiceDDC, AppleDisplayServicesBridge
│   ├── Color/                     # EDIDParser, RGBForcingEngine, ColorDepthController, ColorProfileController
│   ├── VirtualDisplay/            # VirtualDisplayController, SkyLightModeEngine, DisplayMirrorController, DisplayPresetManager, DisplayPowerStateController
│   ├── Luminance/                 # GammaDimmingEngine, XDROverdriveEngine, NightShiftTrueToneBridge, AmbientBrightnessSyncEngine
│   ├── Streaming/                 # PipCaptureEngine (ScreenCaptureKit), PipWindowPanel (.floating)
│   ├── Automation/                # OpenDisplayCLI, DisplayCommandDispatcher, LaunchAtLoginController
│   ├── UI/                        # AppMenuView (SwiftUI), MenuBarController, MediaKeysListener, NativeOSDController, NotchOverlayManager
│   └── AppFeatureManager.swift    # Permanent Unrestricted Feature Engine
└── Tests/OpenDisplayTests/        # Complete Unit Test Suite (Phase1Tests ... Phase13Tests)
```

---

## Build & Test

### Prerequisites
- macOS 12.0 Monterey or higher
- Apple Silicon Mac (M1, M2, M3, M4)
- Xcode 14+ or Swift 5.9+ toolchain

### Building from Source

```bash
cd OpenDisplay

# Run complete test suite (Phases 1-13)
swift test

# Build debug binary
swift build

# Build release optimized binary
swift build -c release
```

---

## Automation & CLI Usage

OpenDisplay includes a built-in CLI interface for terminal scripting and macOS Shortcuts:

```bash
# Read display properties
opendisplay get -target=active -property=brightness

# Set brightness (0-100)
opendisplay set -target=active brightness=85

# Create a 4K 16:9 virtual display
opendisplay create-virtual -name="Studio Virtual" -aspect=16:9 -width=3840

# Configure display mirroring
opendisplay mirror -source=1 -target=2
opendisplay unmirror -target=2

# Rotate display orientation
opendisplay rotate -target=1 -degrees=90

# Software disconnect / reconnect screen
opendisplay disconnect -target=1
opendisplay reconnect -target=1

# Color Calibration & Pixel Formats
opendisplay force-rgb -target=2
opendisplay hdr -target=1 -state=enable
opendisplay color-profile -target=1 -profile="Display P3"
opendisplay profiles

# List display configuration presets
opendisplay presets
```

---

## License

MIT License. OpenDisplay is completely free and open-source software.
