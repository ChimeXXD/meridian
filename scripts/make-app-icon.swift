import AppKit

// Usage: swift scripts/make-app-icon.swift Meridian/Resources/Assets.xcassets/AppIcon.appiconset
// Meridian's app icon: the Longitudes mark (a globe drawn by its meridians; yours at full strength rising to a star)
// on Night Sky's neutral night, the star in Meridian Gold (D-53, D-54). Writes the three iOS appearances, 1024 x 1024,
// opaque: AppIcon.png (any), AppIcon-Dark.png (dark) and AppIcon-Tinted.png (the grayscale source iOS tints).
// The geometry is the design system's (design-system/assets/site.js, `logoInner`): a 100-unit grid placed at
// translate(202, 219) scale(6.2).
let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

struct Variant {
    let file: String
    let background: (CGColor, CGColor)
    let ink: CGColor
    let star: CGColor
}

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

let night = (rgb(0x1C1C1C), rgb(0x0D0D0E))
let variants = [
    Variant(file: "AppIcon.png", background: night, ink: rgb(0xF4EFE4), star: rgb(0xE9C46A)),
    Variant(file: "AppIcon-Dark.png", background: night, ink: rgb(0xF4EFE4), star: rgb(0xE9C46A)),
    Variant(file: "AppIcon-Tinted.png", background: (rgb(0x1A1A1A), rgb(0x000000)), ink: rgb(0xFFFFFF),
            star: rgb(0xFFFFFF)),
]
let meridians: [CGFloat] = [22.28, 28.79, 38.52, 61.48, 71.21, 77.72]

func draw(_ variant: Variant, into folder: URL) {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    // CoreGraphics' origin is bottom-left; flip so the SVG's coordinates apply as written.
    ctx.translateBy(x: 0, y: CGFloat(size))
    ctx.scaleBy(x: 1, y: -1)

    // radialGradient cx 0.5, cy 0.35, r 0.75 of the canvas.
    let gradient = CGGradient(colorsSpace: space, colors: [variant.background.0, variant.background.1] as CFArray,
                              locations: [0, 1])!
    let centre = CGPoint(x: 0.5 * CGFloat(size), y: 0.35 * CGFloat(size))
    ctx.drawRadialGradient(gradient, startCenter: centre, startRadius: 0, endCenter: centre,
                           endRadius: 0.75 * CGFloat(size), options: [.drawsAfterEndLocation])

    ctx.translateBy(x: 202, y: 219)
    ctx.scaleBy(x: 6.2, y: 6.2)
    ctx.setLineCap(.round)

    // The other meridians: stroke 2.5 at 32%, clipped to the globe.
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(x: 20, y: 26, width: 60, height: 60))
    ctx.clip()
    ctx.setStrokeColor(variant.ink.copy(alpha: 0.32)!)
    ctx.setLineWidth(2.5)
    for x in meridians {
        ctx.move(to: CGPoint(x: x, y: 20))
        ctx.addLine(to: CGPoint(x: x, y: 92))
    }
    ctx.strokePath()
    ctx.restoreGState()

    // Yours: full strength, rising past the globe.
    ctx.setStrokeColor(variant.ink)
    ctx.setLineWidth(3.5)
    ctx.move(to: CGPoint(x: 50, y: 86))
    ctx.addLine(to: CGPoint(x: 50, y: 20))
    ctx.strokePath()

    // The star.
    ctx.setFillColor(variant.star)
    ctx.fillEllipse(in: CGRect(x: 46.5, y: 8.5, width: 7, height: 7))

    let url = folder.appendingPathComponent(variant.file) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
}

let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
variants.forEach { draw($0, into: folder) }
