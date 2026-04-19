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

// --- Drag arrow: subtle Apple-Blue chevron between icon drop targets -------
// Post-process step positions Pluck.app at (220, 270) and Applications at
// (440, 270). Draw a thin arrow centered between them at matching y.
let arrowColor = NSColor(srgbRed: 0x00/255.0, green: 0x71/255.0, blue: 0xe3/255.0, alpha: 0.62)
arrowColor.setStroke()

let arrowPath = NSBezierPath()
// Arrow sits between (220, 270) and (440, 270) in the post-processed
// bottom-left origin coordinate system. Our canvas is bottom-left too.
let iconBaselineY: CGFloat = logicalSize.height - 270   // top-down → bottom-up flip
let leftX: CGFloat = 220 + 48    // right edge of left icon (iconSize 96)
let rightX: CGFloat = 440 - 48   // left edge of right icon
let midY: CGFloat = iconBaselineY
let shaftLength: CGFloat = rightX - leftX - 24

arrowPath.lineWidth = 1.5
arrowPath.lineCapStyle = .round
arrowPath.move(to: CGPoint(x: leftX + 12, y: midY))
arrowPath.line(to: CGPoint(x: leftX + 12 + shaftLength, y: midY))
// Chevron head
arrowPath.move(to: CGPoint(x: leftX + 12 + shaftLength - 8, y: midY + 6))
arrowPath.line(to: CGPoint(x: leftX + 12 + shaftLength, y: midY))
arrowPath.line(to: CGPoint(x: leftX + 12 + shaftLength - 8, y: midY - 6))
arrowPath.stroke()

NSGraphicsContext.restoreGraphicsState()

// --- Write PNG ---------------------------------------------------------------
guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(2)
}
try png.write(to: outURL)
print("wrote \(outURL.path) (\(Int(pixelSize.width))×\(Int(pixelSize.height)))")
