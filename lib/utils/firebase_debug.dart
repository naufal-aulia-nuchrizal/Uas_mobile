import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseDebugUtil {
  static Future<void> debugFirebaseConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('=== FIREBASE DEBUG INFO ===');
      debugPrint('Current User UID: ${user?.uid ?? "NOT LOGGED IN"}');
      debugPrint('Current User Email: ${user?.email ?? "NO EMAIL"}');

      if (user != null) {
        // Check if user document exists
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        debugPrint('User Document Exists: ${userDoc.exists}');
        if (userDoc.exists) {
          debugPrint('User Document Data: ${userDoc.data()}');
        } else {
          debugPrint('⚠️ User document NOT found in Firestore!');
          debugPrint('Creating user document now...');

          // Create user document if missing
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid, // Add uid field
                'email': user.email,
                'name': 'New User',
                'nim': '',
                'phone': '',
                'photo': 'user.png',
                'createdAt': FieldValue.serverTimestamp(),
              });

          debugPrint('✓ User document created!');
        }

        // List all items
        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('items')
            .limit(5)
            .get();

        debugPrint('Total items in collection: ${itemsSnapshot.docs.length}');
        for (var doc in itemsSnapshot.docs) {
          debugPrint('Item: ${doc.id} - ${doc.data()}');
        }
      }

      debugPrint('=== END DEBUG INFO ===');
    } catch (e) {
      debugPrint('Debug Error: $e');
    }
  }
}
