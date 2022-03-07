import 'package:flutter/material.dart';

class CheckboxPoint extends StatefulWidget {
  const CheckboxPoint({
    required this.size,
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.uiBuilder,
    Key? key,
  }) : super(key: key);

  final double size;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final QuillCheckboxBuilder? uiBuilder;

  @override
  _CheckboxPointState createState() => _CheckboxPointState();
}

class _CheckboxPointState extends State<CheckboxPoint> {
  @override
  Widget build(BuildContext context) {
    if (widget.uiBuilder != null) {
      return widget.uiBuilder!.build(
        context: context,
        isChecked: widget.value,
        onChanged: widget.onChanged,
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 4),
      width: widget.size,
      height: widget.size,
      child: Checkbox(
        onChanged: widget.enabled
            ? (value) => widget.onChanged(!widget.value)
            : null,
        value: widget.value,
      ),
    );
  }
}

abstract class QuillCheckboxBuilder {
  Widget build({
    required BuildContext context,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  });
}
