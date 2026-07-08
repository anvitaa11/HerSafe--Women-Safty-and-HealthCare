import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────
  static const Color rose      = Color(0xFFE8587A);
  static const Color roseDark  = Color(0xFFCC3D61);
  static const Color roseLight = Color(0xFFFF85A1);
  static const Color rosePale  = Color(0xFFFFD6E4);
  static const Color blush     = Color(0xFFFFF0F5);
  static const Color lavender  = Color(0xFFB07FE8);
  static const Color lavLight  = Color(0xFFE8D5FF);
  static const Color purple    = Color(0xFF7C3AED);

  static const Color textDark  = Color(0xFF3D1A26);
  static const Color textMid   = Color(0xFF8C5A6A);
  static const Color textLight = Color(0xFFBFA0AA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color bgBase    = Color(0xFFFFF4F7);

  // ── Gradients ─────────────────────────────────────────
  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFFF85A1), Color(0xFFE8587A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFB07FE8), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFFFE4EE), Color(0xFFF8F0FF), Color(0xFFFFF4F7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF5F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text Styles ────────────────────────────────────────
  // Serif display — replaces GoogleFonts.dmSerifDisplay
  static TextStyle heading(double size) => TextStyle(
    fontFamily: 'serif',
    fontSize: size,
    color: textDark,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Sans body — replaces GoogleFonts.dmSans
  static TextStyle body(double size,
      {FontWeight weight = FontWeight.w400, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color ?? textMid,
        height: 1.55,
      );

  // Sans label — replaces GoogleFonts.dmSans semibold
  static TextStyle label(double size, {Color? color}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color ?? rose,
    letterSpacing: 0.4,
  );

  // ── Shadows ────────────────────────────────────────────
  static List<BoxShadow> cardShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.18),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: rose.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // ── Decorations ───────────────────────────────────────
  static BoxDecoration cardDecoration({
    double radius = 20,
    Color? border,
    List<BoxShadow>? shadow,
  }) =>
      BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border ?? rosePale.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: shadow ?? softShadow,
      );

  static BoxDecoration gradientCard({
    required LinearGradient gradient,
    double radius = 20,
    Color? shadowColor,
  }) =>
      BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: (shadowColor ?? rose).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  // ── Theme Data ────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: rose,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: bgBase,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textDark),
      titleTextStyle: TextStyle(
        fontFamily: 'serif',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
    ),
  );
}

// ── Reusable Widgets ──────────────────────────────────────

class HerBackground extends StatelessWidget {
  final Widget child;
  const HerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: child,
    );
  }
}

class HerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final LinearGradient? gradient;
  final IconData? icon;
  final bool fullWidth;

  const HerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient,
    this.icon,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        decoration: AppTheme.gradientCard(
          gradient: gradient ?? AppTheme.roseGradient,
          radius: 14,
          shadowColor: AppTheme.rose,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label, style: AppTheme.label(15, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class HerChip extends StatelessWidget {
  final String label;
  final Color color;
  const HerChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: AppTheme.label(10, color: color)),
    );
  }
}