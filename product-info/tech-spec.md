
### Image Placeholder

this project uses blurhash for loading placeholder images from the metadata.  When showing an image, always try to load the blur hash for the placeholder if available.

#### Theme Usage Guidelines
1. Always access theme properties through the `@EnvironmentObject` `themeManager`:
   ```swift
   @EnvironmentObject private var themeManager: ThemeManager
   // Use: themeManager.currentTheme.propertyName
   ```
2. Use semantic color properties instead of raw colors:
   - `backgroundColor` for main backgrounds
   - `surfaceColor` for elevated content
   - `primaryTextColor` for important text
   - `secondaryTextColor` for supporting text
   - `accentColor` for highlights and actions
3. For gradients, use the pre-defined gradient properties:
   - `backgroundGradient` for full-screen backgrounds
   - `accentGradient` for interactive elements
   - `textGradient` for emphasized text
   - `overlayGradient` for image overlays
4. Theme changes are handled automatically through the environment
5. new semantic color properties can be added to the theme manager for new use cases
6. new gradient properties can be added to the theme manager for new use cases
7. Never use raw colors in the code, always use the semantic color properties
