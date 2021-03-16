import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PlatformSwitch extends StatelessWidget {
  final WidgetBuilder iosBuilder;
  final WidgetBuilder androidBuilder;

  const PlatformSwitch({
    Key key,
    this.iosBuilder,
    this.androidBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    assert(theme.platform != null);

    switch (theme.platform) {
      case TargetPlatform.macOS:
      case TargetPlatform.iOS:
        return iosBuilder(context);
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      default:
        return androidBuilder(context);
    }
  }
}
