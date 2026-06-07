import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void navigateToLogin() {
  rootNavigatorKey.currentState?.pushNamedAndRemoveUntil('/signin', (_) => false);
}
