#!/usr/bin/env swift

import AppKit
import Foundation

let fileManager = FileManager.default
let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let zombieRoot: URL
if fileManager.fileExists(atPath: currentDirectory.appendingPathComponent("Sources/ZombieApp").path) {
    zombieRoot = currentDirectory
} else {
    zombieRoot = currentDirectory.appendingPathComponent("zombie", isDirectory: true)
}

let appIconSet = zombieRoot
    .appendingPathComponent("Sources/ZombieApp/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let assetCatalog = appIconSet.deletingLastPathComponent()
let sourceURL = URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Provisional_Irish_Republican_Army_Badge.svg/3840px-Provisional_Irish_Republican_Army_Badge.svg.png")!

let sourceImageURL: URL
if let sourceIndex = CommandLine.arguments.firstIndex(of: "--source"),
   CommandLine.arguments.indices.contains(sourceIndex + 1) {
    sourceImageURL = URL(fileURLWithPath: CommandLine.arguments[sourceIndex + 1])
} else {
    let scratch = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        .appendingPathComponent("ZombieAppIconSource-\(UUID().uuidString).png")
    try Data(contentsOf: sourceURL).write(to: scratch, options: .atomic)
    sourceImageURL = scratch
}

let sourceImage = NSImage(contentsOf: sourceImageURL)
guard let sourceImage,
      let sourceCGImage = sourceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("Unable to read source icon image at \(sourceImageURL.path)\n", stderr)
    exit(1)
}

let crop = CGRect(x: 776, y: 689, width: 2288, height: 2288)
let innerBadgeCenter = CGPoint(x: 1920, y: 1920)
let innerBadgeRadius: CGFloat = 1300
guard let croppedCGImage = sourceCGImage.cropping(to: crop) else {
    fputs("Unable to crop source icon image\n", stderr)
    exit(1)
}

struct IconSlot {
    let idiom: String
    let size: String
    let scale: String
    let pixels: Int

    var filename: String {
        let safeSize = size.replacingOccurrences(of: ".", with: "_")
        return "Icon-\(idiom)-\(safeSize)@\(scale).png"
    }
}

let slots: [IconSlot] = [
    IconSlot(idiom: "iphone", size: "20x20", scale: "2x", pixels: 40),
    IconSlot(idiom: "iphone", size: "20x20", scale: "3x", pixels: 60),
    IconSlot(idiom: "iphone", size: "29x29", scale: "2x", pixels: 58),
    IconSlot(idiom: "iphone", size: "29x29", scale: "3x", pixels: 87),
    IconSlot(idiom: "iphone", size: "40x40", scale: "2x", pixels: 80),
    IconSlot(idiom: "iphone", size: "40x40", scale: "3x", pixels: 120),
    IconSlot(idiom: "iphone", size: "60x60", scale: "2x", pixels: 120),
    IconSlot(idiom: "iphone", size: "60x60", scale: "3x", pixels: 180),
    IconSlot(idiom: "ipad", size: "20x20", scale: "1x", pixels: 20),
    IconSlot(idiom: "ipad", size: "20x20", scale: "2x", pixels: 40),
    IconSlot(idiom: "ipad", size: "29x29", scale: "1x", pixels: 29),
    IconSlot(idiom: "ipad", size: "29x29", scale: "2x", pixels: 58),
    IconSlot(idiom: "ipad", size: "40x40", scale: "1x", pixels: 40),
    IconSlot(idiom: "ipad", size: "40x40", scale: "2x", pixels: 80),
    IconSlot(idiom: "ipad", size: "76x76", scale: "1x", pixels: 76),
    IconSlot(idiom: "ipad", size: "76x76", scale: "2x", pixels: 152),
    IconSlot(idiom: "ipad", size: "83.5x83.5", scale: "2x", pixels: 167),
    IconSlot(idiom: "ios-marketing", size: "1024x1024", scale: "1x", pixels: 1024),
    IconSlot(idiom: "mac", size: "16x16", scale: "1x", pixels: 16),
    IconSlot(idiom: "mac", size: "16x16", scale: "2x", pixels: 32),
    IconSlot(idiom: "mac", size: "32x32", scale: "1x", pixels: 32),
    IconSlot(idiom: "mac", size: "32x32", scale: "2x", pixels: 64),
    IconSlot(idiom: "mac", size: "128x128", scale: "1x", pixels: 128),
    IconSlot(idiom: "mac", size: "128x128", scale: "2x", pixels: 256),
    IconSlot(idiom: "mac", size: "256x256", scale: "1x", pixels: 256),
    IconSlot(idiom: "mac", size: "256x256", scale: "2x", pixels: 512),
    IconSlot(idiom: "mac", size: "512x512", scale: "1x", pixels: 512),
    IconSlot(idiom: "mac", size: "512x512", scale: "2x", pixels: 1024)
]

try fileManager.createDirectory(at: appIconSet, withIntermediateDirectories: true)
let catalogContents: [String: Any] = [
    "info": [
        "author": "xcode",
        "version": 1
    ]
]
try JSONSerialization.data(withJSONObject: catalogContents, options: [.prettyPrinted, .sortedKeys])
    .write(to: assetCatalog.appendingPathComponent("Contents.json"), options: .atomic)

for slot in slots {
    let image = makeIcon(size: slot.pixels, from: croppedCGImage)
    try writePNG(image, to: appIconSet.appendingPathComponent(slot.filename))
}

let contents: [String: Any] = [
    "images": slots.map { slot in
        [
            "filename": slot.filename,
            "idiom": slot.idiom,
            "scale": slot.scale,
            "size": slot.size
        ]
    },
    "info": [
        "author": "xcode",
        "version": 1
    ]
]
let contentsData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try contentsData.write(to: appIconSet.appendingPathComponent("Contents.json"), options: .atomic)

print("Generated \(appIconSet.path)")

func makeIcon(size: Int, from cgImage: CGImage) -> NSImage {
    let side = CGFloat(size)
    let image = NSImage(size: NSSize(width: side, height: side))
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: side, height: side)
    NSColor(calibratedRed: 0.93, green: 0.72, blue: 0.45, alpha: 1).setFill()
    rect.fill()

    let scale = side / CGFloat(cgImage.width)
    let clipCenter = NSPoint(
        x: (innerBadgeCenter.x - crop.minX) * scale,
        y: (innerBadgeCenter.y - crop.minY) * scale
    )
    let clipRadius = innerBadgeRadius * scale
    let clipRect = NSRect(
        x: clipCenter.x - clipRadius,
        y: clipCenter.y - clipRadius,
        width: clipRadius * 2,
        height: clipRadius * 2
    )

    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(ovalIn: clipRect).addClip()
    NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        .draw(in: rect,
              from: .zero,
              operation: .copy,
              fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "ZombieAppIcon", code: 1)
    }
    try data.write(to: url, options: .atomic)
}
