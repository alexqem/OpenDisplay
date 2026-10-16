# OpenDisplay Product Strategy & Strategic Roadmap

> **Mission:** Deliver a 100% free, DRM-free, open-source Apple Silicon (M1-M4) display manager that exceeds BetterDisplay through native macOS Liquid Glass aesthetics, zero telemetry, sub-millisecond responsiveness, and progressive disclosure.

---

## 0. BetterDisplay Reverse-Engineering & REA Artifact Baseline

Полный каталог функций и иерархия меню BetterDisplay исследованы и задокументированы с помощью **REA (Reverse-Engineer-Anything) MCP**:
- 🌐 **Интерактивная карта интерфейса (HTML):** [`betterdisplay_structure/index.html`](betterdisplay_structure/index.html) — пошаговое описание выпадающего меню из статус-бара (Built-in Display, Studio Display XDR, Virtual 16:9, Tools), всех 13 подменю и 7 вкладок окна настроек (`SettingsView`).
- 📋 **Технический отчет и план низкоуровневой декомпиляции:** [`betterdisplay_structure/plan.md`](betterdisplay_structure/plan.md) — карта динамических символов (`IOKit`, `SkyLight`, `ScreenCaptureKit`, `ColorSync`, `CoreImage`), выделение arm64 среза и стратегия чистого (clean-room) воспроизведения.

---

## 1. High-Impact Product Proposals & Additional Features (Из BetterDisplay REA)

### 1.1 Complete 13 Submenus Architecture (Архитектура 13 подменю дисплея)
* **Проблема:** В текущем OpenDisplay расширенные настройки сгруппированы в единый drawer, тогда как пользователю требуется модульное раскрытие конкретных категорий (как в BetterDisplay):
  1. `Display Mode`: HiDPI (Scaled), LowDPI (Native), Favorites 1–5.
  2. `Refresh Rate`: 60Hz, 120Hz (ProMotion / VRR), 50Hz, кинематографические частоты.
  3. `Color Mode`: SDR/HDR, Force RGB 4:4:4, YCbCr 4:2:2, YCbCr 4:2:0, 8/10/12 bpc.
  4. `Mirror Display`: зеркалирование с адаптацией пропорций.
  5. `Stream Display`: полноэкранная трансляция видеопотока через ScreenCaptureKit.
  6. `Picture in Picture`: плавающий оверлей экрана или отдельного окна.
  7. `Move Display`: пространственное перемещение монитора в раскладке macOS.
  8. `Screen Rotation`: 0°, 90°, 180°, 270° через `SLSSetDisplayRotation`.
  9. `Image Adjustments`: программная гамма, насыщенность, баланс белого (Metal/LUT).
  10. `Color Profile`: системные ICC-профили ColorSync.
  11. `Apple Display Preset`: пресеты Apple XDR (P3-1600 nits, P3-500 nits и др.).
  12. `Configuration Protection`: фиксация раскладки, разрешения и частоты от сброса при сне.
  13. `Manage Display`: дампы DPCD, калибровка nits, инъекция кастомных EDID.

### 1.2 Display Notch Switch & Optimization
* **Проблема:** На ноутбуках с вырезом (MacBook Pro 14"/16", MacBook Air) рабочий стол либо перекрывается вырезом, либо не использует полезное пространство.
* **Предложение:** Внедрить тумблер `Display Notch`, переключающий между масштабированием рабочего стола под вырезом и черной полосой через альтернативные дескрипторы дисплея (`_notchAlternativeDisplayModeNumber` в SkyLight).

### 1.3 Virtual Screens Manager (Dummy Displays)
* **Проблема:** Нет возможности создать кастомные разрешения для записи экрана, трансляции по сети или Sidecar без физического монитора.
* **Предложение:** Реализовать модуль виртуальных дисплеев (16:9, 16:10, 21:9 UltraWide, iPad) через приватный драйвер `CGVirtualDisplay` / SkyLight с возможностью привязки в зеркало к физическому дисплею.

### 1.4 System Colors & Accessibility Filters (Tools Menu)
* **Проблема:** Системные настройки доступности macOS глобальны и неудобны для быстрого переключения.
* **Предложение:** Добавить в меню `Tools` секцию `System Colors`: инверсия цветов, монохром (оттенки серого), постеризация и кастомный оттеночный тинт (Night tint) на уровне WindowServer/CoreImage.

---

## 2. Prioritized Implementation Roadmap

| Priority | Feature Domain | Key Technologies | Expected User Value | Status |
| :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | **DDC Input Source Switching** | VCP `0x60`, IOAVService I2C | Instant DP/HDMI/USB-C input switching | **Completed (v1.1)** |
| **Phase 2** | **HiDPI Resolution Switcher** | SkyLight, CoreGraphics, GCD Math | Smart resolution picker with `★ RECOMMENDED` badges | **Completed (v1.2)** |
| **Phase 3** | **Liquid Glass UI Redesign** | SwiftUI, `.ultraThinMaterial`, AtlasTheme | Native macOS glassmorphism, dynamic hover status line | **Completed (v1.3)** |
| **Phase 4** | **Master-Slave Display Groups** | WorkspaceStore, Curve Offsets | Single slider/hotkey controls all screens simultaneously | **Completed (v1.4)** |
| **Phase 5** | **Window & App-Targeted PiP** | ScreenCaptureKit (`SCWindow`), AppKit Panel | Picture-in-Picture for specific apps with click-through | **Next Up** |
| **Phase 6** | **Display Notch Toggle & Mode Engine** | SkyLight Display Descriptors | Обход или скрытие выреза на MacBook Liquid Retina | Planned |
| **Phase 7** | **13 Modular Submenus** | PopoverSections, Progressive Disclosure | Иерархическое раскрытие настроек (Color, Presets, Move) | Planned |
| **Phase 8** | **Virtual Screens (Dummy 16:9 / 21:9)**| CGVirtualDisplay, SkyLight Virtualization | Создание фиктивных экранов для стриминга и HiDPI | Planned |
| **Phase 9** | **System Colors (Tools Menu)** | CoreImage CIFilter, WindowServer | Быстрый монохром, инверсия, ночной тинт экрана | Planned |
| **Phase 10**| **Layout & Config Protection on Wake** | CGWindowList, Accessibility API | Защита от сброса позиций окон и настроек герцовки | Planned |

---

## 3. Engineering & Quality Protocol

Каждый инкремент строго следует принципам:
1. **KISS (Keep It Simple, Stupid):** Плоские, прозрачные структуры данных без лишних уровней абстракций и промежуточных middleware.
2. **DRY (Don't Repeat Yourself):** Все команды (UI, CLI, хоткеи) исполняются строго через единый источник правды — `DisplayCommandDispatcher.shared`.
3. **SRP (Single Responsibility Principle):** Четкое разделение чистой бизнес-логики (математика кривых, парсинг EDID, парсинг аргументов) от низкоуровневых аппаратных вызовов (`IOAVService`, `SkyLight`). Чистая логика покрывается офлайн-тестами.
4. **Bundle-First Architecture:** Модули и UI упаковываются в целевой бандл приложения `/Applications/OpenDisplay.app` без разрозненных внешних зависимостей.
5. **Zero Magic Numbers:** Все опкоды, тайминги, размеры шрифтов и отступы вынесены в `Constants/` и `AtlasTheme.swift`.
6. **Automated Verification:**
   - SwiftLint проверка статического качества кода (`swiftlint lint`).
   - Модульные тесты Swift Package Manager (`swift test` в срезе Core).
   - Независимое архитектурное ревью через `opencode run -m zai-coding-plan/glm-5.3-flash`.
