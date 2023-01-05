import 'package:flutter/widgets.dart';

class NeverScrollableScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const NeverScrollableScrollPhysics();
  }
}
