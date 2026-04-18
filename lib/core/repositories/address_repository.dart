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
          .collection('users')
          .doc(userId)
          .collection('addresses')
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
      if (address.userId.isEmpty) return;

      final colRef = _db
          .collection('users')
          .doc(address.userId)
          .collection('addresses');

      final docRef = address.id.isEmpty ? colRef.doc() : colRef.doc(address.id);

      if (address.isDefault) {
        final batch = _db.batch();
        final snap = await colRef.get();

        for (final doc in snap.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }

        batch.set(docRef, address.toMap(), SetOptions(merge: true));
        await batch.commit();
      } else {
        await docRef.set(address.toMap(), SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('AddressRepository.saveAddress error: $e');
      rethrow;
    }
  }

  static Future<void> deleteAddress(String userId, String addressId) async {
    try {
      if (userId.isEmpty || addressId.isEmpty) return;
      await _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      debugPrint('AddressRepository.deleteAddress error: $e');
      rethrow;
    }
  }

  static Future<void> setDefault(String userId, String addressId) async {
    try {
      if (userId.isEmpty || addressId.isEmpty) return;

      final colRef = _db
          .collection('users')
          .doc(userId)
          .collection('addresses');
      final batch = _db.batch();

      final snap = await colRef.get();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

  batch.update(colRef.doc(addressId), {'isDefault': true});
      await batch.commit();
    } catch (e) {
      debugPrint('AddressRepository.setDefault error: $e');
      rethrow;
    }
  }

  static Future<void> updateAddress(
    String userId,
    String addressId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (userId.isEmpty || addressId.isEmpty) return;

      final docRef = _db
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId);

      final isDefault = data['isDefault'] == true;

      if (isDefault) {
        final colRef = _db
            .collection('users')
            .doc(userId)
            .collection('addresses');
        final batch = _db.batch();
        final snap = await colRef.get();

        for (final doc in snap.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }

        batch.update(docRef, data);
        await batch.commit();
      } else {
        await docRef.update(data);
      }
    } catch (e) {
      debugPrint('AddressRepository.updateAddress error: $e');
      rethrow;
    }
  }
}
