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
      dropdownBuilder: (context, selectedItem) {
        return Text(selectedItem ?? 'Default',
            style: GoogleFonts.asMap()[selectedItem]?.call());
      },
      popupProps: PopupProps.menu(
        constraints: const BoxConstraints(maxHeight: 250),
        searchFieldProps: const TextFieldProps(

          decoration: InputDecoration(
            filled: true,
            labelText: 'Pick a family font',
            hintText: 'Font family',
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF01689A)),
            ),
          ),
        ),
        showSearchBox: true,
        itemBuilder: (context, item, isSelected) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(item, style: GoogleFonts.asMap()[item]?.call()),
          );
        },
      ),
      dropdownButtonProps: const DropdownButtonProps(
        icon: Icon(Icons.arrow_drop_down, color: Colors.black),
      ),
      clearButtonProps: const ClearButtonProps(
        isVisible: true,
        icon: Icon(Icons.clear, color: Colors.black),
      ),
      items: items,
      onChanged: (value) {
        widget.onChanged(value);
      },
      selectedItem: widget.fontFamily,
    );
  }
}
