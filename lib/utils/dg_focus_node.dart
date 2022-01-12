import 'package:flutter/widgets.dart';

class DgFocusNode extends FocusNode {
  DgFocusNode({this.isShortCuts = false});

  final bool isShortCuts;
}
