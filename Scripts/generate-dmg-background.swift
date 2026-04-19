#!/usr/bin/env swift
//
// generate-dmg-background.swift — renders the Pluck DMG window background.
//
// Output: 1320×800 PNG (660×400 logical @2x retina). The `sips` step in
// release.sh then injects 144 DPI metadata so Finder renders at retina.
// Palette and typography pulled from DESIGN.md (Apple tokens).
//
// Usage: swift generate-dmg-background.swift <output.png>

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: generate-dmg-background.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])

// 660×400 @2x = 1320×800 raw pixels.
let logicalSize = CGSize(width: 660, height: 400)
let scale: CGFloat = 2
let pixelSize = CGSize(width: logicalSize.width * scale, height: logicalSize.height * scale)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(pixelSize.width),
    pixelsHigh: Int(pixelSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
rep.size = logicalSize

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// --- Background: Apple Light Gray (#f5f5f7) --------------------------------
NSColor(srgbRed: 0xf5/255.0, green: 0xf5/255.0, blue: 0xf7/255.0, alpha: 1).setFill()
NSRect(origin: .zero, size: logicalSize).fill()

// --- Wordmark: "Pluck" centered, SF 40pt semibold, Near Black ---------------
let nearBlack = NSColor(srgbRed: 0x1d/255.0, green: 0x1d/255.0, blue: 0x1f/255.0, alpha: 1)

let wordmarkFont = NSFont.systemFont(ofSize: 40, weight: .semibold)
let wordmarkAttrs: [NSAttributedString.Key: Any] = [
    .font: wordmarkFont,
    .foregroundColor: nearBlack,
    .kern: -0.28,
]
let wordmark = NSAttributedString(string: "Pluck", attributes: wordmarkAttrs)
let wordmarkSize = wordmark.size()
wordmark.draw(at: CGPoint(
    x: (logicalSize.width - wordmarkSize.width) / 2,
    y: logicalSize.height - wordmarkSize.height - 46
))

// --- Tagline: one line, 15pt regular, secondary --------------------------
let taglineFont = NSFont.systemFont(ofSize: 15, weight: .regular)
let tagline = NSAttributedString(
    string: "Hold a click on selected text, anywhere.",
    attributes: [
        .font: taglineFont,
        .foregroundColor: nearBlack.withAlphaComponent(0.64),
        .kern: -0.24,
    ]
)
let tagSize = tagline.size()
tagline.draw(at: CGPoint(
    x: (logicalSize.width - tagSize.width) / 2,
    y: logicalSize.height - wordmarkSize.height - 46 - tagSize.height - 10
))

// --- Drag arrow: tri-color gradient pulled from the app icon ----------------
// Colors eyedropped from the scissors tile:
//   red handle   #d8443b
//   yellow handle #e6b93b
//   blue handle  #2c61af
// The arrow sits between the drop targets (Pluck.app at (220, 270) and
// Applications at (440, 270) post-process) and flows red → yellow → blue
// left-to-right so the last beat lands on the Applications target.
let red    = NSColor(srgbRed: 0xd8/255.0, green: 0x44/255.0, blue: 0x3b/255.0, alpha: 0.95)
let yellow = NSColor(srgbRed: 0xe6/255.0, green: 0xb9/255.0, blue: 0x3b/255.0, alpha: 0.95)
let blue   = NSColor(srgbRed: 0x2c/255.0, green: 0x61/255.0, blue: 0xaf/255.0, alpha: 0.95)

let iconBaselineY: CGFloat = logicalSize.height - 270
let leftX: CGFloat = 220 + 48     // right edge of left icon (iconSize 96)
let rightX: CGFloat = 440 - 48    // left edge of right icon
let midY: CGFloat = iconBaselineY
let shaftStartX: CGFloat = leftX + 12
let shaftEndX:   CGFloat = rightX - 12

// Build the arrow path: shaft + chevron head.
let arrowPath = NSBezierPath()
arrowPath.lineWidth = 2.2
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.move(to: CGPoint(x: shaftStartX, y: midY))
arrowPath.line(to: CGPoint(x: shaftEndX, y: midY))
arrowPath.move(to: CGPoint(x: shaftEndX - 9, y: midY + 7))
arrowPath.line(to: CGPoint(x: shaftEndX, y: midY))
arrowPath.line(to: CGPoint(x: shaftEndX - 9, y: midY - 7))

// Clip to the stroked arrow path, then fill the clipped region with a
// horizontal red→yellow→blue gradient. Smooth color flow across the
// whole arrow — shaft AND chevron head.
if let cg = NSGraphicsContext.current?.cgContext,
   let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [red.cgColor, yellow.cgColor, blue.cgColor] as CFArray,
        locations: [0.0, 0.5, 1.0]) {
    let stroked = arrowPath.cgPath.copy(
        strokingWithWidth: arrowPath.lineWidth,
        lineCap: .round,
        lineJoin: .round,
        miterLimit: 10
    )
    cg.saveGState()
    cg.addPath(stroked)
    cg.clip()
    cg.drawLinearGradient(
        gradient,
        start: CGPoint(x: shaftStartX, y: midY),
        end:   CGPoint(x: shaftEndX,   y: midY),
        options: []
    )
    cg.restoreGState()
} else {
    blue.setStroke()
    arrowPath.stroke()
}

NSGraphicsContext.restoreGraphicsState()

// --- Write PNG ---------------------------------------------------------------
guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(2)
}
try png.write(to: outURL)
print("wrote \(outURL.path) (\(Int(pixelSize.width))×\(Int(pixelSize.height)))")
