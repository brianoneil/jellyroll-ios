import SwiftUI

struct MovieDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
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
                JellyfinTheme.backgroundColor(for: themeManager.currentMode),
                JellyfinTheme.backgroundColor(for: themeManager.currentMode).opacity(0.95),
                JellyfinTheme.surfaceColor(for: themeManager.currentMode).opacity(0.05),
                JellyfinTheme.backgroundColor(for: themeManager.currentMode)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Section
                ZStack(alignment: .top) {
                    // Backdrop
                    JellyfinImage(
                        itemId: item.id,
                        imageType: .backdrop,
                        aspectRatio: 16/9,
                        cornerRadius: 0,
                        fallbackIcon: "film"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .overlay(alignment: .bottom) {
                        // Bottom gradient for text readability
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.3),
                                .black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 160)
                    }
                    
                    // Back button
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                            }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Content
                VStack(spacing: 24) {
                    // Poster and Metadata Section
                    HStack(spacing: 16) {
                        // Poster
                        VStack {
                            JellyfinImage(
                                itemId: item.id,
                                imageType: .primary,
                                aspectRatio: 2/3,
                                cornerRadius: 12,
                                fallbackIcon: "film"
                            )
                            .frame(width: 120)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                            
                            Spacer()
                        }
                        .frame(height: 180)
                        
                        // Title and metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer()
                            
                            if item.imageTags["Logo"] != nil {
                                JellyfinImage(
                                    itemId: item.id,
                                    imageType: .logo,
                                    aspectRatio: 16/9,
                                    cornerRadius: 0,
                                    fallbackIcon: "film"
                                )
                                .frame(height: 40)
                                .frame(maxWidth: 200)
                                .scaledToFit()
                            } else {
                                Text(item.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                            }
                            
                            // Quick Info Row
                            HStack(spacing: 12) {
                                if let year = item.yearText {
                                    Text(year)
                                }
                                
                                if let runtime = item.formattedRuntime {
                                    Text("•")
                                    Text(runtime)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                            
                            // Rating Row (if exists)
                            if let officialRating = item.officialRating {
                                Text(officialRating)
                                    .font(.system(size: 13))
                                    .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(JellyfinTheme.surfaceColor(for: themeManager.currentMode).opacity(0.1))
                                    .cornerRadius(6)
                            }
                            
                            // Additional Metadata
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    if item.userData.playCount > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 12))
                                            Text("Watched \(item.userData.playCount) time\(item.userData.playCount == 1 ? "" : "s")")
                                        }
                                    }
                                    
                                    if item.userData.isFavorite {
                                        HStack(spacing: 4) {
                                            Image(systemName: "heart.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.pink)
                                            Text("Favorite")
                                        }
                                    }
                                    
                                    if let releaseDate = formattedReleaseDate {
                                        Text(releaseDate)
                                    }
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundColor(JellyfinTheme.Text.tertiary(for: themeManager.currentMode))
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: -90)
                    .padding(.bottom, -90)
                    
                    // Featured Tagline (if only one exists)
                    if item.taglines.count == 1, let tagline = item.taglines.first {
                        Text(tagline)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Genres
                    if !item.genres.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(item.genres, id: \.self) { genre in
                                    Text(genre)
                                        .font(.system(size: 13, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Play Button and Progress
                    VStack(spacing: 8) {
                        Button(action: {
                            showingPlayer = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text(hasProgress ? "Resume" : "Play")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(JellyfinTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        if hasProgress {
                            HStack(spacing: 4) {
                                ProgressView(value: progressPercentage)
                                    .tint(JellyfinTheme.surfaceColor(for: themeManager.currentMode))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Overview
                    if let overview = item.overview {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(showFullOverview ? overview : (shortOverview ?? overview))
                                .font(.system(size: 15))
                                .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                                .lineSpacing(4)
                                .lineLimit(showFullOverview ? nil : 10)
                            
                            if overview.split(separator: " ").count > 80 {
                                Button(action: {
                                    withAnimation {
                                        showFullOverview.toggle()
                                    }
                                }) {
                                    Text(showFullOverview ? "Show less" : "More")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(JellyfinTheme.accentGradient)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Tags
                    if !item.taglines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                            
                            FlowLayout(spacing: 6) {
                                ForEach(item.taglines, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(JellyfinTheme.Text.tertiary(for: themeManager.currentMode))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(JellyfinTheme.surfaceColor(for: themeManager.currentMode).opacity(0.06))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .background(backgroundGradient)
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
        .preferredColorScheme(themeManager.currentMode == .dark ? .dark : .light)
        .fullScreenCover(isPresented: $showingPlayer) {
            NavigationView {
                VideoPlayerView(item: item)
            }
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