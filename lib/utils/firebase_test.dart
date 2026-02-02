import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Connection Test Utility
class FirebaseTestUtil {
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    final result = <String, dynamic>{};

    // Test 1: Check Firebase Core
    try {
      final firebaseApp = Firebase.app();
      result['firebase_core'] = {
        'status': 'connected',
        'app_name': firebaseApp.name,
        'message': 'Firebase Core initialized successfully',
      };
    } catch (e) {
      result['firebase_core'] = {'status': 'error', 'message': e.toString()};
    }

    // Test 2: Check Firestore Connection
    try {
      final firestore = FirebaseFirestore.instance;
      final testCollection = await firestore.collection('users').limit(1).get();
      result['firestore'] = {
        'status': 'connected',
        'documents_count': testCollection.size,
        'message': 'Firestore connection successful',
      };
    } catch (e) {
      result['firestore'] = {'status': 'error', 'message': e.toString()};
    }

    // Test 3: Check Firebase Auth
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      result['firebase_auth'] = {
        'status': 'connected',
        'user_logged_in': currentUser != null,
        'user_email': currentUser?.email,
        'message': 'Firebase Auth connected',
      };
    } catch (e) {
      result['firebase_auth'] = {'status': 'error', 'message': e.toString()};
    }

    return result;
  }

  /// Print connection status in a readable format
  static Future<void> printConnectionStatus() async {
    debugPrint('\n========== FIREBASE CONNECTION TEST ==========');
    final result = await testFirebaseConnection();

    result.forEach((key, value) {
      debugPrint('\n$key:');
      debugPrint('  Status: ${value['status']}');
      value.forEach((k, v) {
        if (k != 'status') {
          debugPrint('  $k: $v');
        }
      });
    });
    debugPrint('\n==============================================\n');
  }
}
