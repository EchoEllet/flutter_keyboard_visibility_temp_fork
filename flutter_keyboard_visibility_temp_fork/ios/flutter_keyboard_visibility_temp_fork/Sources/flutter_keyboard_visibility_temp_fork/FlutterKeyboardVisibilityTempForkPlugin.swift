import Flutter
import UIKit

public class FlutterKeyboardVisibilityTempForkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    private var isVisible: Bool = false
    // Whether the keyboard notifications say a docked keyboard is shown.
    private var isDockedVisible: Bool = false
    // Whether the keyboard layout guide says a floating keyboard is on screen.
    private var isFloating: Bool = false
    // Whether a keyboard frame change has since said the keyboard is gone,
    // which the guide doesn't always show; see didChangeFrame.
    private var isGoneByFrame: Bool = false

    // A transparent view filling the window, whose keyboard layout guide
    // follows an undocked keyboard, and the probe pinned to that guide.
    private var guideHost: UIView?
    private var guideProbe: KeyboardGuideProbe?
    
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
        // The app can move to another window, e.g. a new scene's.
        center.addObserver(self, selector: #selector(attachKeyboardGuide), name: UIWindow.didBecomeKeyNotification, object: nil)
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
            isDockedVisible = false
        } else {
            isDockedVisible = true
        }
        updateVisibility()
    }

    @objc private func didHide() {
        isDockedVisible = false
        updateVisibility()
    }

    private func updateVisibility() {
        let visible = isDockedVisible || (isFloating && !isGoneByFrame)
        guard visible != isVisible else { return }
        isVisible = visible
        if let sink = eventSink {
            sink(visible ? 1 : 0)
        }
    }

    // Dismissing a floating keyboard on iOS 18 leaves the keyboard layout
    // guide where the keyboard was; only this notification, with an all-zero
    // end frame, says it has gone.
    @objc private func didChangeFrame(_ notification: Notification) {
        isGoneByFrame = endFrame(notification) == .zero
        keyboardGuideDidChange()
    }

    // An iPad's floating keyboard posts no show notification when a text field
    // brings it up, and turning a docked keyboard into a floating one posts a
    // hide. A keyboard layout guide that follows an undocked keyboard does
    // track it, so watch one (see keyboardGuideDidChange). Before iOS 15 there
    // is no such guide, and only docked keyboards are reported.
    @objc private func attachKeyboardGuide() {
        guard #available(iOS 15.0, *) else { return }
        guard let window = keyWindow(), guideHost?.window !== window else { return }
        guideHost?.removeFromSuperview()

        let host = UIView()
        host.isUserInteractionEnabled = false
        host.alpha = 0
        host.translatesAutoresizingMaskIntoConstraints = false
        host.keyboardLayoutGuide.followsUndockedKeyboard = true

        let probe = KeyboardGuideProbe()
        probe.translatesAutoresizingMaskIntoConstraints = false
        probe.onResize = { [weak self] in self?.keyboardGuideDidChange() }

        window.addSubview(host)
        host.addSubview(probe)
        let guide = host.keyboardLayoutGuide
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: window.topAnchor),
            host.bottomAnchor.constraint(equalTo: window.bottomAnchor),
            host.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            probe.topAnchor.constraint(equalTo: guide.topAnchor),
            probe.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            probe.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            probe.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
        ])
        guideHost = host
        guideProbe = probe
    }

    @available(iOS 15.0, *)
    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }

    private func keyboardGuideDidChange() {
        guard let frame = guideProbe?.frame, let host = guideHost?.bounds.size else {
            return
        }
        // A docked keyboard, and no keyboard (the guide then covers the bottom
        // safe area), reach the bottom edge at full width. A floating keyboard
        // doesn't: the guide takes its frame, or -- on some iOS versions, when
        // a text field brings one up -- its height and position at the
        // window's width. Dismissing one can leave the guide a sliver a few
        // points tall where it was, and iOS 27 shrinks it to a small box in
        // the corner, hence the minimum height.
        let atBottom = frame.maxY >= host.height - 1
        let fullWidth = frame.width >= host.width - 1
        isFloating = frame.height >= 100 && (!atBottom || !fullWidth)
        updateVisibility()
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
        attachKeyboardGuide()
        
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

// Calls onResize whenever its size changes. Pinned to a keyboard layout guide,
// it reports the keyboard's frame as the guide tracks it.
private class KeyboardGuideProbe: UIView {
    var onResize: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onResize?()
    }
}
