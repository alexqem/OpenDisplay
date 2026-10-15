#if os(macOS) && arch(arm64)
import SwiftUI

/// Uppercase monospaced section eyebrow with optional trailing count pill
public struct AtlasEyebrow: View {
    public let title: String
    public let trailing: String?

    public init(title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                .foregroundStyle(AtlasTheme.textMuted)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .bold, design: .monospaced))
                    .foregroundStyle(AtlasTheme.cobalt)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AtlasTheme.cobaltSofter)
                    .clipShape(Capsule())
            }
        }
    }
}

/// Pill badge visual styles (the only curved elements in Atlas / TypeUI)
public enum AtlasBadgeStyle {
    case lime
    case success
    case brand
    case muted
    case warning
}

/// High-precision status pill badge
public struct AtlasBadge: View {
    public let text: String
    public let style: AtlasBadgeStyle

    public init(_ text: String, style: AtlasBadgeStyle) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        Text(text)
            .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .bold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .overlay(
                Capsule().stroke(borderColor, lineWidth: AtlasTheme.borderWidth)
            )
    }

    private var foregroundColor: Color {
        switch style {
        case .lime: return AtlasTheme.cobaltDark
        case .success: return AtlasTheme.successGreen
        case .brand: return AtlasTheme.cobalt
        case .warning: return AtlasTheme.warningOrange
        case .muted: return AtlasTheme.textMuted
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .lime: return AtlasTheme.electricLime
        case .success: return AtlasTheme.successSoft
        case .brand: return AtlasTheme.cobaltSofter
        case .warning: return AtlasTheme.warningSoft
        case .muted: return AtlasTheme.surfaceCard
        }
    }

    private var borderColor: Color {
        switch style {
        case .muted: return AtlasTheme.borderMedium
        default: return .clear
        }
    }
}

/// Signature blueprint grid texture: 1px technical lines with radial fade mask
public struct AtlasBlueprintGrid: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let step = AtlasTheme.blueprintGridSpacing
            let lineColor = AtlasTheme.cobaltSoft

            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(lineColor), lineWidth: AtlasTheme.borderWidth)
                y += step
            }

            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(lineColor), lineWidth: AtlasTheme.borderWidth)
                x += step
            }
        }
        .opacity(0.35)
        .mask(
            LinearGradient(
                colors: [.black, .black.opacity(0.25), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .allowsHitTesting(false)
    }
}

/// Sharp 0px action pill with reactive active state
public struct AtlasPillButton: View {
    public let title: String
    public let isActive: Bool
    public let action: () -> Void

    public init(title: String, isActive: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                .foregroundStyle(isActive ? .white : AtlasTheme.cobalt)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isActive ? AtlasTheme.cobalt : AtlasTheme.surfaceCard)
                .overlay(
                    Rectangle().stroke(isActive ? AtlasTheme.cobaltDark : AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Small square sharp icon button with 1px border
public struct AtlasIconButton: View {
    public let systemName: String
    public let action: () -> Void

    public init(systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                .foregroundStyle(AtlasTheme.cobalt)
                .frame(width: AtlasTheme.iconButtonSide, height: AtlasTheme.iconButtonSide)
                .background(AtlasTheme.surfaceCard)
                .overlay(
                    Rectangle().stroke(AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

/// 1px crisp structural divider
public struct AtlasDivider: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .frame(height: AtlasTheme.borderWidth)
            .foregroundStyle(AtlasTheme.borderDefault)
    }
}

/// High-precision Swiss Neo-Brutalist toggle switch with smooth animated feedback
public struct AtlasSwitch: View {
    @Binding public var isOn: Bool
    public let activeColor: Color

    public init(isOn: Binding<Bool>, activeColor: Color = AtlasTheme.cobalt) {
        self._isOn = isOn
        self.activeColor = activeColor
    }

    public var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: AtlasTheme.switchAnimationDuration)) {
                isOn.toggle()
            }
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                // Background Track: Sharp 0px border, high contrast
                Rectangle()
                    .fill(isOn ? activeColor : AtlasTheme.surfaceCard)
                    .frame(width: AtlasTheme.switchWidth, height: AtlasTheme.switchHeight)
                    .overlay(
                        Rectangle().stroke(isOn ? activeColor : AtlasTheme.borderMedium, lineWidth: AtlasTheme.borderWidth)
                    )

                // Slider Thumb: Sharp 0px square block
                Rectangle()
                    .fill(isOn ? Color.white : AtlasTheme.textMuted)
                    .frame(width: AtlasTheme.switchThumbSize, height: AtlasTheme.switchThumbSize)
                    .padding(AtlasTheme.switchThumbPadding)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Labeled system toggle row with optional trailing accessory (slider, picker)
public struct AtlasToggleRow<Trailing: View>: View {
    public let title: String
    @Binding public var isOn: Bool
    public let trailing: Trailing

    public init(
        title: String,
        isOn: Binding<Bool>
    ) where Trailing == EmptyView {
        self.title = title
        self._isOn = isOn
        self.trailing = EmptyView()
    }

    public init(
        title: String,
        isOn: Binding<Bool>,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self._isOn = isOn
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: AtlasTheme.fontBodySmall, weight: .semibold))
                .foregroundStyle(AtlasTheme.textBody)
            Spacer()
            trailing
            AtlasSwitch(isOn: $isOn)
        }
    }
}
#endif
