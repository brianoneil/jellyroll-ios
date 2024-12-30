import SwiftUI

struct MovieDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.deviceOrientation) private var orientation
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingPlayer = false
    @State private var showFullOverview = false
    
    private var progressPercentage: Double {
        if let position = item.playbackPositionTicks,
           let total = item.runTimeTicks,
           total > 0 {
            return Double(position) / Double(total)
        }
        return 0
    }
    
    private var hasProgress: Bool {
        return progressPercentage > 0
    }
    
    private var shortOverview: String? {
        guard let overview = item.overview else { return nil }
        let words = overview.split(separator: " ")
        if words.count > 80 {
            return words.prefix(80).joined(separator: " ")
        }
        return overview
    }
    
    private var formattedReleaseDate: String? {
        guard let date = item.premiereDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeManager.currentTheme.backgroundColor,
                themeManager.currentTheme.backgroundColor,
                themeManager.currentTheme.backgroundColor.opacity(0.95),
                themeManager.currentTheme.backgroundColor
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var heroHeight: CGFloat {
        orientation == .portrait ? 260 : 200
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full screen hero image
            JellyfinImage(
                itemId: item.id,
                imageType: .backdrop,
                aspectRatio: 16/9,
                cornerRadius: 0,
                fallbackIcon: "film"
            )
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .scaledToFill()
            .clipped()
            .overlay {
                // Gradient overlay for readability
                LinearGradient(
                    colors: [
                        .clear,
                        themeManager.currentTheme.backgroundColor.opacity(0.4),
                        themeManager.currentTheme.backgroundColor.opacity(0.7),
                        themeManager.currentTheme.backgroundColor.opacity(0.9)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top navigation bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 48)
                    
                    Spacer()
                    .frame(height: orientation == .portrait ? 200 : 100)
                    
                    // Content
                    VStack(alignment: .leading, spacing: orientation == .portrait ? 24 : 16) {
                        // Title and metadata
                        VStack(alignment: .leading, spacing: 12) {
                            if item.imageTags["Logo"] != nil {
                                JellyfinImage(
                                    itemId: item.id,
                                    imageType: .logo,
                                    aspectRatio: 16/9,
                                    cornerRadius: 0,
                                    fallbackIcon: "film"
                                )
                                .frame(height: 40)
                                .frame(maxWidth: 300, alignment: .leading)
                                .scaledToFit()
                            } else {
                                Text(item.name)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                            }
                            
                            // Metadata row
                            HStack(spacing: 12) {
                                if let year = item.yearText {
                                    Text(year)
                                }
                                
                                if let runtime = item.formattedRuntime {
                                    Text("•")
                                    Text(runtime)
                                }
                                
                                if let rating = item.officialRating {
                                    Text("•")
                                    Text(rating)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            
                            // Genres
                            if !item.genres.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(item.genres.prefix(3), id: \.self) { genre in
                                        Text(genre)
                                    }
                                }
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            }
                        }
                        
                        // Action buttons
                        Button(action: { showingPlayer = true }) {
                            HStack(spacing: 8) {
                                if hasProgress {
                                    CircularProgressView(
                                        progress: progressPercentage,
                                        lineWidth: 2,
                                        size: 24,
                                        color: .white
                                    )
                                    .overlay {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 24, height: 24)
                                }
                                Text(hasProgress ? "Resume" : "Play")
                                    .fontWeight(.semibold)
                                    .frame(width: 70, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                            .frame(height: 48)
                            .background(themeManager.currentTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                        }
                        
                        // Overview
                        if let overview = item.overview {
                            Text(showFullOverview ? overview : (shortOverview ?? overview))
                                .font(.system(size: 15))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .lineSpacing(4)
                                .padding(.top, 8)
                            
                            if shortOverview != nil && !showFullOverview {
                                Button(action: { showFullOverview = true }) {
                                    Text("Read More")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(themeManager.currentTheme.tertiaryTextColor)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .background(themeManager.currentTheme.backgroundColor)
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showingPlayer) {
            VideoPlayerView(item: item)
        }
    }
}

// Helper view for flowing tag layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for row in result.rows {
            for element in row.elements {
                element.view.place(
                    at: CGPoint(x: bounds.minX + element.x, y: bounds.minY + element.y),
                    proposal: ProposedViewSize(element.size)
                )
            }
        }
    }
    
    struct FlowResult {
        struct Row {
            var elements: [(view: LayoutSubview, size: CGSize, x: CGFloat, y: CGFloat)]
            var height: CGFloat
        }
        
        var rows: [Row]
        var height: CGFloat
        
        init(in width: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var rows: [Row] = []
            var currentRow: [(view: LayoutSubview, size: CGSize, x: CGFloat, y: CGFloat)] = []
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width, !currentRow.isEmpty {
                    rows.append(Row(elements: currentRow, height: maxHeight))
                    currentRow = []
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                currentRow.append((subview, size, x, y))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            if !currentRow.isEmpty {
                rows.append(Row(elements: currentRow, height: maxHeight))
                y += maxHeight
            }
            
            self.rows = rows
            self.height = y
        }
    }
} 