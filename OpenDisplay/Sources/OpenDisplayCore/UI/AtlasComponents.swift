#if os(macOS) && arch(arm64)
import SwiftUI

/// Section eyebrow with optional trailing count
public struct AtlasEyebrow: View {
    public let title: String
    public let trailing: String?

    public init(title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .semibold))
                .foregroundStyle(Color.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: AtlasTheme.fontCaptionSmall, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Capsule())
            }
        }
    }
}

/// Pill badge visual styles
public enum AtlasBadgeStyle {
    case lime
    case success
    case brand
    case muted
    case warning
}

/// Subtle native status badge
public struct AtlasBadge: View {
    public let text: String
    public let style: AtlasBadgeStyle

    public init(_ text: String, style: AtlasBadgeStyle) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(backgroundColor)
            .clipShape(Capsule())
    }

    private var foregroundColor: Color {
        switch style {
        case .lime, .brand: return Color.accentColor
        case .success: return Color.green
        case .warning: return Color.orange
        case .muted: return Color.secondary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .lime, .brand: return Color.accentColor.opacity(0.12)
        case .success: return Color.green.opacity(0.12)
        case .warning: return Color.orange.opacity(0.12)
        case .muted: return Color.primary.opacity(0.06)
        }
    }
}

/// No-op placeholder to maintain backward compatibility
public struct AtlasBlueprintGrid: View {
    public init() {}

    public var body: some View {
        EmptyView()
    }
}

/// Native macOS rounded pill button
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
                .font(.system(size: AtlasTheme.fontCaptionMedium, weight: .medium))
                .foregroundStyle(isActive ? .white : Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isActive ? Color.accentColor : Color.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AtlasTheme.controlRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Smooth native icon button with hover and rounded corner
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.primary)
                .frame(width: AtlasTheme.iconButtonSide, height: AtlasTheme.iconButtonSide)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Thin translucent divider
public struct AtlasDivider: View {
    public init() {}

    public var body: some View {
        Divider()
            .opacity(0.5)
    }
}

/// Standard native-styled toggle switch
public struct AtlasSwitch: View {
    @Binding public var isOn: Bool
    public let activeColor: Color

    public init(isOn: Binding<Bool>, activeColor: Color = Color.accentColor) {
        self._isOn = isOn
        self.activeColor = activeColor
    }

    public var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
    }
}

/// Clean system toggle row updating footer status bar on hover
public struct AtlasToggleRow<Trailing: View>: View {
    public let title: String
    public let helpText: String?
    @Binding public var isOn: Bool
    public let trailing: Trailing
    @ObservedObject private var store = WorkspaceStore.shared

    public init(
        title: String,
        helpText: String? = nil,
        isOn: Binding<Bool>
    ) where Trailing == EmptyView {
        self.title = title
        self.helpText = helpText
        self._isOn = isOn
        self.trailing = EmptyView()
    }

    public init(
        title: String,
        helpText: String? = nil,
        isOn: Binding<Bool>,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.helpText = helpText
        self._isOn = isOn
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: AtlasTheme.fontBodySmall, weight: .regular))
                .foregroundStyle(Color.primary)

            Spacer()
            trailing
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .contentShape(Rectangle())
        .onHover { isHovered in
            if let helpText {
                if isHovered {
                    store.activeTooltipText = helpText
                } else if store.activeTooltipText == helpText {
                    store.activeTooltipText = nil
                }
            }
        }
    }
}
#endif
