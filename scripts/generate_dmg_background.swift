#!/usr/bin/env swift

import Cocoa
import CoreGraphics

// Configuration
let width = 660
let height = 400
let scale: CGFloat = 2.0 // Retina support
let outputPath = "scripts/dmg-resources/dmg-background.png"

// Create context
let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
let context = CGContext(
    data: nil,
    width: Int(CGFloat(width) * scale),
    height: Int(CGFloat(height) * scale),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo.rawValue
)!

// Scale for Retina
context.scaleBy(x: scale, y: scale)

// 1. Fill Background
// Using a slightly off-white standard macOS window color
let backgroundColor = NSColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
context.setFillColor(backgroundColor.cgColor)
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

// 2. Draw "Install SaneClip" Text
let title = "SaneClip" as NSString
let subTitle = "Drag to Applications to install" as NSString

let titleFont = NSFont.systemFont(ofSize: 36, weight: .bold)
let subTitleFont = NSFont.systemFont(ofSize: 14, weight: .medium)
let textColor = NSColor(white: 0.2, alpha: 1.0)

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: textColor
]
let subTitleAttributes: [NSAttributedString.Key: Any] = [
    .font: subTitleFont,
    .foregroundColor: NSColor(white: 0.5, alpha: 1.0)
]

let titleSize = title.size(withAttributes: titleAttributes)
let subTitleSize = subTitle.size(withAttributes: subTitleAttributes)

// Draw Title centered horizontally, near top
let titleRect = CGRect(
    x: (CGFloat(width) - titleSize.width) / 2.0,
    y: CGFloat(height) - 80, // Top area
    width: titleSize.width,
    height: titleSize.height
)
title.draw(in: titleRect, withAttributes: titleAttributes)

// Draw Subtitle below title
let subTitleRect = CGRect(
    x: (CGFloat(width) - subTitleSize.width) / 2.0,
    y: CGFloat(height) - 110,
    width: subTitleSize.width,
    height: subTitleSize.height
)
subTitle.draw(in: subTitleRect, withAttributes: subTitleAttributes)

// 3. Draw Arrow
// Positions from release.sh: App (160, 220), Link (500, 220)
// Warning: CoreGraphics Y is 0 at bottom, but release.sh (create-dmg) uses Y=0 at top.
// If window height is 400:
// App Y (from top) = 220  -> Y (from bottom) = 400 - 220 = 180
// Link Y (from top) = 220 -> Y (from bottom) = 400 - 220 = 180

let startX: CGFloat = 210 // Start after App Icon
let endX: CGFloat = 450   // End before App Drop Link
let yPos: CGFloat = 180

let arrowPath = CGMutablePath()
arrowPath.move(to: CGPoint(x: startX, y: yPos))
arrowPath.addLine(to: CGPoint(x: endX, y: yPos))

// Arrow head
let arrowHeadSize: CGFloat = 10
arrowPath.move(to: CGPoint(x: endX - arrowHeadSize, y: yPos + arrowHeadSize/2))
arrowPath.addLine(to: CGPoint(x: endX, y: yPos))
arrowPath.addLine(to: CGPoint(x: endX - arrowHeadSize, y: yPos - arrowHeadSize/2))

context.addPath(arrowPath)
context.setStrokeColor(NSColor(white: 0.7, alpha: 1.0).cgColor)
context.setLineWidth(2.0)
context.setLineCap(.round)
context.setLineJoin(.round)
context.strokePath()

// 4. Save Image
guard let image = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let destURL = URL(fileURLWithPath: outputPath)
let destination = CGImageDestinationCreateWithURL(destURL as CFURL, kUTTypePNG, 1, nil)!
CGImageDestinationAddImage(destination, image, nil)
if CGImageDestinationFinalize(destination) {
    print("Generated DMG background at \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}
