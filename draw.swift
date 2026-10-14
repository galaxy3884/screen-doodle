import Cocoa
import Carbon

struct Stroke { var points: [NSPoint]; var color: NSColor; var width: CGFloat }

var penColor = NSColor.systemRed
var penWidth: CGFloat = 4
var history: [CanvasView] = []
var appDelegate: AppDelegate!

final class CanvasView: NSView {
    var strokes: [Stroke] = []
    var current: Stroke?

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }

    override func draw(_ dirtyRect: NSRect) {
        for s in strokes + (current.map { [$0] } ?? []) {
            let p = NSBezierPath()
            p.lineWidth = s.width
            p.lineCapStyle = .round
            p.lineJoinStyle = .round
            p.move(to: s.points[0])
            for pt in s.points.dropFirst() { p.line(to: pt) }
            if s.points.count == 1 { p.line(to: s.points[0]) }
            s.color.setStroke()
            p.stroke()
        }
    }

    override func mouseDown(with e: NSEvent) {
        current = Stroke(points: [convert(e.locationInWindow, from: nil)], color: penColor, width: penWidth)
        needsDisplay = true
    }
    override func mouseDragged(with e: NSEvent) {
        current?.points.append(convert(e.locationInWindow, from: nil))
        needsDisplay = true
    }
    override func mouseUp(with e: NSEvent) {
        if let s = current { strokes.append(s); history.append(self) }
        current = nil
        needsDisplay = true
    }
}

final class DrawWindow: NSWindow {
    override var canBecomeKey: Bool { true }

    override func keyDown(with e: NSEvent) {
        let ch = e.charactersIgnoringModifiers ?? ""
        let colors: [String: NSColor] = [
            "1": .systemRed, "2": .systemYellow, "3": .systemGreen,
            "4": .systemBlue, "5": .white, "6": .black,
        ]
        if let c = colors[ch] { penColor = c; return }
        switch ch {
        case "[": penWidth = max(1, penWidth - 1)
        case "]": penWidth = min(40, penWidth + 1)
        case "z": appDelegate.undo()
        case "c": appDelegate.clear()
        case "\u{1B}", "d": appDelegate.toggle()
        default: super.keyDown(with: e)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [DrawWindow] = []
    var views: [CanvasView] = []
    var drawing = false
    var item: NSStatusItem!

    func applicationDidFinishLaunching(_ n: Notification) {
        for screen in NSScreen.screens {
            let w = DrawWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.setFrame(screen.frame, display: false)
            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = false
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            w.ignoresMouseEvents = true
            w.isReleasedWhenClosed = false
            let v = CanvasView(frame: NSRect(origin: .zero, size: screen.frame.size))
            w.contentView = v
            w.orderFrontRegardless()
            windows.append(w); views.append(v)
        }

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "✎"
        let m = NSMenu()
        m.addItem(withTitle: "Малювати / зупинити (⌃⌥D)", action: #selector(toggle), keyEquivalent: "")
        m.addItem(withTitle: "Очистити (⌃⌥C)", action: #selector(clear), keyEquivalent: "")
        m.addItem(.separator())
        m.addItem(withTitle: "Вийти", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        m.items.forEach { if $0.action != #selector(NSApplication.terminate(_:)) { $0.target = self } }
        item.menu = m

        registerHotKeys()
    }

    @objc func toggle() {
        drawing.toggle()
        item.button?.title = drawing ? "✎●" : "✎"
        for w in windows { w.ignoresMouseEvents = !drawing }
        if drawing {
            NSApp.activate(ignoringOtherApps: true)
            windows.first?.makeKeyAndOrderFront(nil)
        }
        NSCursor.crosshair.set()
    }

    @objc func clear() {
        views.forEach { $0.strokes.removeAll(); $0.needsDisplay = true }
        history.removeAll()
    }

    func undo() {
        guard let v = history.popLast() else { return }
        _ = v.strokes.popLast()
        v.needsDisplay = true
    }

    func registerHotKeys() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, ev, _ in
            var hk = EventHotKeyID()
            GetEventParameter(ev, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            DispatchQueue.main.async { hk.id == 1 ? appDelegate.toggle() : appDelegate.clear() }
            return noErr
        }, 1, &spec, nil, nil)
        let mods = UInt32(controlKey | optionKey)
        for (id, key) in [(UInt32(1), kVK_ANSI_D), (UInt32(2), kVK_ANSI_C)] {
            var ref: EventHotKeyRef?
            RegisterEventHotKey(UInt32(key), mods, EventHotKeyID(signature: 0x44524157, id: id),
                                GetApplicationEventTarget(), 0, &ref)
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
