import SwiftUI

/// Shared layout components that can be used across different orientations
struct LayoutComponents {
    /// Hero section layout for media details
    struct HeroSection: View {
        let imageId: String
        var showBackButton: Bool = true
        let onBackTapped: () -> Void
        @EnvironmentObject private var themeManager: ThemeManager
        @EnvironmentObject private var layoutManager: LayoutManager
        
        private var heroHeight: CGFloat {
            layoutManager.isPad ? 500 : 300
        }
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                // Background Image
                JellyfinImage(
                    itemId: imageId,
                    imageType: .backdrop,
                    aspectRatio: 16/9,
                    fallbackIcon: "film"
                )
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .clipped()
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        .black.opacity(0.8),
                        .black.opacity(0.5),
                        .black.opacity(0.3),
                        .clear,
                        .black.opacity(0.4),
                        .black.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: heroHeight)
                
                // Back button
                if showBackButton {
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(24)
                }
            }
        }
    }
    
    /// Media poster with optional progress indicator
    struct MediaPoster: View {
        let itemId: String
        var progress: Double? = nil
        var width: CGFloat = 120
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            VStack(spacing: 0) {
                JellyfinImage(
                    itemId: itemId,
                    imageType: .primary,
                    aspectRatio: 2/3,
                    cornerRadius: 12,
                    fallbackIcon: "film"
                )
                .frame(width: width)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                
                if let progress = progress {
                    GeometryReader { metrics in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(themeManager.currentTheme.surfaceColor.opacity(0.2))
                                .frame(height: 3)
                            
                            Rectangle()
                                .fill(themeManager.currentTheme.accentGradient)
                                .frame(width: max(0, min(metrics.size.width * progress, metrics.size.width)), height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 8)
                }
            }
        }
    }
    
    /// Cast and Crew section layout
    struct CastCrewSection: View {
        struct Person: Identifiable {
            let id: String
            let name: String
            let role: String
            let imageId: String?
        }
        
        let title: String
        let people: [Person]
        @EnvironmentObject private var themeManager: ThemeManager
        @EnvironmentObject private var layoutManager: LayoutManager
        @State private var isExpanded = false
        
        private var groupedPeople: [String: [Person]] {
            Dictionary(grouping: people) { person in
                if person.role.contains("Director") {
                    return "Director"
                } else if person.role.contains("Writer") {
                    return "Writer"
                } else {
                    return "Actor"
                }
            }
        }
        
        private var director: Person? {
            groupedPeople["Director"]?.first
        }
        
        private var actors: [Person] {
            (groupedPeople["Actor"] ?? []).prefix(3).map { $0 }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Header and Preview
                Button(action: { withAnimation(.spring()) { isExpanded.toggle() }}) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cast & Crew")
                            .font(.title2.weight(.bold))
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        
                        if !isExpanded {
                            HStack(spacing: 16) {
                                if let director = director {
                                    HStack(spacing: 8) {
                                        PersonThumbnail(person: director, size: 32)
                                        VStack(alignment: .leading) {
                                            Text("Director:")
                                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                            Text(director.name)
                                                .fontWeight(.medium)
                                        }
                                        .font(.system(size: 15))
                                    }
                                }
                                
                                if !actors.isEmpty {
                                    Divider()
                                        .frame(height: 16)
                                    
                                    HStack(spacing: 8) {
                                        HStack(spacing: -8) {
                                            ForEach(actors) { actor in
                                                PersonThumbnail(person: actor, size: 32)
                                            }
                                        }
                                        VStack(alignment: .leading) {
                                            Text("Starring:")
                                                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                                            Text(actors.map { $0.name }.joined(separator: ", "))
                                                .fontWeight(.medium)
                                                + Text(people.count > 3 ? " and others" : "")
                                        }
                                        .font(.system(size: 15))
                                    }
                                }
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.down")
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                    }
                    .padding(24)
                    .background(themeManager.currentTheme.elevatedSurfaceColor)
                    .cornerRadius(12)
                }
                
                // Expanded Content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(Array(groupedPeople.keys.sorted()), id: \.self) { type in
                            if let people = groupedPeople[type] {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("\(type)s (\(people.count))")
                                        .font(.title3.weight(.semibold))
                                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(people) { person in
                                            PersonCard(person: person)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .background(themeManager.currentTheme.elevatedSurfaceColor)
            .cornerRadius(12)
        }
    }
    
    private struct PersonThumbnail: View {
        let person: CastCrewSection.Person
        let size: CGFloat
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            if let imageId = person.imageId {
                GeometryReader { geometry in
                    JellyfinImage(
                        itemId: imageId,
                        imageType: .primary,
                        aspectRatio: 1,
                        cornerRadius: 0,
                        fallbackIcon: "person.fill"
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(width: size, height: size)
                .background(themeManager.currentTheme.elevatedSurfaceColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
            } else {
                Circle()
                    .fill(themeManager.currentTheme.elevatedSurfaceColor)
                    .frame(width: size, height: size)
                    .overlay(
                        Text(person.name.prefix(1))
                            .font(.system(size: size/3))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    )
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
            }
        }
    }
    
    private struct PersonCard: View {
        let person: CastCrewSection.Person
        @EnvironmentObject private var themeManager: ThemeManager
        @State private var isHovered = false
        
        var body: some View {
            VStack(spacing: 12) {
                PersonThumbnail(person: person, size: 80)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3), value: isHovered)
                
                VStack(spacing: 4) {
                    Text(person.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(person.role)
                        .font(.system(size: 13))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .background(themeManager.currentTheme.surfaceColor.opacity(isHovered ? 0.5 : 0))
            .cornerRadius(12)
            .onHover { isHovered = $0 }
        }
    }
    
    /// Media metadata display (title, year, runtime, etc.)
    struct MediaMetadata: View {
        let title: String
        let year: String?
        let runtime: String?
        let rating: String?
        let genres: [String]
        @EnvironmentObject private var themeManager: ThemeManager
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                // Quick Info Row
                HStack(spacing: 12) {
                    if let year = year {
                        Text(year)
                    }
                    
                    if let runtime = runtime {
                        Text("•")
                        Text(runtime)
                    }
                    
                    if let rating = rating {
                        Text("•")
                        Text(rating)
                            .font(.system(size: 13))
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(themeManager.currentTheme.surfaceColor.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .font(.system(size: 15))
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                // Genres
                if !genres.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(genres, id: \.self) { genre in
                                Text(genre)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
    }
} 