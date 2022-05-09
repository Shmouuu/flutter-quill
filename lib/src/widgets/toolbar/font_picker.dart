import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontPicker extends StatefulWidget {
  const FontPicker({
    required this.fontFamily,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  final String? fontFamily;
  final ValueChanged<String?> onChanged;

  @override
  _FontPickerState createState() => _FontPickerState();
}

class _FontPickerState extends State<FontPicker> {
  List<String> items = [];

  @override
  void initState() {
    items = GoogleFonts.asMap().entries.map((e) => e.key).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>(
      showSearchBox: true,
      maxHeight: 250,
      dropdownSearchDecoration: const InputDecoration(
        filled: true,
        labelText: 'Pick a family font',
        hintText: 'Font family',
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF01689A)),
        ),
      ),
      dropdownBuilder: (context, selectedItem) {
        return Text(selectedItem ?? 'Default',
            style: GoogleFonts.asMap()[selectedItem]?.call());
      },
      popupItemBuilder: (context, item, isSelected) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(item, style: GoogleFonts.asMap()[item]?.call()),
        );
      },
      clearButtonProps:
          const IconButtonProps(icon: Icon(Icons.clear, color: Colors.black)),
      dropdownButtonProps: const IconButtonProps(
          icon: Icon(Icons.arrow_drop_down, color: Colors.black)),
      items: items,
      showClearButton: true,
      onChanged: (value) {
        widget.onChanged(value);
      },
      selectedItem: widget.fontFamily,
    );
  }
}
