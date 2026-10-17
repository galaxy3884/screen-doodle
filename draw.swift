import Cocoa
import Carbon

enum Tool { case pen, text, arrow, rect, ellipse, block }
struct Stroke { var points: [NSPoint]; var color: NSColor; var width: CGFloat; var kind: Tool = .pen; var text = "" }

var penColor = NSColor.systemRed
var penWidth: CGFloat = 4
var tool: Tool = .pen
var history: [CanvasView] = []
var appDelegate: AppDelegate!

final class CanvasView: NSView, NSTextFieldDelegate {
    var strokes: [Stroke] = []
    var current: Stroke?
    var field: NSTextField?

    override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
    // The app never becomes active, so without this the first click on the canvas can be swallowed.
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        for s in strokes + (current.map { [$0] } ?? []) { draw(s) }
    }

    private func draw(_ s: Stroke) {
        let a = s.points[0], b = s.points[s.points.count - 1]
        let r = NSRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
        switch s.kind {
        case .text:
            (s.text as NSString).draw(at: a, withAttributes: [.font: NSFont.systemFont(ofSize: s.width * 6), .foregroundColor: s.color])
        case .block:
            s.color.withAlphaComponent(0.35).setFill()
            NSBezierPath(rect: r).fill()
        default:
            let p = NSBezierPath()
            p.lineWidth = s.width
            p.lineCapStyle = .round
            p.lineJoinStyle = .round
            switch s.kind {
            case .rect: p.appendRect(r)
            case .ellipse: p.appendOval(in: r)
            case .arrow:
                p.move(to: a); p.line(to: b)
                let angle = atan2(b.y - a.y, b.x - a.x), len = s.width * 4 + 12
                for d in [CGFloat.pi * 0.85, -CGFloat.pi * 0.85] {
                    p.move(to: b); p.line(to: NSPoint(x: b.x + len * cos(angle + d), y: b.y + len * sin(angle + d)))
                }
            default:
                p.move(to: a)
                for pt in s.points.dropFirst() { p.line(to: pt) }
                if s.points.count == 1 { p.line(to: a) }
            }
            s.color.setStroke()
            p.stroke()
        }
    }

    override func mouseDown(with e: NSEvent) {
        commitText()
        let p = convert(e.locationInWindow, from: nil)
        if tool == .text {
            let f = NSTextField(frame: NSRect(x: p.x, y: p.y, width: 300, height: penWidth * 6 + 8))
            f.font = NSFont.systemFont(ofSize: penWidth * 6)
            f.textColor = penColor
            f.isBordered = false; f.drawsBackground = false; f.focusRingType = .none
            f.delegate = self
            addSubview(f); field = f
            window?.makeKeyAndOrderFront(nil)
            window?.makeFirstResponder(f)
            return
        }
        current = Stroke(points: [p, p], color: penColor, width: penWidth, kind: tool)
        needsDisplay = true
    }
    override func mouseDragged(with e: NSEvent) {
        guard var s = current else { return }
        let p = convert(e.locationInWindow, from: nil)
        if s.kind == .pen { s.points.append(p) } else { s.points[1] = p }
        current = s
        needsDisplay = true
    }
    override func mouseUp(with e: NSEvent) {
        if let s = current, s.kind == .pen || s.points[0] != s.points[1] { strokes.append(s); history.append(self) }
        current = nil
        needsDisplay = true
    }

    // Enter, Esc, or clicking elsewhere finishes the text field and turns it into a stroke.
    func commitText() {
        guard let f = field else { return }
        field = nil
        if !f.stringValue.isEmpty {
            strokes.append(Stroke(points: [f.frame.origin], color: f.textColor ?? penColor, width: penWidth, kind: .text, text: f.stringValue))
            history.append(self)
        }
        f.removeFromSuperview()
        needsDisplay = true
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard selector == #selector(NSResponder.insertNewline(_:)) || selector == #selector(NSResponder.cancelOperation(_:)) else { return false }
        commitText()
        return true
    }
    func controlTextDidEndEditing(_ obj: Notification) { commitText() }
}

// A nonactivating panel can be the key window (keys, text input) without the accessory app ever becoming active.
final class DrawWindow: NSPanel {
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
    var panel: NSPanel!

    func applicationDidFinishLaunching(_ n: Notification) {
        buildWindows()
        buildPanel()
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.buildWindows() }

        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "✎"
        let m = NSMenu()
        m.addItem(withTitle: "Toggle Drawing (⌃⌥D)", action: #selector(toggle), keyEquivalent: "")
        m.addItem(withTitle: "Clear (⌃⌥C)", action: #selector(clear), keyEquivalent: "")
        m.addItem(.separator())
        m.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        m.items.forEach { if $0.action != #selector(NSApplication.terminate(_:)) { $0.target = self } }
        item.menu = m

        registerHotKeys()
    }

    // Rebuilds one overlay window per screen; strokes are dropped because their views are replaced.
    func buildWindows() {
        windows.forEach { $0.close() }
        windows.removeAll(); views.removeAll(); history.removeAll()
        for screen in NSScreen.screens {
            let w = DrawWindow(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            w.setFrame(screen.frame, display: false)
            w.isOpaque = false
            w.backgroundColor = .clear
            w.hasShadow = false
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            w.ignoresMouseEvents = !drawing
            w.hidesOnDeactivate = false
            w.isReleasedWhenClosed = false
            let v = CanvasView(frame: NSRect(origin: .zero, size: screen.frame.size))
            w.contentView = v
            w.orderFrontRegardless()
            windows.append(w); views.append(v)
        }
    }

    // Floating toolbar shown while drawing; nonactivating so keys still go to the canvas.
    func buildPanel() {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        for (i, title) in ["Олівець", "Текст", "Стрілка"].enumerated() {
            let b = NSButton(title: title, target: self, action: #selector(pickTool(_:)))
            b.tag = i
            stack.addArrangedSubview(b)
        }
        let obj = NSPopUpButton(frame: .zero, pullsDown: true)
        obj.addItems(withTitles: ["Об'єкт", "Прямокутник", "Коло", "Блок"])
        obj.target = self; obj.action = #selector(pickObject(_:))
        stack.addArrangedSubview(obj)
        stack.addArrangedSubview(NSButton(title: "Колір", target: self, action: #selector(showColors)))
        for (title, sel) in [("Скасувати", #selector(undo)), ("Очистити", #selector(clear)), ("Вийти", #selector(toggle))] {
            stack.addArrangedSubview(NSButton(title: title, target: self, action: sel))
        }
        stack.wantsLayer = true
        stack.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        stack.layer?.cornerRadius = 10
        let size = stack.fittingSize
        stack.frame = NSRect(origin: .zero, size: size)
        panel = NSPanel(contentRect: stack.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.contentView = stack
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        // One level above the overlays, otherwise a click on the canvas raises the overlay over the panel.
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        panel.hasShadow = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        let screen = NSScreen.main?.frame ?? .zero
        panel.setFrameOrigin(NSPoint(x: screen.midX - size.width / 2, y: screen.minY + 60))
    }

    @objc func pickTool(_ sender: NSButton) { setTool([.pen, .text, .arrow][sender.tag]) }
    @objc func pickObject(_ sender: NSPopUpButton) { setTool([.rect, .ellipse, .block][max(sender.indexOfSelectedItem, 1) - 1]) }
    @objc func colorChanged(_ sender: NSColorPanel) { penColor = sender.color }

    @objc func showColors() {
        let p = NSColorPanel.shared
        p.color = penColor
        p.setTarget(self); p.setAction(#selector(colorChanged(_:)))
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.orderFront(nil)
        // orderFront resets the level, so set it after; it must sit above the overlays or its clicks land on the canvas.
        p.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
    }

    func setTool(_ t: Tool) {
        views.forEach { $0.commitText() }
        tool = t
    }

    @objc func toggle() {
        drawing.toggle()
        item.button?.title = drawing ? "✎●" : "✎"
        for w in windows { w.ignoresMouseEvents = !drawing }
        if drawing {
            NSApp.activate(ignoringOtherApps: true)
            windows.first?.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
        } else {
            views.forEach { $0.commitText() }
            panel.orderOut(nil)
            NSColorPanel.shared.orderOut(nil)
        }
        NSCursor.crosshair.set()
    }

    @objc func clear() {
        views.forEach { $0.commitText(); $0.strokes.removeAll(); $0.needsDisplay = true }
        history.removeAll()
    }

    @objc func undo() {
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
