#if os(macOS)
import AppKit
public typealias CrossPlatformImage = NSImage
public typealias CrossPlatformColor = NSColor
#else
import UIKit
public typealias CrossPlatformImage = UIImage
public typealias CrossPlatformColor = UIColor
#endif

/// Cross-platform image and color utilities
public class ImageLoader {

    /// Load an image from the bundle
    public static func loadImage(named name: String) -> CrossPlatformImage? {
        let bundle = Bundle(for: ImageLoader.self)

        // Try bundle resource path directly
        if let bundlePath = bundle.path(forResource: name, ofType: "jpg") {
            #if os(macOS)
            return NSImage(contentsOfFile: bundlePath)
            #else
            return UIImage(contentsOfFile: bundlePath)
            #endif
        }
        if let bundlePath = bundle.path(forResource: name, ofType: "png") {
            #if os(macOS)
            return NSImage(contentsOfFile: bundlePath)
            #else
            return UIImage(contentsOfFile: bundlePath)
            #endif
        }

        // Try bundle's Resources/Textures/8K subdirectory
        if let resourcePath = bundle.resourcePath {
            let texturePaths = [
                "\(resourcePath)/Textures/8K/\(name).jpg",
                "\(resourcePath)/Textures/8K/\(name).png"
            ]
            for path in texturePaths {
                if FileManager.default.fileExists(atPath: path) {
                    #if os(macOS)
                    return NSImage(contentsOfFile: path)
                    #else
                    return UIImage(contentsOfFile: path)
                    #endif
                }
            }
        }

        // Priority 2: Development fallback (project directory)
        // Only used during Xcode development/debugging
        let devPaths = [
            "/Users/pro/Projects/Screensaver/Resources/Textures/8K/\(name).jpg",
            "/Users/pro/Projects/Screensaver/Resources/Textures/8K/\(name).png"
        ]

        for path in devPaths {
            if FileManager.default.fileExists(atPath: path) {
                #if os(macOS)
                return NSImage(contentsOfFile: path)
                #else
                return UIImage(contentsOfFile: path)
                #endif
            }
        }

        // Log missing texture for debugging
        #if DEBUG
        print("⚠️ ImageLoader: Image '\(name)' not found in bundle or development paths")
        #endif

        return nil
    }

    /// Create a color from RGB values
    public static func color(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> CrossPlatformColor {
        #if os(macOS)
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
        #else
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        #endif
    }

    /// Create a color from white value
    public static func color(white: CGFloat, alpha: CGFloat = 1.0) -> CrossPlatformColor {
        #if os(macOS)
        return NSColor(white: white, alpha: alpha)
        #else
        return UIColor(white: white, alpha: alpha)
        #endif
    }

    /// Predefined colors
    public static var orange: CrossPlatformColor {
        #if os(macOS)
        return .orange
        #else
        return .orange
        #endif
    }

    public static var gray: CrossPlatformColor {
        #if os(macOS)
        return .gray
        #else
        return .gray
        #endif
    }

    public static var blue: CrossPlatformColor {
        #if os(macOS)
        return .blue
        #else
        return .blue
        #endif
    }

    public static var white: CrossPlatformColor {
        #if os(macOS)
        return .white
        #else
        return .white
        #endif
    }

    public static var black: CrossPlatformColor {
        #if os(macOS)
        return .black
        #else
        return .black
        #endif
    }
}