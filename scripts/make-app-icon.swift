import AppKit
import CoreText

// Usage: swift scripts/make-app-icon.swift Airstamp/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
// Airstamp's app icon: Night Sky's charcoal base and a light New York serif "A" (D-38). 1024 x 1024, opaque.
let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let gradient = CGGradient(colorsSpace: space, colors: [CGColor(srgbRed: 0.17, green: 0.17, blue: 0.18, alpha: 1),
                                                     CGColor(srgbRed: 0.07, green: 0.07, blue: 0.08, alpha: 1)] as CFArray,
                          locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: CGFloat(size)), end: .zero, options: [])
let base = NSFont.systemFont(ofSize: 640, weight: .light)
let font = NSFont(descriptor: base.fontDescriptor.withDesign(.serif)!, size: 640)! as CTFont
let line = CTLineCreateWithAttributedString(NSAttributedString(string: "A", attributes: [
    .font: font, .foregroundColor: CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)]))
let bounds = CTLineGetImageBounds(line, ctx)
ctx.textPosition = CGPoint(x: (CGFloat(size) - bounds.width) / 2 - bounds.minX,
                           y: (CGFloat(size) - bounds.height) / 2 - bounds.minY)
CTLineDraw(line, ctx)
let url = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
