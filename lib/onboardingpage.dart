import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:women_safety_health_app/homepage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _illustrationController;
  late AnimationController _textController;

  final List<OnboardingData> slides = [
    OnboardingData(
      emoji: "🌸",
      title: "Your safety,\nredefined.",
      subtitle:
      "HerSafe is your quiet companion — always ready, never intrusive. Built for women who deserve to feel safe everywhere.",
      bgGradient: [Color(0xFFFFE4EE), Color(0xFFFFF0F8)],
      accentColor: Color(0xFFE8587A),
      blobColor: Color(0xFFFFB3CA),
      tag: "Welcome",
    ),
    OnboardingData(
      emoji: "📍",
      title: "Share your\nlocation, live.",
      subtitle:
      "Let your trusted circle track you in real time. One tap and your loved ones always know you're okay.",
      bgGradient: [Color(0xFFE8F4FF), Color(0xFFF5FAFF)],
      accentColor: Color(0xFF5AADEE),
      blobColor: Color(0xFFB3DEFF),
      tag: "Live Safety",
    ),
    OnboardingData(
      emoji: "🆘",
      title: "SOS in a\nsingle touch.",
      subtitle:
      "Shake, press, or automate — your emergency alert reaches the right people at the right time, instantly.",
      bgGradient: [Color(0xFFFFEEEE), Color(0xFFFFF5F5)],
      accentColor: Color(0xFFFF6B6B),
      blobColor: Color(0xFFFFB3B3),
      tag: "Emergency",
    ),
    OnboardingData(
      emoji: "🌙",
      title: "Track your\ncycle with care.",
      subtitle:
      "Log your period, symptoms and moods. HerSafe gives you insights that feel personal, not clinical.",
      bgGradient: [Color(0xFFF5F0FF), Color(0xFFFAF7FF)],
      accentColor: Color(0xFFB07FE8),
      blobColor: Color(0xFFD4B8FF),
      tag: "Wellness",
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage < slides.length - 1) {
      _textController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _textController.forward();
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => const HomePage(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Slide PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _textController.reset();
              _textController.forward();
            },
            itemCount: slides.length,
            itemBuilder: (_, index) => _buildSlide(slides[index]),
          ),

          // Bottom UI overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),

          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 22,
            child: _currentPage < slides.length - 1
                ? GestureDetector(
              onTap: _finishOnboarding,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Skip",
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8C5A6A),
                  ),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(OnboardingData data) {
    return AnimatedBuilder(
      animation: _illustrationController,
      builder: (_, __) {
        final t = _illustrationController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data.bgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Background blobs
              Positioned(
                top: -60,
                right: -40,
                child: _blob(220, data.blobColor.withOpacity(0.45), 80),
              ),
              Positioned(
                top: 100 + t * 10,
                left: -60,
                child: _blob(180, data.blobColor.withOpacity(0.28), 70),
              ),
              Positioned(
                bottom: 180 - t * 6,
                right: -30,
                child: _blob(160, data.accentColor.withOpacity(0.1), 60),
              ),

              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),

                      // Emoji illustration with float
                      Transform.translate(
                        offset: Offset(0, t * -8),
                        child: Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: data.accentColor.withOpacity(0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(data.emoji,
                                  style: const TextStyle(fontSize: 72)),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Tag pill
                      FadeTransition(
                        opacity: _textController,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: data.accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data.tag.toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: data.accentColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Title
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _textController,
                          curve: Curves.easeOut,
                        )),
                        child: FadeTransition(
                          opacity: _textController,
                          child: Text(
                            data.title,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 38,
                              color: const Color(0xFF3D1A26),
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _textController,
                          curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _textController,
                            curve: const Interval(0.2, 1.0),
                          ),
                          child: Text(
                            data.subtitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: const Color(0xFF8C5A6A),
                              height: 1.65,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob(double size, Color color, double blur) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBottomBar() {
    final data = slides[_currentPage];
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.bgGradient[1].withOpacity(0),
            data.bgGradient[1],
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dot indicators
          Row(
            children: List.generate(
              slides.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: _currentPage == i ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? data.accentColor
                      : data.accentColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // Next / Get Started button
          GestureDetector(
            onTap: _goNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(
                horizontal: _currentPage == slides.length - 1 ? 28 : 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: data.accentColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: data.accentColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == slides.length - 1
                        ? "Get Started"
                        : "Next",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> bgGradient;
  final Color accentColor;
  final Color blobColor;
  final String tag;

  const OnboardingData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgGradient,
    required this.accentColor,
    required this.blobColor,
    required this.tag,
  });
}