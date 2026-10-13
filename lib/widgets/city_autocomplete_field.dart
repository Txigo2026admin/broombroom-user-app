import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/services/location_service.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class CityAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(Map<String, dynamic> city)? onCitySelected;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const CityAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.focusNode,
    this.onCitySelected,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _isInteractingWithOverlay = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(CityAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
    if (_effectiveFocusNode.hasFocus) {
      if (_effectiveController.text.trim().isNotEmpty) {
        _updateSuggestions(_effectiveController.text);
      }
    } else {
      // Delay closing overlay so tap on suggestion items has time to execute
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_effectiveFocusNode.hasFocus && !_isInteractingWithOverlay) {
          _hideOverlay();
        }
      });
    }
  }

  void _updateSuggestions(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final clean = query.trim();
      if (clean.isEmpty) {
        setState(() => _suggestions = []);
        _hideOverlay();
        return;
      }

      final results = await LocationService.searchCities(clean);

      if (mounted) {
        setState(() {
          _suggestions = results;
        });

        if (_suggestions.isNotEmpty && _effectiveFocusNode.hasFocus) {
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

  String _getFormattedTitle(Map<String, dynamic> city) {
    if (city['name'] != null && city['name'].toString().trim().isNotEmpty) {
      return city['name'].toString().trim();
    }
    final raw = (city['display_name'] ?? city['displayName'] ?? '').toString();
    final parts = raw.split(',');
    if (parts.length >= 2) {
      final first = parts[0].trim();
      final second = parts[1].trim();
      if (second.isNotEmpty && second.length <= 25) {
        return '$first, $second';
      }
      return first;
    }
    return parts.isNotEmpty ? parts[0].trim() : raw;
  }

  void _selectCity(Map<String, dynamic> city) {
    final title = _getFormattedTitle(city);
    _effectiveController.text = title;
    _effectiveController.selection = TextSelection.fromPosition(
      TextPosition(offset: title.length),
    );
    _isInteractingWithOverlay = false;
    _hideOverlay();
    _effectiveFocusNode.unfocus();
    if (widget.onCitySelected != null) {
      widget.onCitySelected!(city);
    }
    LocationService.saveCityToBackend(city);
    widget.onSubmitted?.call();
    if (mounted) {
      setState(() {});
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox.shrink());
    }
    var size = renderBox.size;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                color: kCardBg,
                shadowColor: kAmber.withValues(alpha: 0.35),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kInputBorder),
                  ),
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      _isInteractingWithOverlay = true;
                    },
                    onPointerUp: (_) {
                      Future.delayed(const Duration(milliseconds: 150), () {
                        _isInteractingWithOverlay = false;
                      });
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            height: 1,
                            color: kInputBorder.withValues(alpha: 0.5),
                          ),
                      itemBuilder: (context, index) {
                        final city = _suggestions[index];
                        final title = _getFormattedTitle(city);
                        final fullAddress =
                            (city['display_name'] ??
                                    city['displayName'] ??
                                    '')
                                .toString();

                        return InkWell(
                          onTap: () => _selectCity(city),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: kAmberSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    size: 16,
                                    color: kAmberDeep,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: kInk,
                                        ),
                                      ),
                                      if (fullAddress.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          fullAddress,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: kInkSoft,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.north_west_rounded,
                                  size: 14,
                                  color: kAmberDeep,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _internalController?.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasFocus = _effectiveFocusNode.hasFocus;
    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kInputBg,
          border: Border.all(
            color: hasFocus ? kAmberDeep : kInputBorder,
            width: hasFocus ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              hasFocus
                  ? [
                    BoxShadow(
                      color: kAmber.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: hasFocus ? kAmberDeep : kAmber, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: hasFocus ? kAmberDeep : kInkSoft,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _effectiveController,
                    focusNode: _effectiveFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      if (_suggestions.isNotEmpty) {
                        _selectCity(_suggestions.first);
                      } else {
                        _hideOverlay();
                        _effectiveFocusNode.unfocus();
                      }
                      widget.onSubmitted?.call();
                    },
                    onChanged: (val) {
                      _updateSuggestions(val);
                      widget.onChanged?.call(val);
                    },
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.outfit(
                        color: kInkSoft.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 2),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            if (_effectiveController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _effectiveController.clear();
                  widget.onChanged?.call('');
                  _updateSuggestions('');
                  setState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.clear_rounded, size: 16, color: kInkSoft),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
