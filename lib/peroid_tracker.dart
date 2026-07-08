import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:women_safety_health_app/app_theme.dart';

class PeriodTrackerPage extends StatefulWidget {
  const PeriodTrackerPage({super.key});
  @override
  State<PeriodTrackerPage> createState() => _PeriodTrackerPageState();
}

class _PeriodTrackerPageState extends State<PeriodTrackerPage>
    with SingleTickerProviderStateMixin {
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  late TabController _tabController;

  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  static const Map<String, _PhaseInfo> _phases = {
    'Menstrual': _PhaseInfo(
      emoji: '🩸',
      color: Color(0xFFE8587A),
      days: 'Days 1–5',
      description: 'Your uterus sheds its lining. Rest and gentle care is key.',
      diet: [
        'Iron-rich foods: spinach, lentils, tofu',
        'Anti-inflammatory: ginger tea, turmeric',
        'Dark chocolate (magnesium)',
        'Warm soups and herbal teas',
        'Avoid: caffeine, salty & processed foods',
      ],
      exercise: [
        'Light yoga & stretching',
        'Slow walks in fresh air',
        "Child's pose, cat-cow stretch",
        'Rest when needed — listen to your body',
      ],
    ),
    'Follicular': _PhaseInfo(
      emoji: '🌱',
      color: Color(0xFF3CC98A),
      days: 'Days 6–13',
      description: 'Energy rises as estrogen increases. Great time to start new things.',
      diet: [
        'Fermented foods: yogurt, kimchi',
        'Lean proteins: eggs, chicken, fish',
        'Fresh veggies & salads',
        'Berries & citrus for antioxidants',
        'Stay well hydrated',
      ],
      exercise: [
        'Running, cycling, HIIT',
        'Strength training sessions',
        'Dance classes or aerobics',
        'High-energy workouts welcome!',
      ],
    ),
    'Ovulation': _PhaseInfo(
      emoji: '✨',
      color: Color(0xFFFFAA40),
      days: 'Day ~14',
      description: "Peak energy and mood. You're at your most social and vibrant.",
      diet: [
        'Zinc-rich: pumpkin seeds, cashews',
        'Fiber: beans, whole grains, broccoli',
        'Antioxidant-rich: tomatoes, pomegranate',
        'Light & clean meals',
        'Limit alcohol and sugar',
      ],
      exercise: [
        'Peak performance workouts',
        'Group fitness or sports',
        'Competitive activities',
        'Intense cardio & strength combos',
      ],
    ),
    'Luteal': _PhaseInfo(
      emoji: '🌙',
      color: Color(0xFFB07FE8),
      days: 'Days 15–28',
      description: 'Progesterone rises. Wind down, focus inward, and nourish yourself.',
      diet: [
        'Complex carbs: sweet potato, oats',
        'Magnesium: almonds, avocado, banana',
        'Calcium: dairy, leafy greens',
        'Reduce bloating: avoid raw veggies',
        'Herbal teas for PMS relief',
      ],
      exercise: [
        'Pilates & yoga',
        'Low-impact swimming',
        'Walking & light cycling',
        'Breathwork & meditation',
      ],
    ),
  };

  static const List<_ProductLink> _products = [
    _ProductLink('Sanitary Pads', '🩹',
        'https://www.amazon.in/s?k=sanitary+pads', Color(0xFFFF85A1)),
    _ProductLink('Tampons', '🌀',
        'https://www.amazon.in/s?k=tampons', Color(0xFFB07FE8)),
    _ProductLink('Menstrual Cup', '🥤',
        'https://www.amazon.in/s?k=menstrual+cup', Color(0xFF3CC98A)),
    _ProductLink('Heating Pad', '🔥',
        'https://www.amazon.in/s?k=heating+pad+period', Color(0xFFFFAA40)),
    _ProductLink('Pain Relief', '💊',
        'https://www.amazon.in/s?k=mefenamic+acid+period+pain',
        Color(0xFF5AADEE)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFromFirestore() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('period_tracker')
          .doc('settings')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          if (data['lastPeriodDate'] != null) {
            _lastPeriodDate =
                (data['lastPeriodDate'] as Timestamp).toDate();
          }
          _cycleLength = data['cycleLength'] ?? 28;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveToFirestore() async {
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('period_tracker')
          .doc('settings')
          .set({
        'lastPeriodDate': _lastPeriodDate != null
            ? Timestamp.fromDate(_lastPeriodDate!)
            : null,
        'cycleLength': _cycleLength,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  String get _currentPhase {
    if (_lastPeriodDate == null) return 'Unknown';
    final day = DateTime.now().difference(_lastPeriodDate!).inDays + 1;
    if (day <= 5) return 'Menstrual';
    if (day <= 13) return 'Follicular';
    if (day == 14) return 'Ovulation';
    return 'Luteal';
  }

  int get _cycleDay {
    if (_lastPeriodDate == null) return 0;
    return (DateTime.now().difference(_lastPeriodDate!).inDays + 1)
        .clamp(1, _cycleLength);
  }

  DateTime? get _nextPeriod => _lastPeriodDate != null
      ? _lastPeriodDate!.add(Duration(days: _cycleLength))
      : null;

  int get _daysUntilNext {
    if (_nextPeriod == null) return 0;
    return _nextPeriod!.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const HerBackground(child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTrackerTab(),
                      _buildPhaseTab(),
                      _buildProductsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: AppTheme.cardDecoration(radius: 12),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Menstrual Cycle',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          const Text('🌸', style: TextStyle(fontSize: 26)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.rosePale.withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppTheme.roseGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: AppTheme.label(12, color: Colors.white),
          unselectedLabelStyle:
          AppTheme.body(12, weight: FontWeight.w500),
          unselectedLabelColor: AppTheme.textMid,
          labelColor: Colors.white,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Tracker'),
            Tab(text: 'Phase'),
            Tab(text: 'Products'),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackerTab() {
    final phase = _currentPhase;
    final info = _phases[phase];
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        if (info != null) _buildPhaseStatusCard(phase, info),
        const SizedBox(height: 16),
        _buildCalendarCard(),
        const SizedBox(height: 16),
        _buildCycleLengthCard(),
        const SizedBox(height: 16),
        if (_nextPeriod != null) _buildNextPeriodCard(),
        const SizedBox(height: 16),
        HerButton(
          label: 'Save to Cloud ☁️',
          onTap: () async {
            await _saveToFirestore();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Saved!',
                    style: AppTheme.body(14, color: Colors.white)),
                backgroundColor: AppTheme.rose,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          icon: Icons.cloud_upload_rounded,
        ),
      ],
    );
  }

  Widget _buildPhaseStatusCard(String phase, _PhaseInfo info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [info.color.withOpacity(0.9), info.color.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(info.color),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Phase',
                    style: AppTheme.body(12,
                        weight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Text(
                  phase,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(info.days,
                    style: AppTheme.label(12, color: Colors.white)),
                const SizedBox(height: 8),
                if (_cycleDay > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Day $_cycleDay of $_cycleLength',
                        style: AppTheme.label(11, color: Colors.white)),
                  ),
              ],
            ),
          ),
          Text(info.emoji, style: const TextStyle(fontSize: 56)),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Last Period Start',
              style: AppTheme.label(13, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: _lastPeriodDate ?? DateTime.now(),
            selectedDayPredicate: (day) =>
            _lastPeriodDate != null && isSameDay(day, _lastPeriodDate!),
            onDaySelected: (selected, focused) {
              setState(() => _lastPeriodDate = selected);
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                gradient: AppTheme.roseGradient,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                  color: AppTheme.rosePale, shape: BoxShape.circle),
              todayTextStyle:
              AppTheme.label(14, color: AppTheme.rose),
              selectedTextStyle:
              AppTheme.label(14, color: Colors.white),
              defaultTextStyle:
              AppTheme.body(13, color: AppTheme.textDark),
              weekendTextStyle:
              AppTheme.body(13, color: AppTheme.rose),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle:
              AppTheme.label(14, color: AppTheme.textDark),
              leftChevronIcon:
              const Icon(Icons.chevron_left, color: AppTheme.rose),
              rightChevronIcon:
              const Icon(Icons.chevron_right, color: AppTheme.rose),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTheme.body(11, color: AppTheme.textMid),
              weekendStyle: AppTheme.label(11, color: AppTheme.rose),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleLengthCard() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cycle Length',
                  style: AppTheme.label(14, color: AppTheme.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.roseGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_cycleLength days',
                    style: AppTheme.label(13, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.rose,
              inactiveTrackColor: AppTheme.rosePale,
              thumbColor: AppTheme.rose,
              overlayColor: AppTheme.rose.withOpacity(0.15),
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _cycleLength.toDouble(),
              min: 21,
              max: 35,
              divisions: 14,
              onChanged: (v) => setState(() => _cycleLength = v.toInt()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('21 days', style: AppTheme.body(11)),
              Text('35 days', style: AppTheme.body(11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextPeriodCard() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.lavLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
                child: Text('📅', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next Period',
                  style: AppTheme.body(12, weight: FontWeight.w500)),
              Text(
                '${_nextPeriod!.day}/${_nextPeriod!.month}/${_nextPeriod!.year}',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                _daysUntilNext > 0
                    ? 'In $_daysUntilNext days'
                    : 'Starts today!',
                style: AppTheme.label(12, color: AppTheme.lavender),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: _phases.entries.map((e) {
        return _PhaseCard(
          name: e.key,
          info: e.value,
          isActive: _currentPhase == e.key,
        );
      }).toList(),
    );
  }

  Widget _buildProductsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text(
          'Period Essentials 🛍️',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text('Shop trusted products for your comfort',
            style: AppTheme.body(13)),
        const SizedBox(height: 18),
        ..._products.map((p) => _ProductCard(product: p)),
      ],
    );
  }
}

// ── Phase Card ─────────────────────────────────────────────
class _PhaseCard extends StatefulWidget {
  final String name;
  final _PhaseInfo info;
  final bool isActive;
  const _PhaseCard(
      {required this.name, required this.info, required this.isActive});
  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.isActive
                ? widget.info.color.withOpacity(0.5)
                : AppTheme.rosePale.withOpacity(0.5),
            width: widget.isActive ? 2 : 1.2,
          ),
          boxShadow: AppTheme.cardShadow(widget.info.color),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: widget.info.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                          child: Text(widget.info.emoji,
                              style: const TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              if (widget.isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      widget.info.color,
                                      widget.info.color.withOpacity(0.7)
                                    ]),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Active',
                                      style: AppTheme.label(9,
                                          color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                          Text(widget.info.days,
                              style: AppTheme.body(11,
                                  color: widget.info.color)),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMid,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(
                  color: AppTheme.rosePale.withOpacity(0.7), height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.info.description,
                        style: AppTheme.body(13, color: AppTheme.textMid)),
                    const SizedBox(height: 14),
                    _SectionLabel(
                        label: '🥗 Diet Recommendations',
                        color: widget.info.color),
                    const SizedBox(height: 8),
                    ...widget.info.diet.map(
                            (d) => _BulletItem(text: d, color: widget.info.color)),
                    const SizedBox(height: 12),
                    _SectionLabel(
                        label: '🏃 Exercise Tips',
                        color: widget.info.color),
                    const SizedBox(height: 8),
                    ...widget.info.exercise.map(
                            (e) => _BulletItem(text: e, color: widget.info.color)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTheme.label(12, color: color)),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Container(
                width: 6,
                height: 6,
                decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          Expanded(child: Text(text, style: AppTheme.body(13))),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _ProductLink product;
  const _ProductCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(product.url),
            mode: LaunchMode.externalApplication),
        child: Container(
          decoration: AppTheme.cardDecoration(),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: product.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: AppTheme.label(15,
                            color: AppTheme.textDark)),
                    Text('Shop on Amazon →',
                        style: AppTheme.body(12, color: product.color)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded,
                  color: product.color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhaseInfo {
  final String emoji;
  final Color color;
  final String days;
  final String description;
  final List<String> diet;
  final List<String> exercise;
  const _PhaseInfo({
    required this.emoji, required this.color, required this.days,
    required this.description, required this.diet, required this.exercise,
  });
}

class _ProductLink {
  final String name;
  final String emoji;
  final String url;
  final Color color;
  const _ProductLink(this.name, this.emoji, this.url, this.color);
}