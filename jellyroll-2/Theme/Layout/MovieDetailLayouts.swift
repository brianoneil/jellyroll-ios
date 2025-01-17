import SwiftUI
import UIKit

/// Orientation-specific layouts for movie detail view
struct MovieDetailLayouts {
    struct ExpandableText: View {
        let text: String
        @Binding var isExpanded: Bool
        @EnvironmentObject private var themeManager: ThemeManager
        
        private func shouldShowReadMore() -> Bool {
            let font = UIFont.systemFont(ofSize: 20) // .title3 equivalent
            let width = UIScreen.main.bounds.width - 32 // Account for padding
            let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
            
            let boundingBox = text.boundingRect(
                with: constraintRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            
            let lines = boundingBox.height / font.lineHeight
            return lines > 5
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineSpacing(8)
                    .lineLimit(isExpanded ? nil : 5)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if shouldShowReadMore() {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "Show Less" : "Read More")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(themeManager.currentTheme.accentGradient)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    /// Portrait layout for movie details
    struct PortraitLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @State private var isOverviewExpanded = false
        @State private var textHeight: CGFloat = 0
        
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    LayoutComponents.HeroSection(
                        imageId: item.id,
                        onBackTapped: dismiss
                    )
                    
                    // Content
                    VStack(spacing: 24) {
                        // Poster and Metadata Section
                        HStack(alignment: .top, spacing: 12) {
                            // Poster
                            LayoutComponents.MediaPoster(
                                itemId: item.id,
                                progress: hasProgress ? progressPercentage : nil
                            )
                            .frame(width: 100)
                            
                            // Metadata
                            LayoutComponents.MediaMetadata(
                                title: item.name,
                                year: item.yearText,
                                runtime: item.formattedRuntime,
                                rating: item.formattedRating,
                                genres: item.genres
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .offset(y: -90)
                        .padding(.bottom, -90)
                        
                        // Featured Tagline
                        if item.taglines.count == 1, let tagline = item.taglines.first {
                            Text(tagline)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        
                        // Play Button
                        Button(action: { showingPlayer.wrappedValue = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text(hasProgress ? "Resume" : "Play")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeManager.currentTheme.accentGradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        // Overview
                        if let overview = item.overview {
                            ExpandableText(text: overview, isExpanded: $isOverviewExpanded)
                        }
                        
                        // Cast Section
                        if !item.cast.isEmpty {
                            LayoutComponents.CastCrewSection(
                                title: "Cast",
                                people: item.cast.map { person in
                                    LayoutComponents.CastCrewSection.Person(
                                        id: person.id,
                                        name: person.name,
                                        role: person.role ?? "Unknown Role",
                                        imageId: person.primaryImageTag != nil ? person.id : nil
                                    )
                                }
                            )
                        }
                        
                        // Director Section
                        if !item.directors.isEmpty {
                            LayoutComponents.CastCrewSection(
                                title: "Director",
                                people: item.directors.map { person in
                                    LayoutComponents.CastCrewSection.Person(
                                        id: person.id,
                                        name: person.name,
                                        role: person.role ?? "Unknown Role",
                                        imageId: person.primaryImageTag != nil ? person.id : nil
                                    )
                                }
                            )
                        }
                        
                        // Writers Section
                        if !item.writers.isEmpty {
                            LayoutComponents.CastCrewSection(
                                title: "Writers",
                                people: item.writers.map { person in
                                    LayoutComponents.CastCrewSection.Person(
                                        id: person.id,
                                        name: person.name,
                                        role: person.role ?? "Unknown Role",
                                        imageId: person.primaryImageTag != nil ? person.id : nil
                                    )
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    /// Landscape layout for movie details
    struct LandscapeLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @State private var isOverviewExpanded = false
        
        var body: some View {
            HStack(spacing: 0) {
                // Left column with poster and play button
                VStack(spacing: 24) {
                    LayoutComponents.MediaPoster(
                        itemId: item.id,
                        progress: hasProgress ? progressPercentage : nil,
                        width: 200
                    )
                    
                    Button(action: { showingPlayer.wrappedValue = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text(hasProgress ? "Resume" : "Play")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(themeManager.currentTheme.accentGradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(24)
                .frame(width: 248)
                
                // Right column with scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        LayoutComponents.HeroSection(
                            imageId: item.id,
                            onBackTapped: dismiss
                        )
                        
                        VStack(spacing: 24) {
                            // Metadata
                            LayoutComponents.MediaMetadata(
                                title: item.name,
                                year: item.yearText,
                                runtime: item.formattedRuntime,
                                rating: item.formattedRating,
                                genres: item.genres
                            )
                            .padding(.horizontal, 24)
                            
                            // Featured Tagline
                            if item.taglines.count == 1, let tagline = item.taglines.first {
                                Text(tagline)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Overview
                            if let overview = item.overview {
                                ExpandableText(text: overview, isExpanded: $isOverviewExpanded)
                            }
                            
                            // Cast Section
                            if !item.cast.isEmpty {
                                LayoutComponents.CastCrewSection(
                                    title: "Cast",
                                    people: item.cast.map { person in
                                        LayoutComponents.CastCrewSection.Person(
                                            id: person.id,
                                            name: person.name,
                                            role: person.role ?? "Unknown Role",
                                            imageId: person.primaryImageTag != nil ? person.id : nil
                                        )
                                    }
                                )
                                .padding(.horizontal, 24)
                            }
                            
                            // Director Section
                            if !item.directors.isEmpty {
                                LayoutComponents.CastCrewSection(
                                    title: "Director",
                                    people: item.directors.map { person in
                                        LayoutComponents.CastCrewSection.Person(
                                            id: person.id,
                                            name: person.name,
                                            role: person.role ?? "Unknown Role",
                                            imageId: person.primaryImageTag != nil ? person.id : nil
                                        )
                                    }
                                )
                                .padding(.horizontal, 24)
                            }
                            
                            // Writers Section
                            if !item.writers.isEmpty {
                                LayoutComponents.CastCrewSection(
                                    title: "Writers",
                                    people: item.writers.map { person in
                                        LayoutComponents.CastCrewSection.Person(
                                            id: person.id,
                                            name: person.name,
                                            role: person.role ?? "Unknown Role",
                                            imageId: person.primaryImageTag != nil ? person.id : nil
                                        )
                                    }
                                )
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.vertical, 24)
                    }
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .all)
        }
    }
    
    /// iPad-optimized layout for movie details
    struct IPadLayout: View {
        let item: MediaItem
        let hasProgress: Bool
        let progressPercentage: Double
        let progressText: String
        let showingPlayer: Binding<Bool>
        let dismiss: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @EnvironmentObject private var layoutManager: LayoutManager
        @State private var isOverviewExpanded = false
        @State private var textHeight: CGFloat = 0
        
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section with back button
                    LayoutComponents.HeroSection(
                        imageId: item.id,
                        onBackTapped: dismiss
                    )
                    
                    // Content
                    VStack(spacing: 32) {
                        // Poster and Metadata Section
                        HStack(alignment: .top, spacing: 24) {
                            // Poster
                            LayoutComponents.MediaPoster(
                                itemId: item.id,
                                progress: hasProgress ? progressPercentage : nil,
                                width: 220
                            )
                            
                            // Metadata
                            VStack(alignment: .leading, spacing: 16) {
                                Text(item.name)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                
                                // Metadata row
                                HStack(spacing: 24) {
                                    if let year = item.yearText {
                                        Text(year)
                                            .font(.title3)
                                    }
                                    if let runtime = item.formattedRuntime {
                                        Text(runtime)
                                            .font(.title3)
                                    }
                                    if let rating = item.formattedRating {
                                        Text(rating)
                                            .font(.title3)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(themeManager.currentTheme.elevatedSurfaceColor)
                                            .cornerRadius(6)
                                    }
                                }
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                
                                // Play Button
                                Button(action: { showingPlayer.wrappedValue = true }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "play.fill")
                                            .font(.title3)
                                        Text(hasProgress ? "Resume" : "Play")
                                            .font(.title3.weight(.semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(themeManager.currentTheme.accentGradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                                .frame(maxWidth: 300)
                                
                                // Genres
                                if !item.genres.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(item.genres, id: \.self) { genre in
                                                Text(genre)
                                                    .font(.title3.weight(.medium))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(themeManager.currentTheme.elevatedSurfaceColor)
                                                    .cornerRadius(20)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .offset(y: -160)
                        .padding(.bottom, -160)
                        
                        // Tagline
                        if item.taglines.count == 1, let tagline = item.taglines.first {
                            Text(tagline)
                                .font(.title3.weight(.medium))
                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, 32)
                        }
                        
                        // Overview
                        if let overview = item.overview {
                            ExpandableText(text: overview, isExpanded: $isOverviewExpanded)
                        }
                        
                        // Cast Section
                        if !item.cast.isEmpty {
                            LayoutComponents.CastCrewSection(
                                title: "Cast",
                                people: item.cast.map { person in
                                    LayoutComponents.CastCrewSection.Person(
                                        id: person.id,
                                        name: person.name,
                                        role: person.role ?? "Unknown Role",
                                        imageId: person.primaryImageTag != nil ? person.id : nil
                                    )
                                }
                            )
                            .padding(.horizontal, 32)
                        }
                        
                        // Director Section
                        if !item.directors.isEmpty {
                            LayoutComponents.CastCrewSection(
                                title: "Director",
                                people: item.directors.map { person in
                                    LayoutComponents.CastCrewSection.Person(
                                        id: person.id,
                                        name: person.name,
                                        role: person.role ?? "Unknown Role",
                                        imageId: person.primaryImageTag != nil ? person.id : nil
                                    )
                                }
                            )
                            .padding(.horizontal, 32)
                        }
                        
                        // Writers Section
                        if !item.writers.isEmpty {
                            LayoutComponents.CastCrewSection(
                                title: "Writers",
                                people: item.writers.map { person in
                                    LayoutComponents.CastCrewSection.Person(
                                        id: person.id,
                                        name: person.name,
                                        role: person.role ?? "Unknown Role",
                                        imageId: person.primaryImageTag != nil ? person.id : nil
                                    )
                                }
                            )
                            .padding(.horizontal, 32)
                        }
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.vertical, 24)
                }
            }
            .background(themeManager.currentTheme.backgroundColor)
            .ignoresSafeArea(edges: .all)
        }
    }
} 