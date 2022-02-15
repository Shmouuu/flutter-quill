import 'package:flutter/widgets.dart';

class DgFocusNode extends FocusNode {
  DgFocusNode(
      {this.isShortCuts = false, FocusOnKeyCallback? onKey, String? debugLabel})
      : super(debugLabel: debugLabel, onKey: onKey);

  final bool isShortCuts;
}

class DgBsFocusNode extends DgFocusNode {
  DgBsFocusNode({String? debugLabel}) : super(debugLabel: debugLabel);
}
