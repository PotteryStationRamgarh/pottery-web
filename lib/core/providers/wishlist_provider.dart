import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class WishlistProvider with ChangeNotifier {
  WishlistProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _items.clear();
        notifyListeners();
      } else {
        _load(user.uid);
      }
    });
  }

  final Set<String> _items = <String>{};
  late final StreamSubscription<User?> _authSubscription;

  Set<String> get items => Set.unmodifiable(_items);

  String _key(String id, bool isExclusive) =>
      '${isExclusive ? 'exclusive' : 'product'}:$id';

  bool isWishlisted(String id, {bool isExclusive = false}) {
    return _items.contains(_key(id, isExclusive));
  }

  void toggle(String id, {bool isExclusive = false}) {
    final key = _key(id, isExclusive);
    if (_items.contains(key)) {
      _items.remove(key);
    } else {
      _items.add(key);
    }
    notifyListeners();
    _persist();
  }

  Future<void> _load(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_wishlists')
          .doc(uid)
          .get();
      final values =
          (doc.data()?['items'] as List?)
              ?.map((item) => item.toString())
              .toSet() ??
          <String>{};
      _items
        ..clear()
        ..addAll(values);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('user_wishlists')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'items': _items.toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
