import Cocoa

let S: CGFloat = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(S), pixelsHigh: Int(S), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Плитка в стилі macOS з полями по краях
let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)
NSGradient(colors: [NSColor(red: 0.13, green: 0.16, blue: 0.34, alpha: 1),
                    NSColor(red: 0.05, green: 0.06, blue: 0.16, alpha: 1)])!.draw(in: shape, angle: -90)

// Червоний розмашистий штрих
func stroke(_ color: NSColor, _ width: CGFloat, dx: CGFloat = 0, dy: CGFloat = 0) {
    let p = NSBezierPath()
    p.lineWidth = width
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    p.move(to: NSPoint(x: 245 + dx, y: 330 + dy))
    p.curve(to: NSPoint(x: 520 + dx, y: 560 + dy),
            controlPoint1: NSPoint(x: 330 + dx, y: 720 + dy), controlPoint2: NSPoint(x: 420 + dx, y: 330 + dy))
    p.curve(to: NSPoint(x: 790 + dx, y: 690 + dy),
            controlPoint1: NSPoint(x: 620 + dx, y: 780 + dy), controlPoint2: NSPoint(x: 700 + dx, y: 560 + dy))
    color.setStroke()
    p.stroke()
}
NSGraphicsContext.current?.saveGraphicsState()
let glow = NSShadow()
glow.shadowColor = NSColor(red: 1, green: 0.2, blue: 0.25, alpha: 0.75)
glow.shadowBlurRadius = 50
glow.shadowOffset = .zero
glow.set()
stroke(NSColor(red: 1.0, green: 0.27, blue: 0.30, alpha: 1), 74)
NSGraphicsContext.current?.restoreGraphicsState()
stroke(NSColor(red: 1.0, green: 0.62, blue: 0.60, alpha: 0.85), 20, dx: -4, dy: 10)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "icon_1024.png"))
