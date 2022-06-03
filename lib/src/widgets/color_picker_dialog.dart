// ignore_for_file: unused_import

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' hide MaterialPicker;
import 'package:oktoast/oktoast.dart';

import 'material_picker.dart';

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
  late final TextEditingController _textController = TextEditingController();
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
      content: SizedBox(
        width: 340,
        height: 460,
        child: Column(
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
              labelStyle: const TextStyle(fontFamily: 'Poppins'),
              tabs: [
                const Tab(text: 'Swatches', height: 36),
                const Tab(text: 'Custom', height: 36),
              ],
            ),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onRefresh);
    // ignore: cascade_invocations
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onRefresh() {
    setState(() {});
  }

  Widget _buildMainContent() {
    if (_controller.index == 0) {
      return MaterialPicker(
        portraitOnly: true,
        pickerColor: widget.color,
        onColorChanged: (color) {
          widget.onChanged?.call(color, true);
          Navigator.pop(context);
        },
      );
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPicker(
            portraitOnly: true,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.7,
            pickerColor: _color,
            colorPickerWidth: 340,
            hexInputController: _textController,
            labelTypes: [],
            onColorChanged: (color) {
              _color = color;
              widget.onChanged?.call(color, false);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: CupertinoTextField(
              controller: _textController,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.tag),
              ),
              style: const TextStyle(fontFamily: 'Poppins'),
              suffix: IconButton(
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _textController.text))
                      .then((value) => showToast('Copied!'));
                },
              ),
              maxLength: 9,
              inputFormatters: [
                // Any custom input formatter can be passed
                // here or use any Form validator you want.
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(kValidHexPattern)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
