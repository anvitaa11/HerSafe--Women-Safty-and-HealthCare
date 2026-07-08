import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:women_safety_health_app/app_theme.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});
  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _pressController;

  bool _triggered = false;
  String _statusMsg = '';
  String _emergencyContact = '';
  final TextEditingController _contactCtrl = TextEditingController();

  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _loadContact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContact = prefs.getString('emergency_contact') ?? '';
      _contactCtrl.text = _emergencyContact;
    });
  }

  Future<void> _saveContact(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact', number);
    setState(() => _emergencyContact = number);
  }

  Future<void> _triggerSOS() async {
    setState(() { _triggered = true; _statusMsg = 'Getting your location...'; });
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 6));
        setState(() => _statusMsg = 'Location found. Alerting contacts...');
      } catch (_) {
        setState(() => _statusMsg = 'Could not get location. Calling anyway...');
      }

      await _db.collection('users').doc(_uid).collection('sos_logs').add({
        'triggeredAt': FieldValue.serverTimestamp(),
        'lat': position?.latitude,
        'lng': position?.longitude,
        'contactCalled': _emergencyContact.isNotEmpty ? _emergencyContact : '112',
      });

      final callNumber =
      _emergencyContact.isNotEmpty ? _emergencyContact : '112';
      setState(() => _statusMsg = 'Calling $callNumber...');
      await Future.delayed(const Duration(milliseconds: 500));

      final uri = Uri.parse('tel:$callNumber');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      setState(() => _statusMsg = '✓ Emergency call initiated');
    } catch (e) {
      setState(() => _statusMsg = 'Error: $e');
    }
  }

  void _reset() => setState(() { _triggered = false; _statusMsg = ''; });

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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildSOSButton(),
                        const SizedBox(height: 30),
                        if (_triggered) _buildStatusCard(),
                        if (!_triggered) ...[
                          _buildContactCard(),
                          const SizedBox(height: 16),
                          _buildInstructionsCard(),
                          const SizedBox(height: 16),
                          _buildQuickCallsCard(),
                        ],
                      ],
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: AppTheme.cardDecoration(radius: 12),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'SOS Emergency',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSButton() {
    return Column(
      children: [
        Text(
          _triggered ? 'SOS Active' : 'Hold to Send SOS',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _triggered ? const Color(0xFFFF4444) : AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _triggered ? 'Help is on the way 🙏' : 'Tap the button in an emergency',
          style: AppTheme.body(14),
        ),
        const SizedBox(height: 36),
        AnimatedBuilder(
          animation: _triggered ? _pulseAnim : _pressController,
          builder: (_, __) {
            final scale = _triggered
                ? _pulseAnim.value
                : 1.0 - _pressController.value * 0.05;
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTapDown: (_) { if (!_triggered) _pressController.forward(); },
                onTapUp: (_) { _pressController.reverse(); if (!_triggered) _triggerSOS(); },
                onTapCancel: () => _pressController.reverse(),
                onLongPress: () { if (!_triggered) _triggerSOS(); },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_triggered
                            ? const Color(0xFFFF4444)
                            : AppTheme.rose).withOpacity(0.08),
                      ),
                    ),
                    Container(
                      width: 170, height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (_triggered
                            ? const Color(0xFFFF4444)
                            : AppTheme.rose).withOpacity(0.12),
                      ),
                    ),
                    Container(
                      width: 140, height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _triggered
                              ? [const Color(0xFFFF4444), const Color(0xFFCC0000)]
                              : [const Color(0xFFFF6B6B), const Color(0xFFE8587A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_triggered
                                ? const Color(0xFFFF4444)
                                : AppTheme.rose).withOpacity(0.45),
                            blurRadius: 30, spreadRadius: 4,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _triggered ? Icons.warning_rounded : Icons.sos_rounded,
                            color: Colors.white, size: 48,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _triggered ? 'ACTIVE' : 'SOS',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_triggered) ...[
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.rosePale),
                boxShadow: AppTheme.softShadow,
              ),
              child: Text('Cancel SOS',
                  style: AppTheme.label(14, color: AppTheme.textMid)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3), width: 1.5),
        boxShadow: AppTheme.cardShadow(const Color(0xFFFF4444)),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Color(0xFFFF4444), strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(_statusMsg,
                  style: AppTheme.body(14, color: AppTheme.textDark))),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📞', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Emergency Contact',
                style: AppTheme.label(14, color: AppTheme.textDark)),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _contactCtrl,
                  keyboardType: TextInputType.phone,
                  style: AppTheme.body(15, color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: 'e.g. +91 9876543210',
                    hintStyle: AppTheme.body(14),
                    filled: true, fillColor: AppTheme.blush,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.phone_rounded,
                        color: AppTheme.rose, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _saveContact(_contactCtrl.text.trim()),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.roseGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.save_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_emergencyContact.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF3CC98A), size: 16),
                const SizedBox(width: 6),
                Text('Saved: $_emergencyContact',
                    style: AppTheme.body(12,
                        color: const Color(0xFF3CC98A))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final steps = [
      ('1', 'Tap or hold the red SOS button', '👆'),
      ('2', 'Your GPS location is captured automatically', '📍'),
      ('3', 'Emergency call is placed to your contact', '📞'),
      ('4', 'Event is logged securely in the cloud', '☁️'),
    ];
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How SOS works',
              style: AppTheme.label(14, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    gradient: AppTheme.roseGradient,
                    shape: BoxShape.circle),
                child: Center(
                    child: Text(s.$1,
                        style: AppTheme.label(11,
                            color: Colors.white))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(s.$2, style: AppTheme.body(13))),
              Text(s.$3, style: const TextStyle(fontSize: 16)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildQuickCallsCard() {
    final numbers = [
      ('Police', '100', '🚔', AppTheme.lavender),
      ('Ambulance', '108', '🚑', const Color(0xFF3CC98A)),
      ('Women Helpline', '1091', '👩', AppTheme.rose),
      ('Emergency', '112', '🆘', const Color(0xFFFF6B6B)),
    ];
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Emergency Calls',
              style: AppTheme.label(14, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: numbers.map((n) {
              return GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:${n.$2}')),
                child: Container(
                  decoration: BoxDecoration(
                    color: n.$4.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: n.$4.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(children: [
                    Text(n.$3, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.$1, style: AppTheme.label(10, color: AppTheme.textDark)),
                          Text(n.$2, style: AppTheme.label(12, color: n.$4)),
                        ],
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}