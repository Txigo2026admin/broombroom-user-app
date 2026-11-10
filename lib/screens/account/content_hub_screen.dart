import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class ContentHubScreen extends StatefulWidget {
  const ContentHubScreen({super.key});

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

/// Simple data model so a card can carry its own details.
class _ContentItem {
  const _ContentItem({
    required this.image,
    required this.title,
    required this.category,
    required this.readTime,
    required this.description,
    this.isTall = false,
  });

  final String image;
  final String title;
  final String category;
  final String readTime;
  final String description;
  final bool isTall;
}

class _ContentHubScreenState extends State<ContentHubScreen> {
  final List<String> categories = const [
    'All',
    'Arts and Crafts',
    'Beaches',
    'Book local',
    'Culture',
  ];

  int _selectedCategory = 0;

  /// Order matters: even indexes go to the left column, odd to the right.
  /// (monastery + chardham left, turtle + beach right — same as before)
  static const List<_ContentItem> _items = [
    _ContentItem(
      image: 'assets/images/monastery.png',
      title: '10 Spectacular Buddhist Monasteries in India',
      category: 'Culture',
      readTime: '6 min read',
      isTall: false,
      description:
          'From the cliffside gompas of Ladakh to the quiet courtyards of '
          'Sikkim, India is home to some of the most breathtaking Buddhist '
          'monasteries in the world. We have rounded up ten that are worth '
          'planning an entire trip around — complete with prayer halls, '
          'butter-lamp rituals and mountain views that stay with you long '
          'after you leave.',
    ),
    _ContentItem(
      image: 'assets/images/turtle.png',
      title: '5 Reasons To Attend Velas Turtle Festival',
      category: 'Beaches',
      readTime: '5 min read',
      isTall: true,
      description:
          'Every year between November and February, thousands of Olive '
          'Ridley turtles arrive at Velas beach in Maharashtra to lay their '
          'eggs. Here is why the Velas Turtle Festival deserves a spot on '
          'your calendar — and how to plan your visit responsibly without '
          'disturbing the hatchlings.',
    ),
    _ContentItem(
      image: 'assets/images/chardham_banner.png',
      title: '8 Monuments and 8 mysteries!',
      category: 'Culture',
      readTime: '4 min read',
      isTall: true,
      description:
          'Some of India\'s most famous monuments are hiding secrets that '
          'historians still argue about. From unreadable inscriptions to '
          'engineering feats we cannot fully explain, here are eight '
          'monuments paired with the mysteries that make them so '
          'irresistible.',
    ),
    _ContentItem(
      image: 'assets/images/beach_banner.png',
      title: 'A detailed guide on Char Dham Yatra in Uttarakhand',
      category: 'Book local',
      readTime: '9 min read',
      isTall: false,
      description:
          'Char Dham Yatra is more than a pilgrimage — it is a twelve-day '
          'journey through the most dramatic landscapes of the Himalayas. '
          'This guide covers the route, the best time to travel, permits, '
          'stay options, altitude tips and everything else you need before '
          'you set off.',
    ),
  ];

  List<_ContentItem> get _filteredItems {
    if (_selectedCategory == 0) return _items;
    final selected = categories[_selectedCategory];
    return _items.where((item) => item.category == selected).toList();
  }

  void _showDetails(_ContentItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: kInk.withValues(alpha: 0.45),
      builder: (_) => _DetailsSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    final leftColumn = <_ContentItem>[];
    final rightColumn = <_ContentItem>[];
    for (var i = 0; i < items.length; i++) {
      (i.isEven ? leftColumn : rightColumn).add(items[i]);
    }

    return Scaffold(
      backgroundColor: kBgMid,
      appBar: AppBar(
        backgroundColor: kCardBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kInk),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Content Hub',
          style: GoogleFonts.outfit(
            color: kInk,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Horizontal Categories
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final bool isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? const LinearGradient(
                                colors: [Color(0xFFFFD54F), kAmber],
                              )
                              : null,
                      color: isSelected ? null : kInputBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? kAmberDeep : kInputBorder,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: kAmber.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : const [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categories[index],
                      style: GoogleFonts.outfit(
                        color: isSelected ? kInk : kInkSoft,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Masonry-style Grid
          Expanded(
            child:
                items.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(children: _buildColumn(leftColumn)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(children: _buildColumn(rightColumn)),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildColumn(List<_ContentItem> items) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 16));
      widgets.add(
        _ContentCard(item: items[i], onTap: () => _showDetails(items[i])),
      );
    }
    return widgets;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_off_rounded, size: 48, color: kInkSoft),
          const SizedBox(height: 12),
          Text(
            'Nothing here yet',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another category',
            style: GoogleFonts.outfit(fontSize: 13, color: kInkSoft),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Card with hover lift + tap-to-open-details
/// ---------------------------------------------------------------------------
class _ContentCard extends StatefulWidget {
  const _ContentCard({required this.item, required this.onTap});

  final _ContentItem item;
  final VoidCallback onTap;

  @override
  State<_ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<_ContentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? kAmberDeep : kInputBorder,
              width: _hovered ? 1.4 : 1,
            ),
            boxShadow:
                _hovered
                    ? [
                      BoxShadow(
                        color: kAmber.withValues(alpha: 0.30),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                    : kCardShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'content-image-${item.image}',
                      child: AnimatedScale(
                        scale: _hovered ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        child: Image.asset(
                          item.image,
                          height: item.isTall ? 240 : 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: item.isTall ? 240 : 160,
                            color: const Color(0xFF1E293B),
                            child: const Center(
                              child: Icon(Icons.photo_size_select_actual_outlined, color: Colors.white54, size: 36),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Hover scrim + "open" hint
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _hovered ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  kInk.withValues(alpha: 0.40),
                                ],
                              ),
                            ),
                            alignment: Alignment.bottomRight,
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          item.readTime,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kInkSoft,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: kAmberDeep,
                        ),
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.share_rounded,
                          size: 18,
                          color: kInkSoft,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Bottom sheet that shows the full details of a card
/// ---------------------------------------------------------------------------
class _DetailsSheet extends StatelessWidget {
  const _DetailsSheet({required this.item});

  final _ContentItem item;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'content-image-${item.image}',
                    child: Image.asset(
                      item.image,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 240,
                        color: const Color(0xFF1E293B),
                        child: const Center(
                          child: Icon(Icons.photo_size_select_actual_outlined, color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  ),
                  // drag handle
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // close button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kInputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kInputBorder),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kInkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kInk,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: kInkSoft,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.readTime,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: kInkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Icon(
                          Icons.favorite_rounded,
                          size: 15,
                          color: kAmberDeep,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '1.2k',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: kInkSoft,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(color: kInputBorder, height: 1),
                    const SizedBox(height: 18),
                    Text(
                      item.description,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        height: 1.6,
                        color: kInkSoft,
                      ),
                    ),
                    const SizedBox(height: 26),
                    // primary action
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD54F), kAmber],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kAmber.withValues(alpha: 0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pop(context),
                            child: Center(
                              child: Text(
                                'Read full story',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: kInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
