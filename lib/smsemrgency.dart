import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:women_safety_health_app/app_theme.dart';

class SMSEmergencyPage extends StatefulWidget {
  const SMSEmergencyPage({super.key});

  @override
  State<SMSEmergencyPage> createState() => _SMSEmergencyPageState();
}

class _SMSEmergencyPageState extends State<SMSEmergencyPage>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  late AnimationController _sentAnim;

  final List<_Contact> _contacts = [];
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _msgCtrl = TextEditingController(
      text: '🆘 EMERGENCY! I may be in danger. Please help me immediately.');

  bool _sending = false;
  bool _sent = false;
  String _statusMsg = '';

  @override
  void initState() {
    super.initState();
    _sentAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _loadContacts();
  }

  @override
  void dispose() {
    _sentAnim.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final snap = await _db
          .collection('users')
          .doc(_uid)
          .collection('sms_contacts')
          .get();
      setState(() {
        _contacts.clear();
        for (final d in snap.docs) {
          _contacts.add(_Contact(
            id: d.id,
            name: d['name'] ?? '',
            phone: d['phone'] ?? '',
          ));
        }
      });
    } catch (_) {}
  }

  Future<void> _addContact() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _showSnack('Please enter name and phone number');
      return;
    }
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('sms_contacts')
          .add({
        'name': name,
        'phone': phone,
        'addedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _contacts.add(_Contact(id: doc.id, name: name, phone: phone));
        _nameCtrl.clear();
        _phoneCtrl.clear();
      });
      _showSnack('$name added ✓');
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _deleteContact(String id, int index) async {
    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('sms_contacts')
          .doc(id)
          .delete();
      setState(() => _contacts.removeAt(index));
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  /// Send SMS using Android sms: URI — works WITHOUT internet.
  /// Opens the default SMS app pre-filled with number + message.
  /// For background (no UI) SMS on Android, use android_intent_plus package.
  Future<void> _sendSMS() async {
    if (_contacts.isEmpty) {
      _showSnack('Add at least one trusted contact first');
      return;
    }

    setState(() { _sending = true; _statusMsg = 'Getting location...'; });

    // Get GPS location
    String locationText = '';
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),
        );
        locationText =
        '\n📍 Location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      }
    } catch (_) {}

    final fullMessage = '${_msgCtrl.text.trim()}$locationText';

    // Log to Firestore
    try {
      await _db.collection('users').doc(_uid).collection('sms_logs').add({
        'sentAt': FieldValue.serverTimestamp(),
        'recipients': _contacts.map((c) => c.phone).toList(),
        'message': fullMessage,
      });
    } catch (_) {}

    setState(() { _sending = false; });

    // Open SMS app for each contact
    // (Android allows multi-recipient via comma-separated numbers)
    final numbers = _contacts.map((c) => c.phone).join(',');
    final encoded = Uri.encodeComponent(fullMessage);
    final smsUri = Uri.parse('sms:$numbers?body=$encoded');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      setState(() { _sent = true; _statusMsg = 'SMS app opened for ${_contacts.length} contact(s) ✓'; });
      _sentAnim.forward();
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) { setState(() => _sent = false); _sentAnim.reverse(); }
    } else {
      _showSnack('Could not open SMS app. Check permissions.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTheme.body(14, color: Colors.white)),
      backgroundColor: AppTheme.rose,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSendCard(),
                      const SizedBox(height: 16),
                      _buildAddContactCard(),
                      const SizedBox(height: 16),
                      _buildContactList(),
                      const SizedBox(height: 16),
                      _buildMessageCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_sent)
            Positioned.fill(
              child: FadeTransition(
                opacity: _sentAnim,
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.cardShadow(AppTheme.rose),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text('SMS Ready!',
                              style: TextStyle(fontFamily: 'serif', fontSize: 26, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                          const SizedBox(height: 6),
                          Text(_statusMsg,
                              style: AppTheme.body(14),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
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
          Text('SMS Emergency',
              style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const Spacer(),
          const Text('💬', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  Widget _buildSendCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.purpleGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow(AppTheme.lavender),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const Text('💬', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('Send Emergency SMS',
              style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Opens your SMS app pre-filled with\nyour message + GPS location.',
            style: AppTheme.body(13, color: Colors.white.withOpacity(0.85)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _sending ? null : _sendSMS,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: _sending
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: AppTheme.lavender, strokeWidth: 2)),
                const SizedBox(width: 10),
                Text(_statusMsg,
                    style: AppTheme.label(14, color: AppTheme.lavender)),
              ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.send_rounded,
                    color: AppTheme.lavender, size: 20),
                const SizedBox(width: 8),
                Text('Send SOS SMS Now',
                    style: AppTheme.label(15, color: AppTheme.lavender)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddContactCard() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Trusted Contact',
              style: AppTheme.label(14, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            style: AppTheme.body(14, color: AppTheme.textDark),
            decoration: _inputDeco('Full name', Icons.person_rounded),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: AppTheme.body(14, color: AppTheme.textDark),
                  decoration: _inputDeco('Phone number', Icons.phone_rounded),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addContact,
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: AppTheme.roseGradient,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: AppTheme.cardShadow(AppTheme.rose),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTheme.body(14),
      filled: true,
      fillColor: AppTheme.blush,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      prefixIcon: Icon(icon, color: AppTheme.rose, size: 18),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  Widget _buildContactList() {
    if (_contacts.isEmpty) {
      return Container(
        decoration: AppTheme.cardDecoration(),
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          const Text('👥', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text('No trusted contacts yet',
              style: AppTheme.label(14, color: AppTheme.textMid)),
          const SizedBox(height: 4),
          Text('Add contacts above to send emergency SMS',
              style: AppTheme.body(12), textAlign: TextAlign.center),
        ]),
      );
    }

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Trusted Contacts',
                style: AppTheme.label(14, color: AppTheme.textDark)),
            const Spacer(),
            HerChip(label: '${_contacts.length} saved', color: AppTheme.rose),
          ]),
          const SizedBox(height: 12),
          ..._contacts.asMap().entries.map((e) {
            final c = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppTheme.blush,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      gradient: AppTheme.roseGradient,
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: AppTheme.label(16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: AppTheme.label(13, color: AppTheme.textDark)),
                    Text(c.phone, style: AppTheme.body(12)),
                  ],
                )),
                GestureDetector(
                  onTap: () => _deleteContact(c.id, e.key),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF6B6B), size: 18),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMessageCard() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alert Message',
              style: AppTheme.label(14, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          Text('GPS coordinates will be appended automatically',
              style: AppTheme.body(11)),
          const SizedBox(height: 12),
          TextField(
            controller: _msgCtrl,
            maxLines: 4,
            style: AppTheme.body(13, color: AppTheme.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.blush,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contact {
  final String id;
  final String name;
  final String phone;
  const _Contact({required this.id, required this.name, required this.phone});
}