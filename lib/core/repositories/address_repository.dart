import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/address_model.dart';

class AddressRepository {
  AddressRepository._();

  static final _db = FirebaseFirestore.instance;

  static Future<List<AddressModel>> getAddressesByUser(String userId) async {
    try {
      if (userId.isEmpty) return [];

      final snap = await _db
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(AddressModel.fromDoc).toList();
    } catch (e) {
      debugPrint('AddressRepository.getAddressesByUser error: $e');
      return [];
    }
  }

  static Future<void> saveAddress(AddressModel address) async {
    try {
      final docRef = address.id.isEmpty
          ? _db.collection('addresses').doc()
          : _db.collection('addresses').doc(address.id);

      await docRef.set(address.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('AddressRepository.saveAddress error: $e');
      rethrow;
    }
  }

  static Future<void> deleteAddress(String addressId) async {
    try {
      if (addressId.isEmpty) return;
      await _db.collection('addresses').doc(addressId).delete();
    } catch (e) {
      debugPrint('AddressRepository.deleteAddress error: $e');
      rethrow;
    }
  }

  static Future<void> setDefault(String userId, String addressId) async {
    try {
      if (userId.isEmpty || addressId.isEmpty) return;

      final batch = _db.batch();

      // Set all addresses for this user to isDefault: false
      final snap = await _db
          .collection('addresses')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Set current address to isDefault: true
      batch.update(_db.collection('addresses').doc(addressId), {'isDefault': true});

      await batch.commit();
    } catch (e) {
      debugPrint('AddressRepository.setDefault error: $e');
      rethrow;
    }
  }
}
