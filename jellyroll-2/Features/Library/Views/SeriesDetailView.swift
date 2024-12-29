import SwiftUI

struct SeriesDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
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
                        fallbackIcon: "tv"
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .overlay(alignment: .bottom) {
                        JellyfinTheme.overlayGradient
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
                                fallbackIcon: "tv"
                            )
                            .frame(width: 120)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                            
                            Spacer()
                        }
                        .frame(height: 180)
                        
                        // Title and metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer()
                            
                            Text(item.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(JellyfinTheme.Text.primary(for: themeManager.currentMode))
                            
                            // Quick Info Row
                            HStack(spacing: 12) {
                                if let year = item.yearText {
                                    Text(year)
                                }
                                
                                if let genre = item.genreText {
                                    Text("•")
                                    Text(genre)
                                }
                            }
                            .font(.system(size: 15))
                            .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: -90)
                    .padding(.bottom, -90)
                    
                    // Overview
                    if let overview = item.overview {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(overview)
                                .font(.system(size: 15))
                                .foregroundColor(JellyfinTheme.Text.secondary(for: themeManager.currentMode))
                                .lineSpacing(4)
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
    }
} 