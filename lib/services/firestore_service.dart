import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  final CollectionReference itemsCollection = FirebaseFirestore.instance
      .collection('items');
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Items Stream
  Stream<List<ItemModel>> getItems() {
    return itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Get single item
  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final doc = await itemsCollection.doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Error getting item: $e');
    }
  }

  // Add item
  Future<String> addItem(Map<String, dynamic> data) async {
    try {
      final docRef = await itemsCollection.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding item: $e');
    }
  }

  // Update item
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      await itemsCollection.doc(itemId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await itemsCollection.doc(itemId).delete();
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }

  // Search items by type
  Future<List<ItemModel>> searchItemsByType(String type) async {
    try {
      final snapshot = await itemsCollection
          .where('type', isEqualTo: type)
          .get();
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error searching items: $e');
    }
  }

  // Search items by status
  Future<List<ItemModel>> searchItemsByStatus(String status) async {
    try {
      final snapshot = await itemsCollection
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs.map((doc) {
        return ItemModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error searching items: $e');
    }
  }
}
