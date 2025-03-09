import SwiftUI

#if os(tvOS)
/// A custom button style for tvOS cards
struct TVCardButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isFocused) private var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isSelected ? .white : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .clipShape(Capsule())
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.spring(response: 0.3), value: isFocused)
    }
}

extension ButtonStyle where Self == TVCardButtonStyle {
    static func tvCard(isSelected: Bool) -> TVCardButtonStyle {
        TVCardButtonStyle(isSelected: isSelected)
    }
}
#endif 