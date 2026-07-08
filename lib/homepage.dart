import 'package:flutter/material.dart';
import 'package:women_safety_health_app/app_theme.dart';
import 'package:women_safety_health_app/live_location.dart';
import 'package:women_safety_health_app/peroid_tracker.dart';
import 'package:women_safety_health_app/smsemrgency.dart';
import 'sos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _blobController;
  late AnimationController _staggerController;
  final List<Animation<double>> _cardAnims = [];

  final List<_FeatureItem> features = const [
    _FeatureItem(
      title: 'Menstrual\nCycle',
      subtitle: 'Track your cycle & wellness',
      emoji: '🌸',
      tag: 'Health',
      gradient: LinearGradient(
        colors: [Color(0xFFFF85A1), Color(0xFFE8587A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: Color(0xFFE8587A),
      tagColor: Color(0xFFE8587A),
    ),
    _FeatureItem(
      title: 'Live\nLocation',
      subtitle: 'Hospitals & police near you',
      emoji: '📍',
      tag: 'Safety',
      gradient: LinearGradient(
        colors: [Color(0xFF5AADEE), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: Color(0xFF5AADEE),
      tagColor: Color(0xFF3B82F6),
    ),
    _FeatureItem(
      title: 'SOS\nEmergency',
      subtitle: 'One tap emergency call',
      emoji: '🆘',
      tag: 'Emergency',
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFCC3D3D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: Color(0xFFFF6B6B),
      tagColor: Color(0xFFFF6B6B),
    ),
    _FeatureItem(
      title: 'SMS\nAlert',
      subtitle: 'Send SMS without internet',
      emoji: '💬',
      tag: 'Alert',
      gradient: LinearGradient(
        colors: [Color(0xFFB07FE8), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shadowColor: Color(0xFFB07FE8),
      tagColor: Color(0xFF7C3AED),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (int i = 0; i < features.length; i++) {
      final start = (i * 0.15).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      _cardAnims.add(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ));
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _blobController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _navigate(int index) {
    Widget page;
    switch (index) {
      case 0: page = const PeriodTrackerPage(); break;
      case 1: page = const LiveLocationPage(); break;
      case 2: page = const SOSPage(); break;
      case 3: page = const SMSEmergencyPage(); break;
      default: return;
    }
    Navigator.push(context, _route(page));
  }

  PageRoute _route(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionsBuilder: (_, a, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
        child: child,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 350),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _blobController,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _BlobPainter(_blobController.value),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildHeroCard()),
                SliverToBoxAdapter(child: _buildSectionLabel()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ScaleTransition(
                        scale: _cardAnims[i],
                        child: _FeatureCard(
                          item: features[i],
                          onTap: () => _navigate(i),
                        ),
                      ),
                      childCount: features.length,
                    ),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HerSafe ✦',
                style: const TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.rose,
                  letterSpacing: 0.3,
                ),
              ),
              Text('with you, always', style: AppTheme.body(13)),
            ],
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(Icons.shield_rounded,
                color: AppTheme.rose, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _blobController,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _blobController.value * 3.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: AppTheme.gradientCard(
              gradient: AppTheme.roseGradient,
              radius: 24,
              shadowColor: AppTheme.rose,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay protected 🌷',
                        style: AppTheme.body(13,
                            weight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your safety\nstarts here.',
                        style: TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text('Solapur, Maharashtra',
                                style: AppTheme.label(11,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Text('🌸', style: TextStyle(fontSize: 64)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
      child: const Text(
        'Choose a feature',
        style: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textDark,
        ),
      ),
    );
  }
}

// ── Feature Card ──────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final _FeatureItem item;
  final VoidCallback onTap;
  const _FeatureCard({required this.item, required this.onTap});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - _press.value * 0.04,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: item.shadowColor.withOpacity(0.2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.shadowColor.withOpacity(0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: item.gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: item.shadowColor.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                    Text(item.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                  Text(item.tag, style: AppTheme.label(9, color: item.tagColor)),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(item.subtitle,
                    style: AppTheme.body(10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final String emoji;
  final String tag;
  final LinearGradient gradient;
  final Color shadowColor;
  final Color tagColor;

  const _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.tag,
    required this.gradient,
    required this.shadowColor,
    required this.tagColor,
  });
}

// ── Blob Background ───────────────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
  _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE4EE), Color(0xFFF8F0FF), Color(0xFFFFF4F7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, s.width, s.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), bg);

    void blob(double x, double y, double r, Color c, double blur) {
      canvas.drawCircle(Offset(x, y), r,
          Paint()
            ..color = c
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur));
    }

    blob(s.width * 0.85, s.height * 0.06 + t * 14, s.width * 0.38,
        const Color(0xFFFFD6E7).withOpacity(0.5), 60);
    blob(s.width * 0.05, s.height * 0.30 - t * 10, s.width * 0.38,
        const Color(0xFFE8D5FF).withOpacity(0.35), 70);
    blob(s.width * 0.55, s.height * 0.90 + t * 6, s.width * 0.42,
        const Color(0xFFFFB3CA).withOpacity(0.22), 65);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}