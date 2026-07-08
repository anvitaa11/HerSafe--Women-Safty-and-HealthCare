// lib/services/firebase_service.dart
/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  static Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> storePeriodData(String userId, DateTime lastPeriod, DateTime? nextPeriod) async {
    await _firestore.collection('users').doc(userId).collection('periods').add({
      'lastPeriod': lastPeriod,
      'nextPeriod': nextPeriod,
      'trackedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> storeSOS(String userId, double lat, double lng, List<String> contacts) async {
    await _firestore.collection('sos_events').add({
      'userId': userId,
      'location': GeoPoint(lat, lng),
      'contacts': contacts,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> storeContact(String userId, String name, String phone) async {
    await _firestore.collection('users').doc(userId).collection('contacts').add({
      'name': name,
      'phone': phone,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getContacts(String userId) {
    return _firestore.collection('users').doc(userId).collection('contacts').snapshots();
  }

  static Future<String> uploadRecording(String userId, File file) async {
    Reference ref = _storage.ref().child('recordings/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4');
    UploadTask task = ref.putFile(file);
    TaskSnapshot snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  static Future<void> initMessaging() async {
    NotificationSettings settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      // Store token in Firestore if needed
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle foreground messages
    });
  }
}

 */