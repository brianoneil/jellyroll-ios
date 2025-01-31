import SwiftUI

struct SeriesGridView: View {
    let items: [MediaItem]
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(items) { item in
                    SeriesCard(item: item, style: .grid)
                }
            }
            .padding(.horizontal)
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
} 