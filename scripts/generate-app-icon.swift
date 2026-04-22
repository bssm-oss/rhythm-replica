import AppKit
import Foundation

struct Palette {
    static let base = NSColor(calibratedRed: 32 / 255, green: 29 / 255, blue: 29 / 255, alpha: 1)
    static let baseTop = NSColor(calibratedRed: 45 / 255, green: 40 / 255, blue: 40 / 255, alpha: 1)
    static let baseBottom = NSColor(calibratedRed: 22 / 255, green: 19 / 255, blue: 19 / 255, alpha: 1)
    static let elevated = NSColor(calibratedRed: 48 / 255, green: 44 / 255, blue: 44 / 255, alpha: 1)
    static let primary = NSColor(calibratedRed: 253 / 255, green: 252 / 255, blue: 252 / 255, alpha: 1)
    static let secondary = NSColor(calibratedRed: 154 / 255, green: 152 / 255, blue: 152 / 255, alpha: 1)
    static let accent = NSColor(calibratedRed: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)
    static let ember = NSColor(calibratedRed: 255 / 255, green: 159 / 255, blue: 10 / 255, alpha: 1)
}

struct IconSlot {
    let pointSize: Int
    let scale: Int

    var pixelSize: Int { pointSize * scale }
    var filename: String {
        if scale == 1 {
            return "icon_\(pointSize)x\(pointSize).png"
        }
        return "icon_\(pointSize)x\(pointSize)@\(scale)x.png"
    }
}

let slots: [IconSlot] = [
    .init(pointSize: 16, scale: 1),
    .init(pointSize: 16, scale: 2),
    .init(pointSize: 32, scale: 1),
    .init(pointSize: 32, scale: 2),
    .init(pointSize: 128, scale: 1),
    .init(pointSize: 128, scale: 2),
    .init(pointSize: 256, scale: 1),
    .init(pointSize: 256, scale: 2),
    .init(pointSize: 512, scale: 1),
    .init(pointSize: 512, scale: 2)
]

enum IconGenerationError: Error {
    case bitmapCreationFailed
    case pngEncodingFailed
    case graphicsContextUnavailable
    case iconutilFailed(code: Int32)
}

func writeJSON(_ object: Any, to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}

func roundedRect(_ rect: CGRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func drawLinearGradient(in rect: CGRect, from startColor: NSColor, to endColor: NSColor, angle: CGFloat) {
    let gradient = NSGradient(starting: startColor, ending: endColor)
    gradient?.draw(in: roundedRect(rect, radius: rect.width * 0.18), angle: angle)
}

func drawRadialGlow(in context: CGContext, rect: CGRect, color: NSColor, alpha: CGFloat, start: CGPoint, end: CGPoint, startRadius: CGFloat, endRadius: CGFloat) {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [color.withAlphaComponent(alpha).cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
        locations: [0, 1]
    ) else {
        return
    }

    context.saveGState()
    context.addPath(CGPath(roundedRect: rect, cornerWidth: rect.width * 0.18, cornerHeight: rect.height * 0.18, transform: nil))
    context.clip()
    context.drawRadialGradient(gradient, startCenter: start, startRadius: startRadius, endCenter: end, endRadius: endRadius, options: [.drawsAfterEndLocation])
    context.restoreGState()
}

func drawIcon(size: Int) throws -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw IconGenerationError.bitmapCreationFailed
    }

    bitmap.size = NSSize(width: size, height: size)

    guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw IconGenerationError.graphicsContextUnavailable
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext

    let context = graphicsContext.cgContext

    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    context.clear(CGRect(x: 0, y: 0, width: size, height: size))

    let canvas = CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size))
    let outerInset = CGFloat(size) * 0.055
    let outerRect = canvas.insetBy(dx: outerInset, dy: outerInset)
    let radius = CGFloat(size) * 0.225
    let panelPath = roundedRect(outerRect, radius: radius)

    fill(panelPath, color: Palette.base)
    drawLinearGradient(in: outerRect, from: Palette.baseTop, to: Palette.baseBottom, angle: -90)

    drawRadialGlow(
        in: context,
        rect: outerRect,
        color: Palette.accent,
        alpha: 0.22,
        start: CGPoint(x: outerRect.minX + outerRect.width * 0.24, y: outerRect.maxY - outerRect.height * 0.16),
        end: CGPoint(x: outerRect.minX + outerRect.width * 0.24, y: outerRect.maxY - outerRect.height * 0.16),
        startRadius: 0,
        endRadius: outerRect.width * 0.44
    )
    drawRadialGlow(
        in: context,
        rect: outerRect,
        color: Palette.ember,
        alpha: 0.12,
        start: CGPoint(x: outerRect.maxX - outerRect.width * 0.18, y: outerRect.minY + outerRect.height * 0.2),
        end: CGPoint(x: outerRect.maxX - outerRect.width * 0.18, y: outerRect.minY + outerRect.height * 0.2),
        startRadius: 0,
        endRadius: outerRect.width * 0.36
    )

    let borderWidth = max(CGFloat(size) * 0.012, 1)
    stroke(panelPath, color: Palette.primary.withAlphaComponent(0.12), width: borderWidth)

    let innerRect = outerRect.insetBy(dx: CGFloat(size) * 0.018, dy: CGFloat(size) * 0.018)
    let innerPath = roundedRect(innerRect, radius: radius * 0.88)
    stroke(innerPath, color: Palette.primary.withAlphaComponent(0.05), width: max(CGFloat(size) * 0.004, 1))

    let laneRect = outerRect.insetBy(dx: outerRect.width * 0.14, dy: outerRect.height * 0.18)
    let laneYs: [CGFloat] = [0.22, 0.40, 0.58, 0.76]
    for laneY in laneYs {
        let y = laneRect.minY + laneRect.height * laneY
        let lanePath = NSBezierPath()
        lanePath.move(to: CGPoint(x: laneRect.minX, y: y))
        lanePath.line(to: CGPoint(x: laneRect.maxX, y: y))
        lanePath.lineCapStyle = .round
        stroke(lanePath, color: Palette.secondary.withAlphaComponent(size >= 128 ? 0.14 : 0.1), width: max(CGFloat(size) * 0.007, 1))
    }

    let symbolRect = outerRect.insetBy(dx: outerRect.width * 0.22, dy: outerRect.height * 0.19)
    let rPath = NSBezierPath()
    rPath.move(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.14, y: symbolRect.minY + symbolRect.height * 0.12))
    rPath.line(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.14, y: symbolRect.minY + symbolRect.height * 0.86))
    rPath.line(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.54, y: symbolRect.minY + symbolRect.height * 0.86))
    rPath.line(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.54, y: symbolRect.minY + symbolRect.height * 0.54))
    rPath.line(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.14, y: symbolRect.minY + symbolRect.height * 0.54))
    rPath.move(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.14, y: symbolRect.minY + symbolRect.height * 0.54))
    rPath.line(to: CGPoint(x: symbolRect.minX + symbolRect.width * 0.62, y: symbolRect.minY + symbolRect.height * 0.12))
    rPath.lineCapStyle = .round
    rPath.lineJoinStyle = .round
    let symbolWidth = max(symbolRect.width * 0.12, 2)
    stroke(rPath, color: Palette.primary.withAlphaComponent(0.22), width: symbolWidth * 1.75)
    stroke(rPath, color: Palette.primary, width: symbolWidth)

    let playheadX = symbolRect.minX + symbolRect.width * 0.77
    let playheadPath = NSBezierPath()
    playheadPath.move(to: CGPoint(x: playheadX, y: symbolRect.minY + symbolRect.height * 0.1))
    playheadPath.line(to: CGPoint(x: playheadX, y: symbolRect.minY + symbolRect.height * 0.88))
    playheadPath.lineCapStyle = .round
    stroke(playheadPath, color: Palette.accent.withAlphaComponent(0.18), width: symbolWidth * 1.55)
    stroke(playheadPath, color: Palette.accent, width: max(symbolWidth * 0.36, 1.5))

    if size >= 128 {
        let noteSize = symbolRect.width * 0.095
        let upperNote = CGRect(
            x: playheadX - noteSize * 1.65,
            y: laneRect.minY + laneRect.height * 0.58 - noteSize / 2,
            width: noteSize,
            height: noteSize
        )
        let lowerNote = CGRect(
            x: playheadX - noteSize * 0.58,
            y: laneRect.minY + laneRect.height * 0.40 - noteSize / 2,
            width: noteSize,
            height: noteSize
        )
        fill(roundedRect(upperNote, radius: noteSize * 0.28), color: Palette.primary.withAlphaComponent(0.94))
        fill(roundedRect(lowerNote, radius: noteSize * 0.28), color: Palette.accent.withAlphaComponent(0.96))
    }

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw IconGenerationError.pngEncodingFailed
    }
    try pngData.write(to: url)
}

let rootPath = CommandLine.arguments.dropFirst().first ?? FileManager.default.currentDirectoryPath
let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
let resourcesURL = rootURL.appendingPathComponent("RhythmReplica/Resources", isDirectory: true)
let assetCatalogURL = resourcesURL.appendingPathComponent("Assets.xcassets", isDirectory: true)
let appIconSetURL = assetCatalogURL.appendingPathComponent("AppIcon.appiconset", isDirectory: true)
let temporaryIconsetURL = rootURL.appendingPathComponent("build/AppIcon.iconset", isDirectory: true)
let icnsURL = resourcesURL.appendingPathComponent("AppIcon.icns")

try FileManager.default.createDirectory(at: assetCatalogURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: appIconSetURL, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: temporaryIconsetURL, withIntermediateDirectories: true)

let assetCatalogContents: [String: Any] = [
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

let appIconContents: [String: Any] = [
    "images": slots.map { slot in
        [
            "filename": slot.filename,
            "idiom": "mac",
            "scale": "\(slot.scale)x",
            "size": "\(slot.pointSize)x\(slot.pointSize)"
        ]
    },
    "info": [
        "author": "xcode",
        "version": 1
    ]
]

try writeJSON(assetCatalogContents, to: assetCatalogURL.appendingPathComponent("Contents.json"))
try writeJSON(appIconContents, to: appIconSetURL.appendingPathComponent("Contents.json"))

for slot in slots {
    let image = try drawIcon(size: slot.pixelSize)
    let appIconDestination = appIconSetURL.appendingPathComponent(slot.filename)
    let iconsetDestination = temporaryIconsetURL.appendingPathComponent(slot.filename)
    try writePNG(image, to: appIconDestination)
    try writePNG(image, to: iconsetDestination)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["--convert", "icns", "--output", icnsURL.path, temporaryIconsetURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw IconGenerationError.iconutilFailed(code: process.terminationStatus)
}

try? FileManager.default.removeItem(at: temporaryIconsetURL)

print("Generated AppIcon assets at \(appIconSetURL.path)")
print("Generated fallback icns at \(icnsURL.path)")
