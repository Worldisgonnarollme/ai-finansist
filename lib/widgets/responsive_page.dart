import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Centers page content in a comfortable working width on laptop/desktop
/// browser windows, instead of letting the mobile-first layout stretch
/// full-bleed across a 1440px canvas. Below [AppBreakpoints.desktop] this
/// is a no-op — phones and narrow windows keep the original edge-to-edge
/// layout untouched.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsivePage({super.key, required this.child, this.maxWidth = 640});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < AppBreakpoints.desktop) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
