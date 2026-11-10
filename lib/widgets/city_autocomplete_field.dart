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
  bool _isLoading = false;
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
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(
        _handleFocusChange,
      );
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
        if (mounted &&
            !_effectiveFocusNode.hasFocus &&
            !_isInteractingWithOverlay) {
          _hideOverlay();
        }
      });
    }
  }

  void _updateSuggestions(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    final clean = query.trim();
    if (clean.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
      _hideOverlay();
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final results = await LocationService.searchCities(clean);

        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });

          if (_suggestions.isNotEmpty && _effectiveFocusNode.hasFocus) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
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

  String _getFormattedSubtitle(Map<String, dynamic> city, String title) {
    final raw =
        (city['display_name'] ?? city['displayName'] ?? '').toString().trim();
    if (raw.isEmpty) return '';
    if (raw.toLowerCase().startsWith(title.toLowerCase())) {
      final rem =
          raw.substring(title.length).replaceFirst(RegExp(r'^,\s*'), '').trim();
      if (rem.isNotEmpty) return rem;
    }
    return raw;
  }

  IconData _getIconForPlace(Map<String, dynamic> city) {
    final name =
        (city['name'] ?? city['display_name'] ?? '').toString().toLowerCase();
    if (name.contains('airport') || name.contains('terminal')) {
      return Icons.flight_takeoff_rounded;
    }
    if (name.contains('station') ||
        name.contains('railway') ||
        name.contains('metro')) {
      return Icons.directions_transit_rounded;
    }
    if (name.contains('hospital') || name.contains('clinic')) {
      return Icons.local_hospital_rounded;
    }
    if (name.contains('mall') ||
        name.contains('market') ||
        name.contains('bazar')) {
      return Icons.shopping_bag_rounded;
    }
    if (name.contains('hotel') || name.contains('resort')) {
      return Icons.hotel_rounded;
    }
    if (name.contains('restaurant') || name.contains('cafe')) {
      return Icons.restaurant_rounded;
    }
    return Icons.location_on_rounded;
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
                elevation: 14,
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.22),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 290),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7.5,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(17),
                            ),
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.explore_rounded,
                                size: 13,
                                color: kAmberDeep,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LOCATIONS (${_suggestions.length})',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            separatorBuilder:
                                (context, index) => const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                            itemBuilder: (context, index) {
                              final city = _suggestions[index];
                              final title = _getFormattedTitle(city);
                              final subtitle = _getFormattedSubtitle(
                                city,
                                title,
                              );
                              final icon = _getIconForPlace(city);
                              final source = city['source']?.toString() ?? '';

                              return InkWell(
                                onTap: () => _selectCity(city),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9.5,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8E7),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          icon,
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
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13.5,
                                                      color: const Color(
                                                        0xFF1E293B,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (source == 'GoogleMaps')
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          left: 6,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 5,
                                                          vertical: 1.5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEEF2FF,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Google',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 8.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF4F46E5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (subtitle.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
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
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(kAmberDeep),
                  ),
                ),
              )
            else if (_effectiveController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _effectiveController.clear();
                  widget.onChanged?.call('');
                  _updateSuggestions('');
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: kInkSoft.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: kInkSoft,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
