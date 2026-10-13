import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/models/airport.dart';
import '../data/services/airport_service.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class AirportAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(Airport airport, String? terminal)? onAirportSelected;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  const AirportAutocompleteField({
    super.key,
    this.label = 'AIRPORT',
    this.hint = 'Click to search or select airport',
    this.icon = Icons.airplanemode_active_rounded,
    this.controller,
    this.focusNode,
    this.onAirportSelected,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<AirportAutocompleteField> createState() => _AirportAutocompleteFieldState();
}

class _AirportAutocompleteFieldState extends State<AirportAutocompleteField> {
  TextEditingController? _internalController;
  TextEditingController get _effectiveController =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Airport> _allAirports = [];
  List<Airport> _filteredAirports = [];
  bool _isLoading = true;
  Timer? _debounce;
  bool _isInteractingWithOverlay = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    final list = await AirportService.getAirports();
    if (mounted) {
      setState(() {
        _allAirports = list;
        _filteredAirports = list;
        _isLoading = false;
      });
      if (_effectiveFocusNode.hasFocus) {
        _showOverlay();
      }
    }
  }

  @override
  void didUpdateWidget(AirportAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
    if (_effectiveFocusNode.hasFocus) {
      _filterAirports(_effectiveController.text);
      _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_effectiveFocusNode.hasFocus && !_isInteractingWithOverlay) {
          _hideOverlay();
        }
      });
    }
  }

  void _filterAirports(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredAirports = _allAirports;
    } else {
      _filteredAirports = _allAirports.where((a) {
        final nameMatch = a.name.toLowerCase().contains(q);
        final codeMatch = a.code.toLowerCase().contains(q);
        final cityMatch = a.city.toLowerCase().contains(q);
        final stateMatch = (a.state ?? '').toLowerCase().contains(q);
        return nameMatch || codeMatch || cityMatch || stateMatch;
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _filterAirports(query);
        });
        if (_effectiveFocusNode.hasFocus) {
          _showOverlay();
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

  void _selectAirport(Airport airport) {
    final defaultTerminal =
        airport.terminals.isNotEmpty ? airport.terminals.first : null;
    final displayText = '${airport.name} (${airport.code})';

    _effectiveController.text = displayText;
    _effectiveController.selection = TextSelection.fromPosition(
      TextPosition(offset: displayText.length),
    );
    _isInteractingWithOverlay = false;
    _hideOverlay();
    _effectiveFocusNode.unfocus();

    widget.onAirportSelected?.call(airport, defaultTerminal);
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
      builder: (context) => Positioned(
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
              constraints: const BoxConstraints(maxHeight: 330),
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
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: CircularProgressIndicator(color: kAmberDeep),
                        ),
                      )
                    : _filteredAirports.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Text(
                                'No matching airports found',
                                style: GoogleFonts.outfit(color: kInkSoft),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: _filteredAirports.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: kInputBorder.withValues(alpha: 0.5),
                            ),
                            itemBuilder: (context, index) {
                              final airport = _filteredAirports[index];
                              return InkWell(
                                onTap: () => _selectAirport(airport),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: kPrimaryGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          airport.code,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            color: kInk,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              airport.name,
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                                color: kInk,
                                              ),
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              '${airport.city}${airport.state != null && airport.state!.isNotEmpty ? ", ${airport.state}" : ""}${airport.terminals.isNotEmpty ? " • ${airport.terminals.length} Terminals" : ""}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color: kInkSoft,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.north_west_rounded,
                                        size: 15,
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
          boxShadow: hasFocus
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
                    onTap: () {
                      _filterAirports(_effectiveController.text);
                      _showOverlay();
                    },
                    onChanged: (val) {
                      _onSearchChanged(val);
                      widget.onChanged?.call(val);
                    },
                    style: GoogleFonts.outfit(
                      color: kInk,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.outfit(
                        color: kInkSoft.withValues(alpha: 0.5),
                        fontSize: 13.5,
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
                  _filterAirports('');
                  setState(() {});
                  if (_effectiveFocusNode.hasFocus) {
                    _showOverlay();
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.clear_rounded, size: 16, color: kInkSoft),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: kInkSoft,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
