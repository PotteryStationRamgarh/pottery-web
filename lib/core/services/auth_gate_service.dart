import 'package:flutter/material.dart';

import '../../app/routes.dart';

class PendingAuthNavigation {
  final String routeName;
  final Object? arguments;

  const PendingAuthNavigation({required this.routeName, this.arguments});
}

class AuthGateService {
  AuthGateService._();

  static PendingAuthNavigation? _pendingNavigation;

  static void requireLogin(
    BuildContext context, {
    required String routeName,
    Object? arguments,
  }) {
    _pendingNavigation = PendingAuthNavigation(
      routeName: routeName,
      arguments: arguments,
    );
    Navigator.pushNamed(context, Routes.signin);
  }

  static PendingAuthNavigation? consumePendingNavigation() {
    final pending = _pendingNavigation;
    _pendingNavigation = null;
    return pending;
  }

  static PendingAuthNavigation? peekPendingNavigation() {
    return _pendingNavigation;
  }
}
