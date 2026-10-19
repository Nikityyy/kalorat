import 'package:flutter/widgets.dart';

/// Rebuilds every widget below [context], keeping their state. The colors are
/// read where a widget builds, so this is how a theme change reaches widgets
/// that do not otherwise depend on the theme.
void rebuildAll(BuildContext context) {
  void visit(Element element) {
    element.markNeedsBuild();
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
}
