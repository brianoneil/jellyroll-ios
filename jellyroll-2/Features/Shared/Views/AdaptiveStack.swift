import SwiftUI

struct AdaptiveStack<Content: View>: View {
    @Environment(\.deviceOrientation) private var orientation
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content
    
    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        Group {
            if orientation == .portrait {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content()
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content()
                }
            }
        }
    }
} 