import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/cities.dart';
import '../data/services/location_service.dart';
import 'dart:async';

class CityAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const CityAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _updateSuggestions(widget.controller.text);
      } else {
        _hideOverlay();
      }
    });
  }

  void _updateSuggestions(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _suggestions = []);
        _hideOverlay();
        return;
      }

      final results = await LocationService.searchCities(query);

      if (mounted) {
        setState(() {
          _suggestions = results;
        });

        if (_suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _hideOverlay();
        }
      }
    });
  }

  void _showOverlay() {
    _hideOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade100),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final city = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city, size: 18, color: Colors.amber),
                    title: Text(city['display_name'].split(',')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(city['display_name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                    onTap: () {
                      widget.controller.text = city['display_name'].split(',')[0];
                      LocationService.saveCityToBackend(city);
                      _focusNode.unfocus();
                      _hideOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.02),
          border: Border.all(color: Colors.amber.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: _updateSuggestions,
                    style: GoogleFonts.outfit(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
