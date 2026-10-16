# OpenDisplay Architecture & Bundle Map

This document serves as the canonical navigation and architectural bundle index for LLM agents and human contributors. It provides an explicit lookup matrix of subsystems, file responsibilities, dependencies, and communication patterns.

---

## 1. High-Level Bundle Hierarchy

```
OpenDisplay/
├── Package.swift                                      # SPM Manifest (Swift 5.9, macOS 12.0+, ARM64 only)
├── Sources/OpenDisplayCore/                           # Core Library Module
│   ├── Constants/                                     # Typed opcodes, magic numbers & layout scales
│   │   ├── ColorConstants.swift                       # Color spaces, pixel format identifiers
│   │   ├── DDCConstants.swift                         # VCP opcodes (0x10, 0x62, 0x8D), I2C addrs & packets
│   │   └── DisplayConstants.swift                     # Aspect ratios, limits, media keys, angles
│   ├── DynamicBridge/                                 # dlopen/dlsym & NSClassFromString runtime decoders
│   │   ├── DynamicLibrary.swift                       # Dynamic private framework loader (CoreDisplay, SkyLight)
│   │   └── DynamicObjCClass.swift                     # Objective-C runtime class allocator
│   ├── Hardware/                                      # Low-level IOKit, AVService, DDC/CI & inventory
│   │   ├── AppleDisplayServicesBridge.swift           # Native Apple display brightness wrapper
│   │   ├── DisplayInventory.swift                     # Live NSScreen + CGDirectDisplayID enumeration & UUIDs
│   │   ├── IOAVServiceDDC.swift                       # Apple Silicon IOAVService I2C packet dispatch
│   │   └── IOAVServiceMatcher.swift                   # 8-level IORegistry hierarchy search for EDID
│   ├── Color/                                         # ColorSync, EDID manipulation & HDR/10-bit modes
│   │   ├── ColorDepthController.swift                 # SkyLight 10-bit (ARGB2101010) & HDR mode toggles
│   │   ├── ColorProfileController.swift               # ColorSync ICC profile search, header validation & assignment
│   │   ├── EDIDParser.swift                           # Pure 128-byte EDID block decoder & checksum validator
│   │   └── RGBForcingEngine.swift                     # Hardware CADisplay connection mode switcher & IOMobileFramebuffer remap
│   ├── Luminance/                                     # Brightness curves, gamma LUT & Night Shift
│   │   ├── AmbientBrightnessSyncEngine.swift          # CoreDisplay auto-brightness polling & scaling
│   │   ├── GammaDimmingEngine.swift                   # Software Gamma LUT fallbacks for non-DDC panels
│   │   ├── LuminanceError.swift                       # Typed domain errors
│   │   ├── NightShiftTrueToneBridge.swift             # CoreBrightness CBBlueLightClient / CBTrueToneClient
│   │   └── XDROverdriveEngine.swift                   # EDR/XDR 1600 nits headroom calculator
│   ├── VirtualDisplay/                                # Software dummy screens & multi-display logic
│   │   ├── DisplayArrangementController.swift         # Display coordinates (origin X/Y) & main display swap
│   │   ├── DisplayGroupManager.swift                  # Multi-monitor Master-Slave linking & sync
│   │   ├── DisplayMirrorController.swift              # Hardware/software mirror pairing
│   │   ├── DisplayPowerStateController.swift          # Display blanking, sleep & orientation (0/90/180/270)
│   │   ├── DisplayPresetManager.swift                 # JSON snapshot serializer & preset bank
│   │   ├── ResolutionClassifier.swift                 # HiDPI vs Native vs Standard mode classification
│   │   ├── SkyLightModeEngine.swift                   # Display modes, refresh rates, VRR, ProMotion 120Hz detection
│   │   ├── VirtualDisplayController.swift             # CoreDisplay CGVirtualDisplay driver
│   │   └── VirtualDisplayManager.swift                # Thread-safe lifecycle registry of live virtual screens
│   ├── Streaming/                                     # Picture-in-Picture display projection
│   │   ├── PipCaptureEngine.swift                     # ScreenCaptureKit stream session
│   │   ├── PipStreamManager.swift                     # Floating window & CIImage render coordinator
│   │   └── PipWindowPanel.swift                       # Borderless, floating NSPanel (.floating level)
│   ├── Automation/                                    # CLI parser & Centralized Dispatcher
│   │   ├── AutomationConstants.swift                  # CLI flag prefixes and defaults
│   │   ├── DisplayCommandDispatcher.swift             # SINGLE SOURCE OF TRUTH for executing actions
│   │   ├── LaunchAtLoginController.swift              # macOS 13+ SMAppService login item manager
│   │   └── OpenDisplayCLI.swift                       # Pure argument parser (get, set, rotate, etc.)
│   ├── UI/                                            # Native macOS Translucent Glassmorphism Interface
│   │   ├── AppMenuView.swift                          # Root Popover View (Header, ScrollView, Footer)
│   │   ├── AtlasComponents.swift                      # Reusable UI primitives (Eyebrow, Badge, Divider, Toggles)
│   │   ├── AtlasTheme.swift                           # Adaptive Design Tokens (Dynamic NSColor, Material Glass)
│   │   ├── DisplayCardView.swift                      # Per-display interactive card coordinator
│   │   ├── DisplayCardHeaderView.swift                # Icon, name, active badges, soft disconnect toggle
│   │   ├── DisplayCardStatusBadgeRow.swift            # Protocol capability pills (DDC, 10-Bit, Retina)
│   │   ├── DisplayLuminanceControlView.swift          # Brightness slider, steppers, direct % input, XDR
│   │   ├── DisplayAudioControlView.swift              # DDC volume slider, mute toggle
│   │   ├── DisplayResolutionModePickerView.swift      # Separate Resolution and Refresh Rate dropdown selectors
│   │   ├── DisplayAdvancedControlsDrawerView.swift    # Flat progressive disclosure settings drawer
│   │   ├── DisplayColorModeSectionView.swift          # Hardware RGB Full / YCbCr Limited and appearance presets
│   │   ├── DisplayItemModel.swift                     # Observable reactive model of a single display
│   │   ├── MediaKeysListener.swift                    # NX_SYSDEFINED & CGEvent media key hook
│   │   ├── MenuBarController.swift                    # NSStatusItem & NSPopover lifecycle host
│   │   ├── NativeOSDController.swift                  # Chiclet HUD overlay via com.apple.OSDUIHelper
│   │   ├── NotchOverlayManager.swift                  # Blackout overlay panel for MacBook notches
│   │   ├── PopoverSections.swift                      # Presets, Virtual Display Generator & System toggles
│   │   ├── WorkspaceStore.swift                       # Central @MainActor state store with DDC throttling
│   │   ├── WorkspaceStore+Presets.swift               # Preset snapshots and import/export extensions
│   │   └── WorkspaceStore+Features.swift              # Virtual displays and system feature triggers
│   └── AppFeatureManager.swift                        # Permanent free-feature state engine (100% unlocked)
└── Tests/OpenDisplayTests/                            # Complete Offline & Logic Unit Test Suites (Phases 1-21)
    ├── Phase1Tests.swift ... Phase13Tests.swift       # Protocols, math, EDID, CLI, DDC, presets
    ├── Phase14Tests.swift ... Phase18Tests.swift      # UI tokens, input sources, resolution classifier
    └── Phase19Tests.swift ... Phase21Tests.swift      # Display groups, AppLogger, PiP and Notch overlays
```

---

## 2. Component Dependency Graph

```
[ AppMenuView ] ────> [ WorkspaceStore ] ────> [ DisplayCommandDispatcher ]
       │                      │                               │
       ├─ DisplayCardView     ├─ DisplayInventory             ├─ IOAVServiceDDC (I2C)
       ├─ PopoverSections     ├─ VirtualDisplayManager        ├─ AppleDisplayServicesBridge
       └─ AtlasComponents     ├─ DisplayPresetManager         ├─ GammaDimmingEngine
                              └─ AmbientBrightnessSyncEngine  ├─ ColorDepthController
                                                              ├─ PipStreamManager
                                                              └─ NightShiftTrueToneBridge
```

---

## 3. Communication Rules for LLMs

1. **Always Route via `DisplayCommandDispatcher`:**
   UI views (`DisplayCardView`, `PopoverSections`) must **never** call hardware controllers directly. They must mutate through `WorkspaceStore.shared`, which calls `DisplayCommandDispatcher.shared`.

2. **DDC I2C Throttling Rule:**
   Any slider or rapid-fire event modifying brightness or volume must use debounced dispatching to avoid freezing monitor microcontrollers.

3. **Swiss Neo-Brutalism Design Guardrails (Atlas/TypeUI):**
   - Radius: strictly `0px` (`AtlasTheme.zeroRadius`), except for pill badges (`Capsule()`).
   - Borders: crisp `1px` structural borders (`AtlasTheme.borderDefault`).
   - Theme: adaptive **Blueprint Light** (`#fbfbfe` + `#1313ba`) / **Blueprint Dark Terminal** (`#0a0a1a` + `#3b82f6` / `#edff45`).
   - Headlines: Cobalt blue in light mode, electric blue in dark mode.
   - Status indicators: Electric lime `#edff45`, Success green `#15a34a`, Warning orange `#f97316`.

4. **Zero Magic Numbers:**
   Never hardcode dimensions, timeouts, opcodes, or colors inline. Add or reuse tokens in `AtlasTheme` or `Constants/`.
