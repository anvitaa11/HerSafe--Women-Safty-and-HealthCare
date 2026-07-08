
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';


class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser?.uid ?? '';

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'name': name, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }
}

// ─────────────────────────────────────────────
// TRUSTED CONTACTS SERVICE
// ─────────────────────────────────────────────
class TrustedContactsService {
  final _db = FirebaseFirestore.instance;
  final _auth = AuthService();

  CollectionReference get _contactsRef =>
      _db.collection('users').doc(_auth.uid).collection('trusted_contacts');

  Future<void> addContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    await _contactsRef.add({
      'name': name,
      'phone': phone,
      'relationship': relationship ?? 'Friend',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteContact(String id) => _contactsRef.doc(id).delete();

  Stream<List<TrustedContact>> getContacts() {
    return _contactsRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => TrustedContact.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<List<TrustedContact>> getContactsOnce() async {
    final snap = await _contactsRef.get();
    return snap.docs
        .map((d) => TrustedContact.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }
}

class TrustedContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;

  TrustedContact(
      {required this.id,
        required this.name,
        required this.phone,
        required this.relationship});

  factory TrustedContact.fromMap(String id, Map<String, dynamic> m) =>
      TrustedContact(
        id: id,
        name: m['name'] ?? '',
        phone: m['phone'] ?? '',
        relationship: m['relationship'] ?? 'Friend',
      );
}

// ─────────────────────────────────────────────
// LOCATION SERVICE
// ─────────────────────────────────────────────
class LocationService {
  static StreamSubscription<Position>? _positionSub;
  static final _db = FirebaseFirestore.instance;
  static final _auth = AuthService();

  static Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  static Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Start streaming live location to Firestore
  static Future<void> startLiveSharing() async {
    final granted = await requestPermission();
    if (!granted) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      await _db
          .collection('users')
          .doc(_auth.uid)
          .collection('live_location')
          .doc('current')
          .set({
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
        'active': true,
      });
    });
  }

  static Future<void> stopLiveSharing() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _db
        .collection('users')
        .doc(_auth.uid)
        .collection('live_location')
        .doc('current')
        .update({'active': false});
  }

  static Stream<Map<String, dynamic>?> watchLocation(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('live_location')
        .doc('current')
        .snapshots()
        .map((snap) => snap.data());
  }
}

class SOSService {
  static final _telephony = Telephony.instance;
  static final _contactsService = TrustedContactsService();
  static final _db = FirebaseFirestore.instance;
  static final _auth = AuthService();

  static StreamSubscription<AccelerometerEvent>? _shakeSub;
  static DateTime? _lastShakeTime;
  static int _shakeCount = 0;

  static Future<SOSResult> triggerSOS({String? customMessage}) async {
    try {
      final position = await LocationService.getCurrentPosition();
      final contacts = await _contactsService.getContactsOnce();

      if (contacts.isEmpty) {
        return SOSResult.failure("No trusted contacts found.");
      }

      final locationText = position != null
          ? "📍 My location: https://maps.google.com/?q=${position.latitude},${position.longitude}"
          : "⚠️ Could not get location.";

      final message = customMessage != null
          ? "$customMessage\n$locationText"
          : "🆘 EMERGENCY ALERT from HerSafe!\nI may be in danger. Please help me.\n$locationText";

      bool smsGranted = await _telephony.requestSmsPermissions ?? false;
      int sent = 0;

      if (smsGranted) {
        for (final contact in contacts) {
          try {
            await _telephony.sendSms(
              to: contact.phone,
              message: message,
              statusListener: (status) {
                debugPrint("SMS to ${contact.name}: $status");
              },
            );
            sent++;
          } catch (e) {
            debugPrint("SMS error to ${contact.phone}: $e");
          }
        }
      }

      // Log SOS event
      await _db
          .collection('users')
          .doc(_auth.uid)
          .collection('sos_logs')
          .add({
        'triggeredAt': FieldValue.serverTimestamp(),
        'lat': position?.latitude,
        'lng': position?.longitude,
        'messagesSent': sent,
        'totalContacts': contacts.length,
      });

      return SOSResult.success("SOS sent to $sent/${contacts.length} contacts.");
    } catch (e) {
      return SOSResult.failure("SOS failed: $e");
    }
  }

  /// Start shake-to-SOS detection
  static void startShakeDetection() {
    _shakeSub = accelerometerEventStream().listen((event) {
      final magnitude = (event.x * event.x +
          event.y * event.y +
          event.z * event.z)
          .abs();

      if (magnitude > 200) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inSeconds > 1) {
          _shakeCount++;
          _lastShakeTime = now;

          if (_shakeCount >= 3) {
            _shakeCount = 0;
            triggerSOS(customMessage: "🆘 Auto SOS triggered by shake gesture.");
          }
        }
      }
    });
  }

  static void stopShakeDetection() {
    _shakeSub?.cancel();
    _shakeSub = null;
    _shakeCount = 0;
  }
}

class SOSResult {
  final bool success;
  final String message;

  SOSResult._({required this.success, required this.message});

  factory SOSResult.success(String message) =>
      SOSResult._(success: true, message: message);

  factory SOSResult.failure(String message) =>
      SOSResult._(success: false, message: message);
}


class AutoMessageService {
  static final _telephony = Telephony.instance;
  static final _prefs = SharedPreferences.getInstance();

  static Future<void> saveTemplate(String message) async {
    final p = await _prefs;
    await p.setString('auto_message_template', message);
  }

  static Future<String> getTemplate() async {
    final p = await _prefs;
    return p.getString('auto_message_template') ??
        "I'm on my way. Tracking me via HerSafe.";
  }

  static Future<bool> sendToContacts({
    required List<TrustedContact> contacts,
    String? customMsg,
  }) async {
    final template = customMsg ?? await getTemplate();
    final pos = await LocationService.getCurrentPosition();
    final locationText = pos != null
        ? "\n📍 Location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}"
        : "";
    final finalMsg = "$template$locationText";

    bool granted = await _telephony.requestSmsPermissions ?? false;
    if (!granted) return false;

    for (final c in contacts) {
      await _telephony.sendSms(to: c.phone, message: finalMsg);
    }
    return true;
  }
}

class EmergencyRecordingService {
  static final _recorder = AudioRecorder();
  static final _storage = FirebaseStorage.instance;
  static final _db = FirebaseFirestore.instance;
  static final _auth = AuthService();

  static bool _isRecording = false;
  static String? _currentPath;

  static bool get isRecording => _isRecording;

  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<void> startRecording() async {
    final granted = await requestPermission();
    if (!granted || _isRecording) return;

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/emergency_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _currentPath!,
    );

    _isRecording = true;
    debugPrint("Recording started: $_currentPath");
  }

  static Future<String?> stopAndUpload() async {
    if (!_isRecording) return null;

    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null) return null;

    final file = File(path);
    final fileName = path.split('/').last;

    try {
      final ref = _storage
          .ref()
          .child('recordings')
          .child(_auth.uid)
          .child(fileName);

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _db
          .collection('users')
          .doc(_auth.uid)
          .collection('recordings')
          .add({
        'url': url,
        'fileName': fileName,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      return url;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> getRecordings() {
    return _db
        .collection('users')
        .doc(_auth.uid)
        .collection('recordings')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}

// ─────────────────────────────────────────────
// PERIOD TRACKER SERVICE
// ─────────────────────────────────────────────
class PeriodTrackerService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = AuthService();

  CollectionReference get _cyclesRef =>
      _db.collection('users').doc(_auth.uid).collection('period_cycles');

  Future<void> logPeriodStart(DateTime date, {String? notes}) async {
    await _cyclesRef.add({
      'startDate': Timestamp.fromDate(date),
      'endDate': null,
      'notes': notes ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logPeriodEnd(String cycleId, DateTime date) async {
    await _cyclesRef.doc(cycleId).update({
      'endDate': Timestamp.fromDate(date),
    });
  }

  Future<void> logSymptoms(String cycleId, List<String> symptoms) async {
    await _cyclesRef.doc(cycleId).update({'symptoms': symptoms});
  }

  Stream<List<PeriodCycle>> getCycles() {
    return _cyclesRef
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => PeriodCycle.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  /// Predict next period based on average cycle length
  Future<DateTime?> predictNextPeriod() async {
    final snap = await _cyclesRef
        .orderBy('startDate', descending: true)
        .limit(6)
        .get();

    if (snap.docs.length < 2) return null;

    final dates = snap.docs
        .map((d) => (d['startDate'] as Timestamp).toDate())
        .toList();

    int totalDays = 0;
    for (int i = 0; i < dates.length - 1; i++) {
      totalDays += dates[i].difference(dates[i + 1]).inDays;
    }

    final avgCycle = totalDays ~/ (dates.length - 1);
    return dates.first.add(Duration(days: avgCycle));
  }
}

class PeriodCycle {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;
  final List<String> symptoms;

  PeriodCycle({
    required this.id,
    required this.startDate,
    this.endDate,
    this.notes = '',
    this.symptoms = const [],
  });

  int? get durationDays => endDate?.difference(startDate).inDays;

  factory PeriodCycle.fromMap(String id, Map<String, dynamic> m) =>
      PeriodCycle(
        id: id,
        startDate: (m['startDate'] as Timestamp).toDate(),
        endDate: m['endDate'] != null
            ? (m['endDate'] as Timestamp).toDate()
            : null,
        notes: m['notes'] ?? '',
        symptoms: List<String>.from(m['symptoms'] ?? []),
      );
}