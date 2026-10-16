import Flutter
import UIKit

public class FlutterKeyboardVisibilityTempForkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    private var isVisible: Bool = false
    private var isFloating: Bool = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let eventChannel = FlutterEventChannel(name: "flutter_keyboard_visibility", binaryMessenger: registrar.messenger())
        let instance = FlutterKeyboardVisibilityTempForkPlugin()
        eventChannel.setStreamHandler(instance)
    }
    
    override init() {
        super.init()
        
        // Set up the notification observers
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(didShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        center.addObserver(self, selector: #selector(willShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: #selector(didHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: #selector(didChangeFrame(_:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func didShow(_ notification: Notification) {
        showIfOnScreen(notification)
    }

    @objc private func willShow(_ notification: Notification) {
        showIfOnScreen(notification)
    }

    // A rotation can post will/didShow for a keyboard that isn't on screen
    // (seen on a foldable's inner display: a zero-height frame at the bottom
    // edge). No hide follows for a keyboard that never appeared, so trusting
    // the show leaves `isVisible` stuck true.
    private func showIfOnScreen(_ notification: Notification) {
        if let frame = endFrame(notification), !isOnScreen(frame, notification) {
            if !isFloating { didHide() }
            return
        }
        show()
    }

    private func show() {
        guard !isVisible else { return }
        isVisible = true
        if let sink = eventSink {
            sink(1) // Notify the keyboard is visible
        }
    }

    @objc private func didHide() {
        guard isVisible else { return }
        isVisible = false
        if let sink = eventSink {
            sink(0) // Notify the keyboard is hidden
        }
    }
    
    @objc private func didChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = endFrame(notification) else { return }
        let screenBounds = screenBounds(notification)

        if keyboardFrame.width > 0 &&
            keyboardFrame.width < screenBounds.width &&
            isOnScreen(keyboardFrame, notification) {
            isFloating = true
            show()
        } else if isFloating {
            isFloating = false
            didHide()
        }
    }

    private func endFrame(_ notification: Notification) -> CGRect? {
        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
    }

    // Keyboard notifications carry the UIScreen their frames are in (iOS
    // 16.1+). `UIScreen.main` is the wrong one on a device with two displays:
    // on a foldable it is the cover screen even while the app is on the inner
    // one.
    private func screenBounds(_ notification: Notification) -> CGRect {
        (notification.object as? UIScreen)?.bounds ?? UIScreen.main.bounds
    }

    private func isOnScreen(_ frame: CGRect, _ notification: Notification) -> Bool {
        let visible = frame.intersection(screenBounds(notification))
        return !visible.isNull && visible.height > 0
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Notify the current keyboard visibility state
        if isVisible, let eventSink = self.eventSink {
            eventSink(1)
        }
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
