// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

typedef OnColorChanged = void Function(Color color, bool fromMaterial);

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({
    required this.color,
    this.onChanged,
    this.title,
    Key? key,
  }) : super(key: key);

  final Widget? title;
  final Color color;
  final OnColorChanged? onChanged;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);
  late Color _color = widget.color;

  @override
  void initState() {
    _controller.addListener(_onRefresh);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      backgroundColor: Theme.of(context).canvasColor,
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _controller,
            labelColor: Colors.black,
            unselectedLabelColor: const Color(0xFF5A5A5A),
            indicatorColor: Colors.black,
            indicatorWeight: 1,
            labelPadding: const EdgeInsets.only(top: 8),
            padding: EdgeInsets.zero,
            tabs: [
              const Tab(text: 'Swatches', height: 36),
              const Tab(text: 'Custom', height: 36),
            ],
          ),
          SizedBox(width: 340, height: 502, child: _buildMainContent()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onRefresh);
    // ignore: cascade_invocations
    _controller.dispose();
    super.dispose();
  }

  void _onRefresh() {
    setState(() {});
  }

  Widget _buildMainContent() {
    if (_controller.index == 0) {
      return SingleChildScrollView(
        child: MaterialPicker(
          portraitOnly: true,
          pickerColor: widget.color,
          onColorChanged: (color) {
            widget.onChanged?.call(color, true);
            Navigator.pop(context);
          },
        ),
      );
    }

    return ColorPicker(
      portraitOnly: true,
      pickerColor: _color,
      colorPickerWidth: 340,
      onColorChanged: (color) {
        _color = color;
        widget.onChanged?.call(color, false);
      },
    );
  }
}
