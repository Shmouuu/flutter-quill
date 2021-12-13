import 'package:flutter/material.dart';

import 'font_picker.dart';

class FontPickerDialog extends StatefulWidget {
  const FontPickerDialog({
    required this.fontFamily,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  final String? fontFamily;
  final ValueChanged<String?> onChanged;

  @override
  YoutubeDialogState createState() => YoutubeDialogState();
}

class YoutubeDialogState extends State<FontPickerDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, minWidth: 300),
            child: FontPicker(
              fontFamily: widget.fontFamily,
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _cancel() {
    Navigator.pop(context);
  }
}
