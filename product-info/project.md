├── jellyroll-2                          # Main app directory
│   ├── Assets.xcassets                  # App image and color assets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   ├── Contents.json
│   │   │   └── jamm-logo-dark-1024.png
│   │   ├── Contents.json
│   │   └── jamm-logo.imageset
│   │       ├── Contents.json
│   │       ├── jamm-logo-alpha 1.png
│   │       ├── jamm-logo-alpha 2.png
│   │       └── jamm-logo-alpha.png
│   ├── ContentView.swift                # Root view of the application
│   ├── Features                         # Core feature modules
│   │   ├── Auth                         # Authentication and server management
│   │   │   ├── Models                   # Data models for auth and server config
│   │   │   │   ├── AuthenticationToken.swift
│   │   │   │   ├── ServerConfiguration.swift
│   │   │   │   └── ServerHistory.swift
│   │   │   ├── Services                 # Auth, keychain, and server history handlers
│   │   │   │   ├── AuthenticationService.swift
│   │   │   │   ├── KeychainService.swift
│   │   │   │   └── ServerHistoryService.swift
│   │   │   ├── ViewModels              # Login business logic
│   │   │   │   └── LoginViewModel.swift
│   │   │   └── Views                   # Login UI components
│   │   │       └── LoginView.swift
│   │   ├── Home                        # Main app dashboard features
│   │   │   ├── ViewModels              # Home screen logic
│   │   │   │   └── HomeViewModel.swift
│   │   │   └── Views                   # Home, movies, TV shows UI components
│   │   │       ├── ContinueWatchingView.swift
│   │   │       ├── HomeView.swift
│   │   │       ├── MoviesView.swift
│   │   │       └── TVShowsView.swift
│   │   ├── Library                     # Media library management
│   │   │   ├── Models                  # Media and library item data structures
│   │   │   │   ├── LibraryItem.swift
│   │   │   │   └── MediaItem.swift
│   │   │   ├── Services                # Image handling and library operations
│   │   │   │   ├── ImageCacheService.swift
│   │   │   │   ├── ImageService.swift
│   │   │   │   └── LibraryService.swift
│   │   │   ├── ViewModels              # Library and series detail logic
│   │   │   │   ├── LibraryViewModel.swift
│   │   │   │   └── SeriesDetailViewModel.swift
│   │   │   └── Views                   # Media browsing and detail UI components
│   │   │       ├── ContinueWatchingCard.swift
│   │   │       ├── JellyfinImage.swift
│   │   │       ├── MovieCard.swift
│   │   │       ├── MovieDetailView.swift
│   │   │       ├── RecentlyAddedCard.swift
│   │   │       ├── SeriesCard.swift
│   │   │       ├── SeriesDetailView.swift
│   │   │       └── SeriesGridView.swift
│   │   ├── Playback                    # Media playback functionality
│   │   │   ├── Services                # Playback handling
│   │   │   │   └── PlaybackService.swift
│   │   │   ├── Utils                   # Progress tracking utilities
│   │   │   │   └── PlaybackProgressUtility.swift
│   │   │   ├── ViewModels              # Playback control logic
│   │   │   │   └── PlaybackViewModel.swift
│   │   │   └── Views                   # Video player and downloads UI
│   │   │       ├── DownloadsView.swift
│   │   │       └── VideoPlayerView.swift
│   │   ├── Settings                    # App configuration
│   │   │   └── Views                   # Settings and downloads management UI
│   │   │       ├── DownloadsManagementView.swift
│   │   │       └── SettingsView.swift
│   │   └── Shared                      # Shared app configurations
│   │       └── JellyfinClientConfig.swift
│   ├── Item.swift                      # Base item model
│   ├── JammPlayer.entitlements         # App capabilities and permissions
│   ├── Preview Content                 # SwiftUI preview assets
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Theme                           # App theming and layout
│   │   ├── BlurHash.swift
│   │   ├── JellyfinTheme.swift
│   │   ├── Layout                      # UI layout components and management
│   │   │   ├── LayoutComponents.swift
│   │   │   ├── LayoutManager.swift
│   │   │   ├── MovieDetailLayouts.swift
│   │   │   └── TabComponents.swift
│   │   └── ThemeManager.swift
│   └── jellyroll_2App.swift            # App entry point
├── jellyroll-2.xcodeproj               # Xcode project configuration
│   ├── project.pbxproj
│   ├── project.xcworkspace
│   │   ├── contents.xcworkspacedata
│   │   └── xcuserdata
│   │       └── boneil.xcuserdatad
│   │           └── UserInterfaceState.xcuserstate
│   └── xcuserdata
│       └── boneil.xcuserdatad
│           └── xcschemes
│               └── xcschememanagement.plist
├── jellyroll-2Tests                    # Unit tests
│   └── jellyroll_2Tests.swift
├── jellyroll-2UITests                  # UI automation tests
│   ├── jellyroll_2UITests.swift
│   └── jellyroll_2UITestsLaunchTests.swift
└── product-info                        # Project documentation and assets
    ├── jamm-logo-alpha.png
    ├── jamm-logo-dark-1024.png
    ├── jamm-logo-dark-background.png
    ├── jamm_logo.png
    ├── prd.md
    ├── tech-spec.md
    ├── themes.md
    └── working-features.md