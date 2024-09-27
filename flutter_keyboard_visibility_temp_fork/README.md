# Flutter Keyboard Visibility Temp Fork

This is a temporary unofficial fork of [flutter_keyboard_visibility](https://pub.dev/packages/flutter_keyboard_visibility) as a response to some of the issues we had in [flutter_quill](https://pub.dev/packages/flutter_quill). See [#2290](https://github.com/singerdmx/flutter-quill/issues/2290) and [#1889](https://github.com/singerdmx/flutter-quill/issues/1889).

Will be maintained for a short while once we find a replacement, fix those issues, or develop your own solution in [quill_native_bridge](https://pub.dev/packages/quill_native_bridge).

We don't recommend using this package as a dependency in packages published to [pub.dev](https://pub.dev/) as it's very likely to be break after a short while, however, if you're developing an app, this might be a temporary replacement for you once those PRs reviewed in the upstream repo or find a replacement:

- [#164](https://github.com/MisterJimson/flutter_keyboard_visibility/pull/164)
- [#159](https://github.com/MisterJimson/flutter_keyboard_visibility/pull/159)
- [#155](https://github.com/MisterJimson/flutter_keyboard_visibility/pull/155)

We don't plan on introduce breaking changes unless there is a strong reason even if we will have less clean API. [flutter_keyboard_visibility_platform_interface](https://pub.dev/packages/flutter_keyboard_visibility_platform_interface) is still a dependency.

This fork aim to solve the following issues:

- Use the Flutter default `compileSdkVersion` as a workaround to a bug in Flutter [#63533](https://github.com/flutter/flutter/issues/63533). Allowing you to target the latest `compileSdkVersion`
- Support for [Flutter/WASM](https://docs.flutter.dev/platform-integration/web/wasm). Currently using `dart:html` or `package:js` will prevent from compiling the app using Wasm target. It looks like `flutter_keyboard_visibility_web` was created to always return `false` on web platforms. The Web is still not supported with this fork.

Your existing code that use `package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart` should work by replacing it with:

```dart
import 'package:flutter_keyboard_visibility_temp_fork/flutter_keyboard_visibility_temp_fork.dart';
```

Once you remove `flutter_keyboard_visibility` from your `pubspec.yaml` and add `flutter_keyboard_visibility_temp_fork` instead.

`flutter_keyboard_visibility_web` and `flutter_keyboard_visibility` were merged into one package since we didn't see a strong reason for our fork to have multiple packages, desktop is not meant to be supported (virtual keyboard detection is still not a feature) and web is still not supported. The package should still return `false` on those unsupported platforms. Only Android and iOS are supported.

The fork `flutter_keyboard_visibility_temp_fork` still depends on [flutter_keyboard_visibility_platform_interface](https://pub.dev/packages/flutter_keyboard_visibility_platform_interface), [flutter_keyboard_visibility_macos](https://pub.dev/packages/flutter_keyboard_visibility_macos),
[flutter_keyboard_visibility_windows](https://pub.dev/packages/flutter_keyboard_visibility_windows) and [flutter_keyboard_visibility_linux](https://pub.dev/packages/flutter_keyboard_visibility_linux)
for compatibility.

Refer to [flutter_keyboard_visibility](https://pub.dev/packages/flutter_keyboard_visibility) for more details about the usage. We're looking forward to seeing new changes in `flutter_keyboard_visibility` so this fork is no longer necessary.