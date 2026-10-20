## [0.1.6] - February 20, 2025

- Fixes WASM compilation issue when using [`flutter_keyboard_visibility`](https://pub.dev/packages/flutter_keyboard_visibility) with this package by removing the deprecated class `FlutterKeyboardVisibilityPluginWeb` which is not expected to be used by clients.
- [iOS] ignore show notifications for an off-screen keyboard.

## [0.1.5] - December 2, 2024

- Updates the threshold for detecting the keyboard state from 85% to 82% of the visible screen height. This improves accuracy in determining whether the keyboard is visible [#5](https://github.com/EchoEllet/flutter_keyboard_visibility_temp_fork/pull/5/).

## [0.1.4] - November 24, 2024

* Supports Swift package manager.
* Migrates the iOS plugin from Objective-C to Swift.
* Updates the minimum supported iOS from `8.0` to `9.0`.

## [0.1.3] - November 7, 2024

* Promoted 0.1.3-alpha to stable.

## [0.1.3-alpha] - November 6, 2024

* Adds iOS notification observer for the floating keyboard (see [PR #2](https://github.com/EchoEllet/flutter_keyboard_visibility_temp_fork/pull/2)).
* Adds keyboard debounce check (see [PR #2](https://github.com/EchoEllet/flutter_keyboard_visibility_temp_fork/pull/2)).

## [0.1.2-alpha] - November 5, 2024

* Fixes plugin class name collisions with [flutter_keyboard_visibility](https://pub.dev/packages/flutter_keyboard_visibility) for Web, Android, and iOS. Which updates the platform plugin name to `FlutterKeyboardVisibilityTempForkPlugin`. The desktop platforms don't have issues.
* Updates the [web](https://pub.dev/packages/web) dependency constraints to `>=0.5.1 <2.0.0`.

## [0.1.1] - September 27, 2024

* Updates `README.md` to reflect the changes.

## [0.1.0] - September 27, 2024

* Initial release for the temporary fork of [flutter_keyboard_visibility](https://pub.dev/packages/flutter_keyboard_visibility).
